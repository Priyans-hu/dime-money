import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/extensions/currency_ext.dart';
import 'package:dime_money/core/extensions/date_ext.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/core/utils/sheet_padding.dart';
import 'package:dime_money/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/shared/widgets/empty_state.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(allRecurringRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring')),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: 72 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddRule(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return const EmptyState(
              icon: Icons.repeat,
              title: 'No recurring transactions',
              subtitle: 'Tap + to set up auto-repeating expenses',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return _RecurringRuleTile(rule: rule);
            },
          );
        },
      ),
    );
  }

  void _showAddRule(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var type = TransactionType.expense;
    var recurrence = RecurrenceType.monthly;
    int? categoryId;
    int? accountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final categoriesAsync = ref.watch(allCategoriesProvider);
        final accountsAsync = ref.watch(allAccountsProvider);

        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: sheetBottomPadding(context),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('New Recurring',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Gap(16),
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Expense')),
                      ButtonSegment(
                          value: TransactionType.income,
                          label: Text('Income')),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) =>
                        setSheetState(() => type = s.first),
                  ),
                  const Gap(12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const Gap(12),
                  SegmentedButton<RecurrenceType>(
                    segments: RecurrenceType.values
                        .map((r) => ButtonSegment(
                              value: r,
                              label: Text(r.name[0].toUpperCase() +
                                  r.name.substring(1)),
                            ))
                        .toList(),
                    selected: {recurrence},
                    onSelectionChanged: (s) =>
                        setSheetState(() => recurrence = s.first),
                    style: ButtonStyle(
                        visualDensity: VisualDensity.compact),
                  ),
                  const Gap(12),
                  categoriesAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, _) => const Text('Error'),
                    data: (cats) => DropdownButtonFormField<int>(
                      initialValue: categoryId,
                      decoration:
                          const InputDecoration(labelText: 'Category'),
                      items: cats
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => categoryId = v),
                    ),
                  ),
                  const Gap(12),
                  accountsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, _) => const Text('Error'),
                    data: (accts) => DropdownButtonFormField<int>(
                      initialValue: accountId,
                      decoration:
                          const InputDecoration(labelText: 'Account'),
                      items: accts
                          .map((a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => accountId = v),
                    ),
                  ),
                  const Gap(12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: 'Note (optional)',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),
                  const Gap(16),
                  FilledButton(
                    onPressed: () async {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      if (amount <= 0 || accountId == null) return;
                      Haptics.medium();
                      await ref
                          .read(recurringRepositoryProvider)
                          .insert(
                            type: type,
                            amount: amount,
                            categoryId: categoryId,
                            accountId: accountId!,
                            note: noteController.text.trim(),
                            recurrence: recurrence,
                            startDate: DateTime.now(),
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Create Rule'),
                  ),
                  const Gap(8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecurringRuleTile extends ConsumerWidget {
  final RecurringRule rule;

  const _RecurringRuleTile({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final isExpense = rule.type == TransactionType.expense;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isExpense ? Colors.red : Colors.green)
              .withValues(alpha: 0.15),
          child: Icon(
            Icons.repeat,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        title: categoriesAsync.when(
          loading: () => const Text('...'),
          error: (_, _) => const Text('Error'),
          data: (cats) {
            final cat = rule.categoryId != null
                ? cats.where((c) => c.id == rule.categoryId).firstOrNull
                : null;
            return Text(cat?.name ?? rule.note);
          },
        ),
        subtitle: Text(
          '${rule.recurrence.name} · started ${rule.startDate.shortFormatted}',
        ),
        trailing: Text(
          '${isExpense ? "-" : "+"}${rule.amount.formatCurrency()}',
          style: TextStyle(
            color: isExpense ? Colors.red : Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
        onLongPress: () async {
          Haptics.medium();
          await ref
              .read(recurringRepositoryProvider)
              .deleteById(rule.id);
        },
      ),
    );
  }
}
