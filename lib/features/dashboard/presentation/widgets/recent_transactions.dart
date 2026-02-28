import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/features/transactions/presentation/widgets/quick_add_sheet.dart';
import 'package:dime_money/features/transactions/presentation/widgets/transaction_tile.dart';

class RecentTransactions extends ConsumerWidget {
  const RecentTransactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsProvider);

    return recentAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No recent transactions',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline),
              ),
            ),
          );
        }

        return Column(
          children: transactions
              .map((txn) => TransactionTile(
                    transaction: txn,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            QuickAddSheet(editTransaction: txn),
                      );
                    },
                    onDismissed: () {
                      final repo =
                          ref.read(transactionRepositoryProvider);
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
                    },
                  ))
              .toList(),
        );
      },
    );
  }
}
