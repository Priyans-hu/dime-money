import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/extensions/date_ext.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/features/transactions/presentation/widgets/quick_add_sheet.dart';
import 'package:dime_money/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:dime_money/shared/widgets/empty_state.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  String _searchQuery = '';
  bool _showSearch = false;

  void _openEditSheet(Transaction txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => QuickAddSheet(editTransaction: txn),
    );
  }

  void _deleteWithUndo(Transaction txn) {
    final repo = ref.read(transactionRepositoryProvider);
    repo.deleteById(txn.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            repo.insert(
              type: txn.type,
              amount: txn.amount,
              categoryId: txn.categoryId,
              accountId: txn.accountId,
              toAccountId: txn.toAccountId,
              note: txn.note,
              date: txn.date,
              recurringRuleId: txn.recurringRuleId,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = _searchQuery.isEmpty
        ? ref.watch(allTransactionsProvider)
        : ref.watch(searchTransactionsProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchQuery = '';
            }),
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              subtitle: 'Tap + to add your first expense',
            );
          }

          // Group by date
          final grouped = <String, List<Transaction>>{};
          for (final txn in transactions) {
            final label = txn.date.relativeLabel;
            grouped.putIfAbsent(label, () => []).add(txn);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateLabel = grouped.keys.elementAt(index);
              final items = grouped[dateLabel]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      dateLabel,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                  ...items.map((txn) => TransactionTile(
                        transaction: txn,
                        onTap: () => _openEditSheet(txn),
                        onDismissed: () => _deleteWithUndo(txn),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
