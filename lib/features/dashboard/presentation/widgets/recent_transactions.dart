import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
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
                    onDismissed: () {
                      ref
                          .read(transactionRepositoryProvider)
                          .deleteById(txn.id);
                    },
                  ))
              .toList(),
        );
      },
    );
  }
}
