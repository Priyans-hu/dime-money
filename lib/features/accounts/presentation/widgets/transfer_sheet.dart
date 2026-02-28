import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key});

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int? _fromAccountId;
  int? _toAccountId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || _fromAccountId == null || _toAccountId == null) return;
    if (_fromAccountId == _toAccountId) return;

    Haptics.medium();

    await ref.read(transactionRepositoryProvider).insert(
          type: TransactionType.transfer,
          amount: amount,
          accountId: _fromAccountId!,
          toAccountId: _toAccountId,
          note: _noteController.text.trim(),
          date: DateTime.now(),
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(allAccountsProvider);

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
          Text('Transfer',
              style: Theme.of(context).textTheme.titleLarge),
          const Gap(16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.attach_money),
            ),
            autofocus: true,
          ),
          const Gap(12),
          accountsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Error loading accounts'),
            data: (accounts) => Column(
              children: [
                _AccountDropdown(
                  label: 'From',
                  accounts: accounts,
                  selectedId: _fromAccountId,
                  onChanged: (id) => setState(() => _fromAccountId = id),
                ),
                const Gap(8),
                Icon(Icons.arrow_downward,
                    color: Theme.of(context).colorScheme.outline),
                const Gap(8),
                _AccountDropdown(
                  label: 'To',
                  accounts: accounts,
                  selectedId: _toAccountId,
                  onChanged: (id) => setState(() => _toAccountId = id),
                ),
              ],
            ),
          ),
          const Gap(12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Note (optional)',
              prefixIcon: Icon(Icons.note_outlined),
              isDense: true,
            ),
          ),
          const Gap(16),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Transfer'),
          ),
          const Gap(8),
        ],
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final String label;
  final List<Account> accounts;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const _AccountDropdown({
    required this.label,
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: selectedId,
      decoration: InputDecoration(labelText: label),
      items: accounts
          .map((a) => DropdownMenuItem(
                value: a.id,
                child: Row(
                  children: [
                    Icon(
                      IconData(a.iconCodePoint, fontFamily: 'MaterialIcons'),
                      size: 18,
                      color: Color(a.color),
                    ),
                    const Gap(8),
                    Text(a.name),
                  ],
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
