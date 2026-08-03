import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/document_model.dart';
import '../logic/document_provider.dart';
import '../logic/editor_provider.dart';
import '../logic/obsidian_launcher_service.dart';
import 'widgets/document_links_sheet.dart';
import 'widgets/markdown_toolbar.dart';

/// Markdown editor for a single [Document].
///
/// Autosave strategy:
///   1. 800 ms debounce while the user is typing.
///   2. Awaited save on the custom AppBar back button (guaranteed write).
///   3. Fire-and-forget save in [dispose] as a safety net for swipe-back
///      and Android system back (where a synchronous await is impossible).
///
/// Duplicate-write prevention lives in [DocumentEditorService.saveIfChanged],
/// not here — the screen simply calls save whenever it thinks something
/// might have changed.
class DocumentEditorScreen extends ConsumerStatefulWidget {
  const DocumentEditorScreen({super.key, required this.document});

  final Document document;

  @override
  ConsumerState<DocumentEditorScreen> createState() =>
      _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DocumentEditorService _service; // stored to avoid ref in dispose
  late Document _current;

  Timer? _debounce;
  bool _isDirty = false;

  static const _debounceDelay = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _current = widget.document;
    _service = ref.read(documentEditorServiceProvider);
    _titleController = TextEditingController(text: _current.title);
    _contentController = TextEditingController(text: _current.content);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Fire-and-forget safety-net save — controllers are still readable here.
    if (_isDirty) {
      _service.saveIfChanged(
        current: _current,
        title: _titleController.text,
        content: _contentController.text,
      );
    }
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── Autosave ──────────────────────────────────────────────────────

  void _scheduleAutosave() {
    if (!_isDirty) setState(() => _isDirty = true);
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, _save);
  }

  Future<void> _save() async {
    if (!_isDirty) return;
    _debounce?.cancel();
    try {
      final saved = await _service.saveIfChanged(
        current: _current,
        title: _titleController.text,
        content: _contentController.text,
      );
      _current = saved; // update for next equality check
      if (mounted) setState(() => _isDirty = false);
    } catch (_) {
      // Leave _isDirty = true so the next autosave retries.
    }
  }

  // ── Open in Obsidian (Sprint 20 Task 3) ─────────────────────────────

  void _openInObsidian() {
    final vault = ref.read(activeVaultProvider).valueOrNull;
    final result = ObsidianLauncherService.buildLaunchRequest(
      document: _current,
      vault: vault,
    );

    final message = switch (result.outcome) {
      ObsidianLaunchOutcome.noActiveVault => 'No vault configured yet.',
      ObsidianLaunchOutcome.notAnObsidianVault =>
        "This document isn't in an Obsidian vault.",
      ObsidianLaunchOutcome.launchUnavailable =>
        "Opening Obsidian directly isn't supported yet.",
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: result.uri == null
            ? null
            : SnackBarAction(
                label: 'Copy Link',
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: result.uri!)),
              ),
      ),
    );
  }

  // ── Links (Sprint 22 Task 5) ────────────────────────────────────────

  void _showLinksSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DocumentLinksSheet(documentPath: _current.path),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // Custom back button so we can await the final save before popping.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            _debounce?.cancel();
            await _save();
            if (mounted) context.pop();
          },
        ),
        // Editable title in the AppBar
        title: TextField(
          controller: _titleController,
          style: theme.textTheme.titleMedium,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Note title',
          ),
          onChanged: (_) => _scheduleAutosave(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in Obsidian',
            onPressed: _openInObsidian,
          ),
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Links',
            onPressed: _showLinksSheet,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Center(
              child: Text(
                _isDirty ? 'Saving…' : 'Saved',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _isDirty
                      ? theme.colorScheme.outline
                      : Colors.green.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
      // Markdown content — expands to fill available space above toolbar.
      body: TextField(
        controller: _contentController,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        onChanged: (_) => _scheduleAutosave(),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          height: 1.65,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          hintText: 'Start writing…',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
      // Toolbar sits above the soft keyboard (Scaffold resizes body,
      // bottom nav bar floats above the keyboard automatically).
      bottomNavigationBar: MarkdownToolbar(controller: _contentController),
    );
  }
}
