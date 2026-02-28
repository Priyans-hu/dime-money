import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/settings/presentation/providers/settings_provider.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/features/transactions/presentation/widgets/amount_keypad.dart';
import 'package:dime_money/features/transactions/presentation/widgets/category_picker_grid.dart';
import 'package:dime_money/features/transactions/presentation/widgets/account_selector.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  /// Pass an existing transaction to open in edit mode.
  final Transaction? editTransaction;

  const QuickAddSheet({super.key, this.editTransaction});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  String _amount = '';
  int? _categoryId;
  int? _accountId;
  bool _accountInitialized = false;
  TransactionType _type = TransactionType.expense;
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _step = 0; // 0 = amount, 1 = category, 2 = confirm

  bool get _isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    final txn = widget.editTransaction;
    if (txn != null) {
      _type = txn.type;
      _amount = txn.amount.toString();
      // Remove trailing .0 for whole numbers
      if (_amount.endsWith('.0')) {
        _amount = _amount.substring(0, _amount.length - 2);
      }
      _categoryId = txn.categoryId;
      _accountId = txn.accountId;
      _accountInitialized = true;
      _noteController.text = txn.note;
      _selectedDate = txn.date;
      _step = 2; // Jump to confirm step for editing
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _parsedAmount => double.tryParse(_amount) ?? 0;

  void _nextStep() {
    if (_step == 0) {
      if (_parsedAmount <= 0) {
        _showError('Enter an amount');
        return;
      }
      Haptics.selection();
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_categoryId == null) {
        _showError('Pick a category');
        return;
      }
      Haptics.selection();
      setState(() => _step = 2);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      Haptics.selection();
      setState(() => _step -= 1);
    }
  }

  void _showError(String message) {
    Haptics.heavy();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() async {
    if (_parsedAmount <= 0) {
      _showError('Enter an amount');
      return;
    }
    if (_accountId == null) {
      _showError('Select an account');
      return;
    }
    if (_type != TransactionType.transfer && _categoryId == null) {
      _showError('Pick a category');
      return;
    }

    Haptics.medium();

    final repo = ref.read(transactionRepositoryProvider);

    if (_isEditing) {
      final txn = widget.editTransaction!;
      await repo.update(txn.copyWith(
        type: _type,
        amount: _parsedAmount,
        categoryId: Value(_categoryId),
        accountId: _accountId!,
        note: _noteController.text.trim(),
        date: _selectedDate,
      ));
    } else {
      await repo.insert(
        type: _type,
        amount: _parsedAmount,
        categoryId: _categoryId,
        accountId: _accountId!,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(allAccountsProvider);
    final incomeEnabled = ref.watch(incomeEnabledProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor =
        _type == TransactionType.expense ? Colors.red : Colors.green;

    // Auto-select first account (once only, for new transactions)
    if (!_accountInitialized) {
      accounts.whenData((list) {
        if (list.isNotEmpty) {
          _accountInitialized = true;
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
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: type toggle + step indicator
          Row(
            children: [
              // Type toggle
              _TypeChip(
                label: 'Expense',
                selected: _type == TransactionType.expense,
                color: Colors.red,
                onTap: () => setState(() {
                  _type = TransactionType.expense;
                  Haptics.selection();
                }),
              ),
              if (incomeEnabled) ...[
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
              const Spacer(),
              // Step indicator dots
              Row(
                children: List.generate(3, (i) {
                  final isActive = i == _step;
                  final isDone = i < _step;
                  return Container(
                    width: isActive ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isDone
                          ? typeColor
                          : isActive
                              ? typeColor.withValues(alpha: 0.7)
                              : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
          const Gap(16),

          // Amount display (always visible, tappable to go back to step 0)
          GestureDetector(
            onTap: _step != 0 ? () => setState(() => _step = 0) : null,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.watch(currencySymbolProvider),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: typeColor.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  const Gap(4),
                  Text(
                    _amount.isEmpty ? '0' : _amount,
                    style:
                        Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                  ),
                  if (_step != 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Icon(Icons.edit, size: 16, color: typeColor.withValues(alpha: 0.5)),
                    ),
                ],
              ),
            ),
          ),
          const Gap(12),

          // Step content
          if (_step == 0) ...[
            AmountKeypad(
              currentAmount: _amount,
              onAmountChanged: (v) => setState(() => _amount = v),
            ),
            const Gap(8),
            // Next button
            FilledButton(
              onPressed: _parsedAmount > 0 ? _nextStep : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: typeColor,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Gap(4),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ] else if (_step == 1) ...[
            Row(
              children: [
                IconButton(
                  onPressed: _prevStep,
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                  ),
                ),
                const Gap(8),
                Text('Pick a category',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Gap(12),
            CategoryPickerGrid(
              selectedId: _categoryId,
              onSelected: (cat) {
                setState(() {
                  _categoryId = cat.id;
                  _step = 2;
                });
              },
            ),
          ] else ...[
            // Confirm step: account, note, date, submit
            Row(
              children: [
                IconButton(
                  onPressed: _prevStep,
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                  ),
                ),
                const Gap(8),
                Text(_isEditing ? 'Edit transaction' : 'Finalize',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Gap(12),

            // Account selector
            Text('Account',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )),
            const Gap(6),
            AccountSelector(
              selectedId: _accountId,
              onSelected: (a) => setState(() => _accountId = a.id),
            ),
            const Gap(12),

            // Date picker row
            Text('Date',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )),
            const Gap(6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 18, color: colorScheme.onSurfaceVariant),
                    const Gap(8),
                    Text(
                      _formatDate(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        size: 20, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const Gap(12),

            // Note field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                prefixIcon: const Icon(Icons.note_outlined),
                isDense: true,
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.done,
              maxLength: 50,
            ),
            const Gap(8),

            // Submit button
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(_isEditing ? Icons.save : Icons.check),
              label: Text(
                _isEditing ? 'Save' : 'Add ${_type == TransactionType.expense ? 'Expense' : 'Income'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: typeColor,
              ),
            ),
          ],
          const Gap(8),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (target == today.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('EEE, d MMM yyyy').format(date);
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
          color:
              selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? color : Theme.of(context).colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
