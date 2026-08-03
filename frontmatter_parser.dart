import 'package:yaml/yaml.dart';

/// Parses the leading YAML frontmatter block out of raw markdown text.
///
/// Frontmatter is the convention used by Obsidian, Jekyll, and most static
/// site generators: a block of YAML delimited by `---` lines at the very
/// start of the file, e.g.
///
/// ```
/// ---
/// title: My Note
/// tags: [daily, work]
/// ---
/// # Body starts here
/// ```
///
/// ## This is read-only, by design
///
/// LifeOS never regenerates a frontmatter block from a parsed map.
/// [Document.content] (see `document_model.dart`) always holds the
/// complete, original file text — frontmatter included, verbatim — and
/// that is exactly what gets written back to disk. Parsing here exists
/// purely to populate [Document.frontmatter] / [Document.tags] for the
/// app's own reads (tag filtering, future search). It has no bearing on
/// what a save writes, which is what actually guarantees frontmatter is
/// never reordered or reformatted and unknown fields are never dropped —
/// a parse-then-re-emit round trip could not offer that guarantee.
///
/// Pure Dart — no Flutter import. Lives in `core/utils/` rather than
/// `features/documents/logic/` because one of its consumers,
/// [ObsidianDocumentRepository] (see `obsidian_document_repository.dart`),
/// is in the Data layer, which must not depend on Logic (see
/// `ARCHITECTURE.md` §Layer Rules). Sprint 17 added a second consumer,
/// [DocumentMetadataService] (see `document_metadata_service.dart`, Logic
/// layer) — living in the layer-agnostic `core/` means both can depend on
/// this file without either layer depending on the other.
///
/// Returns an empty map if [content] has no frontmatter block, or if the
/// block isn't valid YAML — a malformed or non-standard block should
/// degrade gracefully, not crash a read.
Map<String, dynamic> parseFrontmatter(String content) {
  // Some Windows tools write a UTF-8 byte-order-mark at the start of a
  // saved file, which decodes to this exact character. Whether Dart's
  // default UTF-8 decoding (used by dart:io's File.readAsString, which
  // is how every document reaches this function) strips it isn't
  // certain enough to rely on either way — stripping it here defensively
  // costs nothing for the (overwhelmingly common) files that never have
  // one, and avoids a BOM-prefixed file's otherwise-well-formed
  // frontmatter silently going unrecognised. Found during the Sprint 19
  // vault-compatibility audit.
  final normalized =
      content.startsWith('\uFEFF') ? content.substring(1) : content;

  final lines = normalized.split('\n');
  if (lines.isEmpty || lines.first.trimRight() != '---') {
    return const {};
  }

  var closingIndex = -1;
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trimRight() == '---') {
      closingIndex = i;
      break;
    }
  }
  if (closingIndex == -1) return const {}; // no closing delimiter — not frontmatter

  final yamlBlock = lines.sublist(1, closingIndex).join('\n');
  if (yamlBlock.trim().isEmpty) return const {};

  try {
    final parsed = loadYaml(yamlBlock);
    if (parsed is YamlMap) {
      return parsed.map(
        (key, value) => MapEntry(key.toString(), _unwrap(value)),
      );
    }
    return const {};
  } catch (_) {
    // A hand-edited or plugin-authored block that isn't strictly valid
    // YAML shouldn't block reading the rest of the document.
    return const {};
  }
}

/// Recursively converts the `yaml` package's [YamlMap]/[YamlList] wrapper
/// types into plain [Map]/[List], so callers of [parseFrontmatter] never
/// need to import `package:yaml` themselves.
dynamic _unwrap(dynamic value) {
  if (value is YamlMap) {
    return value.map((k, v) => MapEntry(k.toString(), _unwrap(v)));
  }
  if (value is YamlList) {
    return value.map(_unwrap).toList();
  }
  return value;
}

/// Extracts a tag list from a parsed frontmatter map.
///
/// Handles the two shapes YAML allows: a real list (`tags: [a, b]` or
/// block-style), or a single bare scalar (`tags: work`). Anything else
/// (missing key, wrong type) yields an empty list rather than throwing —
/// tags are a convenience feature, not something a malformed file should
/// be able to break a document read over.
List<String> tagsFromFrontmatter(Map<String, dynamic> frontmatter) {
  final raw = frontmatter['tags'];
  if (raw is List) return raw.map((e) => e.toString()).toList(growable: false);
  if (raw is String && raw.trim().isNotEmpty) return [raw.trim()];
  return const [];
}
