import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/features/sms_import/presentation/providers/sms_import_provider.dart';
import 'package:dime_money/features/sms_import/presentation/widgets/sms_transaction_card.dart';

class SmsReviewScreen extends ConsumerStatefulWidget {
  const SmsReviewScreen({super.key});

  @override
  ConsumerState<SmsReviewScreen> createState() => _SmsReviewScreenState();
}

class _SmsReviewScreenState extends ConsumerState<SmsReviewScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-start scan when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smsImportProvider.notifier).startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsImportProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from SMS'),
        actions: [
          if (state.status == SmsImportStatus.ready && state.transactions.isNotEmpty)
            TextButton.icon(
              onPressed: state.selectedCount > 0
                  ? () => ref.read(smsImportProvider.notifier).importSelected()
                  : null,
              icon: const Icon(Icons.check, size: 18),
              label: Text('Import (${state.selectedCount})'),
            ),
        ],
      ),
      body: _buildBody(context, state, theme),
    );
  }

  Widget _buildBody(BuildContext context, SmsImportState state, ThemeData theme) {
    switch (state.status) {
      case SmsImportStatus.idle:
      case SmsImportStatus.requestingPermission:
      case SmsImportStatus.scanning:
      case SmsImportStatus.parsing:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _statusMessage(state.status),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );

      case SmsImportStatus.permissionDenied:
        return _buildPermissionDenied(context, theme);

      case SmsImportStatus.notificationFallback:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Reading notifications...'),
            ],
          ),
        );

      case SmsImportStatus.ready:
        if (state.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'No new transactions found',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.source == ImportSource.notification
                      ? 'No financial notifications in the notification shade'
                      : 'All SMS transactions have already been imported\nor no financial SMS found in the last 90 days',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }
        return _buildTransactionList(state);

      case SmsImportStatus.importing:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Importing transactions...'),
            ],
          ),
        );

      case SmsImportStatus.done:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
              const SizedBox(height: 16),
              Text(
                '${state.importedCount} transaction${state.importedCount == 1 ? '' : 's'} imported',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );

      case SmsImportStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'An error occurred',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    final notifier = ref.read(smsImportProvider.notifier);
                    if (state.source == ImportSource.notification) {
                      notifier.startNotificationScan();
                    } else {
                      notifier.startScan();
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildPermissionDenied(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sms_failed, size: 64, color: theme.colorScheme.error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              'SMS Permission Denied',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You can still import transactions by reading bank notifications instead.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(smsImportProvider.notifier).startNotificationScan(),
              icon: const Icon(Icons.notifications),
              label: const Text('Use Notification Access'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(smsImportProvider.notifier).startScan(),
              child: const Text('Try SMS Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(SmsImportState state) {
    final allSelected = state.transactions.every((t) => t.selected);

    return Column(
      children: [
        // Select all / deselect all toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${state.transactions.length} transaction${state.transactions.length == 1 ? '' : 's'} found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => ref
                    .read(smsImportProvider.notifier)
                    .toggleAll(!allSelected),
                child: Text(allSelected ? 'Deselect all' : 'Select all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.transactions.length,
            itemBuilder: (context, index) {
              return SmsTransactionCard(
                item: state.transactions[index],
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  String _statusMessage(SmsImportStatus status) {
    switch (status) {
      case SmsImportStatus.requestingPermission:
        return 'Requesting permission...';
      case SmsImportStatus.scanning:
        return 'Scanning messages...';
      case SmsImportStatus.parsing:
        return 'Parsing transactions...';
      default:
        return 'Loading...';
    }
  }
}
