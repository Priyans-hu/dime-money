import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/extensions/currency_ext.dart';
import 'package:dime_money/core/extensions/date_ext.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

class TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;
    final sign = isExpense ? '-' : '+';
    final color = isExpense ? Colors.red : Colors.green;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        Haptics.medium();
        return true;
      },
      onDismissed: (_) => onDismissed?.call(),
      child: ListTile(
        onTap: onTap,
        leading: categoriesAsync.when(
          loading: () => const CircleAvatar(child: Icon(Icons.hourglass_empty)),
          error: (_, _) => const CircleAvatar(child: Icon(Icons.error)),
          data: (categories) {
            if (isTransfer) {
              return CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.swap_horiz,
                    color: Theme.of(context).colorScheme.primary),
              );
            }
            final cat = transaction.categoryId != null
                ? categories
                    .where((c) => c.id == transaction.categoryId)
                    .firstOrNull
                : null;
            if (cat == null) {
              return const CircleAvatar(child: Icon(Icons.help_outline));
            }
            return CircleAvatar(
              backgroundColor: Color(cat.color).withValues(alpha: 0.15),
              child: Icon(
                IconData(cat.iconCodePoint, fontFamily: cat.iconFontFamily),
                color: Color(cat.color),
              ),
            );
          },
        ),
        title: categoriesAsync.when(
          loading: () => const Text('...'),
          error: (_, _) => const Text('Error'),
          data: (categories) {
            if (isTransfer) return const Text('Transfer');
            final cat = transaction.categoryId != null
                ? categories
                    .where((c) => c.id == transaction.categoryId)
                    .firstOrNull
                : null;
            return Text(cat?.name ?? 'Uncategorized');
          },
        ),
        subtitle: transaction.note.isNotEmpty
            ? Text(
                transaction.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text(transaction.date.shortFormatted),
        trailing: Text(
          '$sign${transaction.amount.formatCurrency()}',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
