import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quick_clipboard_repository.dart';

final quickClipboardRepositoryProvider = Provider<QuickClipboardRepository>((
  ref,
) {
  return const FileQuickClipboardRepository();
});

/// Holds Quick Clipboard's current text and persists changes —
/// Sprint 22 V2-02 Task 4.
class QuickClipboardNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() {
    return ref.read(quickClipboardRepositoryProvider).read();
  }

  /// Persists [content] and updates state to match. Called from the
  /// widget's own debounce timer (Task 4's "autosave") — this method
  /// itself has no timing logic; it just writes through and reflects
  /// the result, same shape as every other notifier's mutation methods
  /// in this project.
  Future<void> save(String content) async {
    await ref.read(quickClipboardRepositoryProvider).write(content);
    state = AsyncValue.data(content);
  }
}

final quickClipboardProvider =
    AsyncNotifierProvider<QuickClipboardNotifier, String>(
  QuickClipboardNotifier.new,
);
