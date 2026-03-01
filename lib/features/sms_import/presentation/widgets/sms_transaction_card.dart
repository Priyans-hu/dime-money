import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/features/sms_import/data/models/parsed_sms.dart';
import 'package:dime_money/features/sms_import/presentation/providers/sms_import_provider.dart';
import 'package:dime_money/features/settings/presentation/providers/settings_provider.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

class SmsTransactionCard extends ConsumerWidget {
  final ParsedSms item;
  final int index;

  const SmsTransactionCard({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpense = item.type == TransactionType.expense;
    final amountColor = isExpense ? Colors.red : Colors.green;
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final currencySymbol = ref.watch(currencySymbolProvider);

    final categoriesAsync = ref.watch(allCategoriesProvider);
    final accountsAsync = ref.watch(allAccountsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Checkbox + Amount + Type chip + Date
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: item.selected,
                    onChanged: (_) => ref
                        .read(smsImportProvider.notifier)
                        .toggleItem(index),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isExpense ? "-" : "+"}$currencySymbol${item.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpense ? 'Expense' : 'Income',
                    style: theme.textTheme.labelSmall?.copyWith(color: amountColor),
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(item.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            if (item.merchant != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  item.merchant!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Row 2: Category picker + Account picker
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Row(
                children: [
                  // Category chip
                  categoriesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (categories) {
                      final cat = categories.cast<Category?>().firstWhere(
                        (c) => c!.id == item.effectiveCategoryId,
                        orElse: () => null,
                      );
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showCategoryPicker(context, ref, categories),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cat != null
                                ? Color(cat.color).withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (cat != null)
                                Icon(
                                  IconData(cat.iconCodePoint, fontFamily: cat.iconFontFamily),
                                  size: 14,
                                  color: Color(cat.color),
                                ),
                              if (cat != null) const SizedBox(width: 4),
                              Text(
                                cat?.name ?? 'Category',
                                style: theme.textTheme.labelSmall,
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 8),

                  // Account chip
                  accountsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (accounts) {
                      final acct = accounts.cast<Account?>().firstWhere(
                        (a) => a!.id == item.selectedAccountId,
                        orElse: () => accounts.isNotEmpty ? accounts.first : null,
                      );
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showAccountPicker(context, ref, accounts),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: acct != null
                                ? Color(acct.color).withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (acct != null)
                                Icon(
                                  IconData(acct.iconCodePoint, fontFamily: 'MaterialIcons'),
                                  size: 14,
                                  color: Color(acct.color),
                                ),
                              if (acct != null) const SizedBox(width: 4),
                              Text(
                                acct?.name ?? 'Account',
                                style: theme.textTheme.labelSmall,
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  if (item.accountLast4 != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'xx${item.accountLast4}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, WidgetRef ref, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...categories.map((cat) => ListTile(
            leading: Icon(
              IconData(cat.iconCodePoint, fontFamily: cat.iconFontFamily),
              color: Color(cat.color),
            ),
            title: Text(cat.name),
            selected: cat.id == item.effectiveCategoryId,
            onTap: () {
              ref.read(smsImportProvider.notifier).updateCategory(index, cat.id);
              Navigator.pop(ctx);
            },
          )),
        ],
      ),
    );
  }

  void _showAccountPicker(BuildContext context, WidgetRef ref, List<Account> accounts) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...accounts.map((acct) => ListTile(
            leading: Icon(
              IconData(acct.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: Color(acct.color),
            ),
            title: Text(acct.name),
            selected: acct.id == item.selectedAccountId,
            onTap: () {
              ref.read(smsImportProvider.notifier).updateAccount(index, acct.id);
              Navigator.pop(ctx);
            },
          )),
        ],
      ),
    );
  }
}
