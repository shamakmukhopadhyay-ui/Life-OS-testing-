import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../data/document_model.dart';
import '../logic/documents_list_provider.dart';
import 'widgets/document_list_card.dart';

/// Full-screen list of every document in the active vault.
///
/// New in Sprint 16 — no document list screen existed before this;
/// documents were previously only reachable one at a time (e.g. Day
/// Workspace's daily-note tile opening straight into the editor). This
/// is the polish target for Sprint 16 Task 4, built to match
/// ObjectivesScreen's structure as closely as documents' own shape
/// allows: same loading/error/empty gating, same confirm-before-delete
/// dialog pattern.
///
/// Registered at the `/documents` route in app_router.dart. Not yet
/// linked from anywhere (no bottom-nav tab or Home card points here) —
/// that's a navigation/IA decision left for you, not assumed here.
class DocumentsListScreen extends ConsumerWidget {
  const DocumentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);
    final notifier = ref.read(documentsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Failed to load documents',
          error: error,
        ),
        data: (documents) => _DocumentsListBody(
          documents: documents,
          notifier: notifier,
        ),
      ),
    );
  }
}

class _DocumentsListBody extends StatelessWidget {
  const _DocumentsListBody({required this.documents, required this.notifier});

  final List<Document> documents;
  final DocumentsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    // RefreshIndicator needs a scrollable descendant to detect the pull
    // gesture even when there's nothing to show yet, so the empty state
    // is wrapped in a (non-scrolling-in-practice) ListView rather than
    // just centered directly.
    if (documents.isEmpty) {
      return RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            EmptyState(
              icon: Icons.description_outlined,
              title: 'No documents yet',
              message: 'Documents you create will show up here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          return DocumentListCard(
            document: doc,
            onTap: () => context.push('/document', extra: doc),
            onRename: () => _showRenameDialog(context, notifier, doc),
            onDuplicate: () => _duplicate(context, notifier, doc),
            onDelete: () => _confirmDelete(context, notifier, doc),
          );
        },
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    DocumentsNotifier notifier,
    Document document,
  ) async {
    final controller = TextEditingController(text: document.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();

    final cleanTitle = newTitle?.trim() ?? '';
    if (cleanTitle.isEmpty || cleanTitle == document.title) return;

    try {
      await notifier.renameDocument(document.path, cleanTitle);
    } catch (e) {
      _showError(context, 'Could not rename document', e);
    }
  }

  Future<void> _duplicate(
    BuildContext context,
    DocumentsNotifier notifier,
    Document document,
  ) async {
    try {
      await notifier.duplicateDocument(document.path);
    } catch (e) {
      _showError(context, 'Could not duplicate document', e);
    }
  }

  // Mirrors ObjectivesScreen._confirmDelete exactly (same dialog shape,
  // same Cancel/Delete wording) for consistency between the two list
  // screens.
  Future<void> _confirmDelete(
    BuildContext context,
    DocumentsNotifier notifier,
    Document document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          'This will permanently remove "${document.title}". '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await notifier.deleteDocument(document.path);
    } catch (e) {
      _showError(context, 'Could not delete document', e);
    }
  }

  void _showError(BuildContext context, String message, Object error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message: $error')),
    );
  }
}
