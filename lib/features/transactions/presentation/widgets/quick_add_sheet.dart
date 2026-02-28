import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/features/transactions/presentation/widgets/amount_keypad.dart';
import 'package:dime_money/features/transactions/presentation/widgets/category_picker_grid.dart';
import 'package:dime_money/features/transactions/presentation/widgets/account_selector.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  String _amount = '';
  int? _categoryId;
  int? _accountId;
  TransactionType _type = TransactionType.expense;
  final _noteController = TextEditingController();
  int _step = 0; // 0 = amount, 1 = category, 2 = confirm

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _parsedAmount => double.tryParse(_amount) ?? 0;

  void _submit() async {
    if (_parsedAmount <= 0 || _accountId == null) return;
    if (_type != TransactionType.transfer && _categoryId == null) return;

    Haptics.medium();

    await ref.read(transactionRepositoryProvider).insert(
          type: _type,
          amount: _parsedAmount,
          categoryId: _categoryId,
          accountId: _accountId!,
          note: _noteController.text.trim(),
          date: DateTime.now(),
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(allAccountsProvider);

    // Auto-select first account
    if (_accountId == null) {
      accounts.whenData((list) {
        if (list.isNotEmpty && _accountId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _accountId = list.first.id);
          });
        }
      });
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Type toggle
          Row(
            children: [
              _TypeChip(
                label: 'Expense',
                selected: _type == TransactionType.expense,
                color: Colors.red,
                onTap: () => setState(() {
                  _type = TransactionType.expense;
                  Haptics.selection();
                }),
              ),
              const Gap(8),
              _TypeChip(
                label: 'Income',
                selected: _type == TransactionType.income,
                color: Colors.green,
                onTap: () => setState(() {
                  _type = TransactionType.income;
                  Haptics.selection();
                }),
              ),
            ],
          ),
          const Gap(16),

          // Amount display
          Center(
            child: Text(
              _amount.isEmpty ? '0' : _amount,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _type == TransactionType.expense
                        ? Colors.red
                        : Colors.green,
                  ),
            ),
          ),
          const Gap(8),

          if (_step == 0) ...[
            // Keypad
            AmountKeypad(
              currentAmount: _amount,
              onAmountChanged: (v) => setState(() => _amount = v),
              onDone: _parsedAmount > 0
                  ? () => setState(() => _step = 1)
                  : null,
            ),
          ] else if (_step == 1) ...[
            // Category picker
            Text('Category',
                style: Theme.of(context).textTheme.titleSmall),
            const Gap(8),
            CategoryPickerGrid(
              selectedId: _categoryId,
              onSelected: (cat) => setState(() {
                _categoryId = cat.id;
                _step = 2;
              }),
            ),
          ] else ...[
            // Account + note + confirm
            Text('Account',
                style: Theme.of(context).textTheme.titleSmall),
            const Gap(8),
            AccountSelector(
              selectedId: _accountId,
              onSelected: (a) => setState(() => _accountId = a.id),
            ),
            const Gap(12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Add a note (optional)',
                prefixIcon: Icon(Icons.note_outlined),
                isDense: true,
              ),
              textInputAction: TextInputAction.done,
            ),
            const Gap(16),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('Back'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('Add'),
                ),
              ],
            ),
          ],
          const Gap(8),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Theme.of(context).colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
