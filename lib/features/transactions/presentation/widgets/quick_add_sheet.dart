import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/core/utils/sheet_padding.dart';
import 'package:dime_money/features/settings/presentation/providers/settings_provider.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/features/transactions/presentation/widgets/amount_keypad.dart';
import 'package:dime_money/features/transactions/presentation/widgets/category_picker_grid.dart';
import 'package:dime_money/features/transactions/presentation/widgets/account_selector.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  final Transaction? editTransaction;
  final TransactionType? initialType;

  const QuickAddSheet({super.key, this.editTransaction, this.initialType});

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
  bool _showKeypad = true;

  bool get _isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    final txn = widget.editTransaction;
    if (txn != null) {
      _type = txn.type;
      _amount = txn.amount.toString();
      if (_amount.endsWith('.0')) {
        _amount = _amount.substring(0, _amount.length - 2);
      }
      _categoryId = txn.categoryId;
      _accountId = txn.accountId;
      _accountInitialized = true;
      _noteController.text = txn.note;
      _selectedDate = txn.date;
      _showKeypad = false;
    } else if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _parsedAmount => double.tryParse(_amount) ?? 0;

  bool get _canSubmit =>
      _parsedAmount > 0 &&
      _accountId != null &&
      (_type == TransactionType.transfer || _categoryId != null);

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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() async {
    if (_parsedAmount <= 0) {
      _showError('Enter an amount');
      return;
    }
    if (_type != TransactionType.transfer && _categoryId == null) {
      _showError('Pick a category');
      return;
    }
    if (_accountId == null) {
      _showError('Select an account');
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (target == today.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('EEE, d MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(allAccountsProvider);
    final incomeEnabled = ref.watch(incomeEnabledProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor =
        _type == TransactionType.expense ? Colors.red : Colors.green;

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

    // Auto-select most frequent category for new transactions
    if (!_isEditing && _categoryId == null) {
      ref.watch(mostFrequentCategoryProvider).whenData((id) {
        if (id != null && _categoryId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _categoryId = id);
          });
        }
      });
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: sheetBottomPadding(context),
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

          // Type toggle row
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
              // Date chip
              ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 16),
                label: Text(_formatDate(_selectedDate)),
                onPressed: _pickDate,
              ),
            ],
          ),
          const Gap(12),

          // Amount display — tap to toggle keypad
          GestureDetector(
            onTap: () => setState(() => _showKeypad = !_showKeypad),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      ref.watch(currencySymbolProvider),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                  ],
                ),
              ),
            ),
          ),

          // Keypad (collapsible)
          AnimatedCrossFade(
            firstChild: AmountKeypad(
              currentAmount: _amount,
              onAmountChanged: (v) => setState(() => _amount = v),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _showKeypad
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
          if (_showKeypad) const Gap(8),

          // Category picker (compact chips)
          _SectionLabel(label: 'Category'),
          const Gap(6),
          CategoryPickerGrid(
            compact: true,
            selectedId: _categoryId,
            onSelected: (cat) {
              Haptics.selection();
              setState(() => _categoryId = cat.id);
            },
          ),
          const Gap(12),

          // Account selector
          _SectionLabel(label: 'Account'),
          const Gap(6),
          AccountSelector(
            selectedId: _accountId,
            onSelected: (a) => setState(() => _accountId = a.id),
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
              counterText: '',
            ),
            textInputAction: TextInputAction.done,
            maxLength: 50,
          ),
          const Gap(12),

          // Submit button
          FilledButton.icon(
            onPressed: _canSubmit ? _submit : null,
            icon: Icon(_isEditing ? Icons.save : Icons.check),
            label: Text(
              _isEditing
                  ? 'Save'
                  : 'Add ${_type == TransactionType.expense ? 'Expense' : 'Income'}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: typeColor,
            ),
          ),
          const Gap(8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
