import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../logic/search_service.dart';
import '../logic/tag_provider.dart';

/// Every tag in use across the vault, with how many documents carry
/// each — Sprint 21 Task 5's Tag Explorer. Tapping a tag pushes
/// `TagDocumentsScreen` (tag_documents_screen.dart) filtered to it.
///
/// Registered at the `/tags` route. Same "not yet linked from
/// navigation" situation as Search, Documents, and Views before it —
/// see search_screen.dart's doc comment for the fuller rationale.
class TagExplorerScreen extends ConsumerWidget {
  const TagExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagCountsAsync = ref.watch(tagCountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      body: tagCountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load tags',
          error: error,
        ),
        data: (tagCounts) {
          if (tagCounts.isEmpty) {
            return const EmptyState(
              icon: Icons.label_outline,
              title: 'No tags yet',
              message: "Add tags to a document's frontmatter to see "
                  'them here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: tagCounts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _TagTile(
              tagCount: tagCounts[index],
            ),
          );
        },
      ),
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({required this.tagCount});

  final TagCount tagCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: const Icon(Icons.label_outline),
      title: Text('#${tagCount.tag}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${tagCount.count}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
      onTap: () => context.push('/tag', extra: tagCount.tag),
    );
  }
}
