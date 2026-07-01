import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/extensions.dart';
import '../provider/sync_provider.dart';
import '../widgets/sync_status_tile.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Sync Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SyncStatusTile(
            label: 'Pending',
            value: state.pendingCount.toString(),
            icon: Icons.hourglass_empty,
            color: theme.colorScheme.tertiaryContainer,
          ),
          SyncStatusTile(
            label: 'Failed',
            value: state.failedCount.toString(),
            icon: Icons.error_outline,
            color: theme.colorScheme.errorContainer,
          ),
          SyncStatusTile(
            label: 'Synced',
            value: state.syncedCount.toString(),
            icon: Icons.check_circle_outline,
            color: theme.colorScheme.primaryContainer,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Last Sync'),
              subtitle: Text(
                state.lastSyncTime?.formattedDateTime ?? 'Never',
              ),
            ),
          ),
          if (state.isSyncing) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text('Syncing...',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                      ],
                    ),
                    if (state.incomingStatus.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...state.incomingStatus.entries.map((e) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              _incomingIcon(e.value.success),
                              const SizedBox(width: 8),
                              Text(e.value.label, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (state.incomingStatus.isNotEmpty && !state.isSyncing) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Server Data',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                    const SizedBox(height: 8),
                    ...state.incomingStatus.entries.map((e) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            _incomingIcon(e.value.success),
                            const SizedBox(width: 8),
                            Text(e.value.label, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!state.isSyncing) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(syncProvider.notifier).syncAll(),
              icon: const Icon(Icons.sync),
              label: const Text('Sync All'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            if (state.syncResult) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Sync completed successfully!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            if (state.pendingQueue.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Pending Items',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...state.pendingQueue.map((entry) {
                return Card(
                  child: ListTile(
                    leading: Icon(
                      entry.entityType == 'Delivery'
                          ? Icons.local_shipping
                          : Icons.receipt_long,
                    ),
                    title: Text('${entry.entityType} #${entry.entityId}'),
                    subtitle: Text(
                      'Status: ${entry.status}',
                      style: TextStyle(
                        color: entry.status == 'Failed'
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: _statusIcon(entry.status),
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  Widget _incomingIcon(bool? success) {
    if (success == null) {
      return const SizedBox(
        width: 14, height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(
      success ? Icons.check_circle : Icons.error,
      size: 16,
      color: success ? Colors.green : Colors.red,
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case 'Synced':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'Failed':
        return const Icon(Icons.error, color: Colors.red);
      case 'Syncing':
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      default:
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
    }
  }
}
