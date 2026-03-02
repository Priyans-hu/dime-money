import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/extensions/currency_ext.dart';
import 'package:dime_money/core/extensions/date_ext.dart';
import 'package:dime_money/features/settings/presentation/providers/settings_provider.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/features/transactions/presentation/widgets/quick_add_sheet.dart';
import 'package:dime_money/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:dime_money/shared/widgets/empty_state.dart';
import 'package:dime_money/shared/widgets/snack_bar_helpers.dart';

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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_searchQuery.isNotEmpty) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedTransactionsProvider.notifier).loadMore();
    }
  }

  void _openEditSheet(Transaction txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => QuickAddSheet(editTransaction: txn),
    );
  }

  void _deleteWithUndo(Transaction txn) async {
    final repo = ref.read(transactionRepositoryProvider);
    try {
      await repo.deleteById(txn.id);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to delete: $e');
      return;
    }
    ref.read(paginatedTransactionsProvider.notifier).refresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await repo.insert(
              type: txn.type,
              amount: txn.amount,
              categoryId: txn.categoryId,
              accountId: txn.accountId,
              toAccountId: txn.toAccountId,
              note: txn.note,
              date: txn.date,
              recurringRuleId: txn.recurringRuleId,
            );
            ref.read(paginatedTransactionsProvider.notifier).refresh();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final transactionsAsync = _searchQuery.isEmpty
        ? ref.watch(paginatedTransactionsProvider)
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
            controller: _searchQuery.isEmpty ? _scrollController : null,
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateLabel = grouped.keys.elementAt(index);
              final items = grouped[dateLabel]!;

              final dayExpense = items
                  .where((t) => t.type == TransactionType.expense)
                  .fold<double>(0, (sum, t) => sum + t.amount);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
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
                        if (dayExpense > 0)
                          Text(
                            '-${dayExpense.formatCurrency(symbol: currency)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.red.withValues(alpha: 0.7),
                                ),
                          ),
                      ],
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
