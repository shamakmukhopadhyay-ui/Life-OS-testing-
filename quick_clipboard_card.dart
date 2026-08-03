import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/quick_clipboard_provider.dart';

/// A lightweight, always-available scratchpad on the Home dashboard —
/// Sprint 22 V2-02 Task 4.
///
/// Plain text in, plain text out: no markdown parsing/rendering here,
/// by design ("no markdown parsing") — this is deliberately a simpler
/// text box, not a second document editor. "Future AI will consume
/// this" is why it exists at all; nothing here does anything AI-shaped
/// yet.
///
/// `ConsumerStatefulWidget` + `TextEditingController` + a debounced
/// `Timer`, same shape as `document_editor_screen.dart`'s autosave
/// (same 800ms delay) — this project's established pattern for "a text
/// field that saves itself a moment after typing stops."
class QuickClipboardCard extends ConsumerStatefulWidget {
  const QuickClipboardCard({super.key});

  @override
  ConsumerState<QuickClipboardCard> createState() =>
      _QuickClipboardCardState();
}

class _QuickClipboardCardState extends ConsumerState<QuickClipboardCard> {
  static const _debounceDelay = Duration(milliseconds: 800);

  late final TextEditingController _controller;
  Timer? _debounce;
  bool _loadedInitialValue = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      ref.read(quickClipboardProvider.notifier).save(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clipboardAsync = ref.watch(quickClipboardProvider);
    final theme = Theme.of(context);

    // Seeds the controller once, the first time the persisted value
    // arrives — afterwards this widget is the source of truth for what
    // the user is typing, so later provider updates (from this same
    // widget's own saves) must not overwrite the live text mid-edit.
    if (!_loadedInitialValue) {
      final loaded = clipboardAsync.valueOrNull;
      if (loaded != null) {
        _controller.text = loaded;
        _loadedInitialValue = true;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sticky_note_2_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Quick Clipboard', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              onChanged: _onChanged,
              maxLines: 4,
              minLines: 4,
              decoration: const InputDecoration(
                hintText: 'Jot something down…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
