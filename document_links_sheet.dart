import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../data/document_model.dart';
import '../../logic/backlink_provider.dart';

/// Outgoing Links / Backlinks / Broken Links for one document —
/// Sprint 22 Task 5. Shown from `document_editor_screen.dart` via
/// `showModalBottomSheet`, not inlined into that screen's body (which
/// stays the untouched full-screen `TextField` it's been since
/// Sprint 15) and not a new file under `presentation/` directly, to
/// keep this clearly a supporting widget rather than a screen.
class DocumentLinksSheet extends ConsumerWidget {
  const DocumentLinksSheet({super.key, required this.documentPath});

  final String documentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(documentLinksProvider(documentPath));

    return SafeArea(
      child: linksAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorState(message: 'Could not load links', error: error),
        ),
        data: (links) => ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            SectionHeader(title: 'Outgoing Links (${links.outgoing.length})'),
            if (links.outgoing.isEmpty)
              const _EmptyRow('No outgoing links.')
            else
              for (final resolved in links.outgoing)
                ListTile(
                  leading: const Icon(Icons.arrow_outward),
                  title: Text(resolved.link.displayText),
                  subtitle: Text(resolved.document.title),
                  onTap: () => _openDocument(context, resolved.document),
                ),
            const SizedBox(height: 8),
            SectionHeader(title: 'Backlinks (${links.incoming.length})'),
            if (links.incoming.isEmpty)
              const _EmptyRow('No backlinks yet.')
            else
              for (final document in links.incoming)
                ListTile(
                  leading: const Icon(Icons.arrow_back),
                  title: Text(document.title),
                  onTap: () => _openDocument(context, document),
                ),
            if (links.broken.isNotEmpty) ...[
              const SizedBox(height: 8),
              SectionHeader(title: 'Broken Links (${links.broken.length})'),
              for (final broken in links.broken)
                ListTile(
                  leading: Icon(
                    Icons.link_off,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(broken.displayText),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _openDocument(BuildContext context, Document document) {
    Navigator.of(context).pop();
    context.push('/document', extra: document);
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}
