import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_helpers.dart';
import '../../data/document_model.dart';

/// A single document, shown as a Material 3 [Card].
///
/// Mirrors ObjectiveCard's shape (objectives/presentation/widgets/
/// objective_card.dart): a pure Presentation-layer widget that holds no
/// state and calls no repository/provider itself — every callback is
/// supplied by whoever places it, and a null callback simply hides
/// nothing here (the buttons stay visible but inert), matching how
/// ObjectiveCard's own onEdit/onArchive/onDelete are handled.
class DocumentListCard extends StatelessWidget {
  const DocumentListCard({
    super.key,
    required this.document,
    this.onTap,
    this.onRename,
    this.onDuplicate,
    this.onDelete,
  });

  final Document document;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = document.content.trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  preview,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Edited ${formatCompactDate(document.updatedAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onRename,
                    icon: const Icon(
                      Icons.drive_file_rename_outline,
                      size: 18,
                    ),
                    label: const Text('Rename'),
                  ),
                  TextButton.icon(
                    onPressed: onDuplicate,
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Duplicate'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
