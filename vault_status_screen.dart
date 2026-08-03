import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_time_helpers.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../data/vault_model.dart';
import '../logic/document_provider.dart';
import '../logic/documents_list_provider.dart';
import '../logic/vault_refresh_provider.dart';

/// Vault name/location, indexed document count, and manual refresh —
/// Sprint 20 Tasks 1/2/5.
///
/// New screen rather than an addition to DocumentsListScreen — same
/// reasoning as every prior sprint's new screens: additive and
/// independent beats touching an already-approved one. Registered at
/// `/vault-status`; like `/documents` and `/views` before it, nothing
/// links to it yet — a navigation/IA decision left for you.
class VaultStatusScreen extends ConsumerWidget {
  const VaultStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(activeVaultProvider);
    final documentsAsync = ref.watch(documentsProvider);
    final refreshAsync = ref.watch(vaultRefreshProvider);
    final refreshing = refreshAsync.when(
      loading: () => true,
      data: (_) => false,
      error: (_, __) => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Vault Status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Vault'),
          const SizedBox(height: 8),
          vaultAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(
              message: 'Could not load vault information',
              error: error,
            ),
            data: (vault) => _VaultInfoRows(
              vault: vault,
              documentCount: documentsAsync.valueOrNull?.length,
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Last Refresh'),
          const SizedBox(height: 8),
          _LastRefreshInfo(refreshAsync: refreshAsync),
          const SizedBox(height: 24),
          PrimaryButton(
            label: refreshing ? 'Refreshing…' : 'Refresh Vault',
            icon: Icons.refresh,
            onPressed: refreshing
                ? null
                : () => ref.read(vaultRefreshProvider.notifier).refreshNow(),
          ),
        ],
      ),
    );
  }
}

class _VaultInfoRows extends StatelessWidget {
  const _VaultInfoRows({required this.vault, required this.documentCount});

  final Vault? vault;
  final int? documentCount;

  @override
  Widget build(BuildContext context) {
    if (vault == null) {
      // Task 4's "missing vault" — shown as an empty state, not an
      // error: there's nothing wrong, there's just nothing configured
      // yet (the exact same UnimplementedError-to-null pattern
      // activeVaultProvider itself already uses).
      return const EmptyState(
        icon: Icons.folder_outlined,
        title: 'No vault configured',
        message: 'Set one up in Settings to see vault details here.',
      );
    }

    final v = vault!;
    final location = v.rootPath.trim().isEmpty
        ? '(managed internally — no filesystem path)'
        : v.rootPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(label: 'Name', value: v.name),
        _InfoRow(label: 'Location', value: location),
        _InfoRow(
          label: 'Indexed documents',
          value: documentCount?.toString() ?? '—',
        ),
      ],
    );
  }
}

class _LastRefreshInfo extends StatelessWidget {
  const _LastRefreshInfo({required this.refreshAsync});

  final AsyncValue<VaultRefreshStatus?> refreshAsync;

  @override
  Widget build(BuildContext context) {
    return refreshAsync.when(
      loading: () => const _InfoRow(label: 'Last refresh', value: '…'),
      error: (error, _) => ErrorState(
        message: 'The last refresh failed',
        error: error,
      ),
      data: (status) {
        if (status == null) {
          return const _InfoRow(label: 'Last refresh', value: 'Never');
        }
        final when = '${formatCompactDate(status.completedAt)} at '
            '${formatTime(status.completedAt)}';
        final changedCount = status.changedFilePaths.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Last refresh', value: when),
            _InfoRow(
              label: 'Files changed',
              value: changedCount == 0 ? 'None' : '$changedCount',
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
