import 'package:flutter/material.dart';

/// Horizontally scrollable markdown formatting toolbar.
///
/// All operations manipulate [controller]'s text and selection directly —
/// no business logic, no state, no Riverpod. Placed in the Scaffold's
/// [bottomNavigationBar] slot so it automatically rises above the soft
/// keyboard (Flutter's default Scaffold resize behaviour).
class MarkdownToolbar extends StatelessWidget {
  const MarkdownToolbar({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              _btn('H1', () => _linePrefix('# ')),
              _btn('H2', () => _linePrefix('## ')),
              _btn('H3', () => _linePrefix('### ')),
              _divider(),
              _btn('B', () => _wrap('**', '**'), bold: true),
              _btn('I', () => _wrap('*', '*'), italic: true),
              _divider(),
              _btn('`', () => _wrap('`', '`')),
              _btn('```', () => _codeBlock()),
              _divider(),
              _btn('—', () => _linePrefix('- ')),          // list
              _btn('☐', () => _linePrefix('- [ ] ')),      // checkbox
              _btn('❝', () => _linePrefix('> ')),          // blockquote
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _btn(String label, VoidCallback onTap,
      {bool bold = false, bool italic = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  Widget _divider() => const SizedBox(
        width: 1, height: 24,
        child: VerticalDivider(width: 1),
      );

  // ── Text operations ───────────────────────────────────────────────

  /// Inserts [prefix] at the start of the line containing the cursor.
  void _linePrefix(String prefix) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;

    // Find the start of the current line.
    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;

    // Check if the prefix already exists to allow toggling.
    if (text.substring(lineStart).startsWith(prefix)) {
      // Toggle off: remove the prefix.
      final newText =
          text.substring(0, lineStart) + text.substring(lineStart + prefix.length);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: (sel.start - prefix.length).clamp(lineStart, newText.length)),
      );
    } else {
      // Toggle on: insert the prefix.
      final newText =
          text.substring(0, lineStart) + prefix + text.substring(lineStart);
      controller.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: sel.start + prefix.length),
      );
    }
  }

  /// Wraps the current selection (or a placeholder) with [before] and [after].
  void _wrap(String before, String after) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;

    final selected = sel.textInside(text);
    final inner = selected.isEmpty ? 'text' : selected;
    final replacement = '$before$inner$after';
    final newText =
        text.substring(0, sel.start) + replacement + text.substring(sel.end);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: sel.start + before.length,
        extentOffset: sel.start + before.length + inner.length,
      ),
    );
  }

  /// Inserts a fenced code block and positions the cursor inside it.
  void _codeBlock() {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;

    const block = '```\n\n```';
    final newText =
        text.substring(0, sel.start) + block + text.substring(sel.end);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
          offset: sel.start + 4), // inside the block, after '```\n'
    );
  }
}
