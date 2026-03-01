import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/core/utils/sheet_padding.dart';
import 'package:dime_money/core/theme/color_tokens.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:dime_money/features/accounts/presentation/widgets/account_card.dart';
import 'package:dime_money/features/accounts/presentation/widgets/transfer_sheet.dart';

class ManageAccountsScreen extends ConsumerWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(allAccountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transfer',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const TransferSheet(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: 72 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddAccount(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) => balancesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (balances) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return AccountCard(
                account: account,
                balance: balances[account.id] ?? 0,
                onLongPress: () => _showArchiveDialog(context, ref, account),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddAccount(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    var selectedType = AccountType.bank;
    var selectedColor = AppColors.categoryPalette[4];
    var selectedIcon = Icons.account_balance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: sheetBottomPadding(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New Account',
                  style: Theme.of(context).textTheme.titleLarge),
              const Gap(16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const Gap(12),
              TextField(
                controller: balanceController,
                decoration:
                    const InputDecoration(labelText: 'Initial Balance'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const Gap(12),
              SegmentedButton<AccountType>(
                segments: AccountType.values
                    .map((t) => ButtonSegment(
                          value: t,
                          label: Text(
                              t.name[0].toUpperCase() + t.name.substring(1)),
                        ))
                    .toList(),
                selected: {selectedType},
                onSelectionChanged: (s) =>
                    setSheetState(() => selectedType = s.first),
              ),
              const Gap(16),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Haptics.medium();
                  await ref.read(accountRepositoryProvider).insert(
                        name: name,
                        type: selectedType,
                        initialBalance:
                            double.tryParse(balanceController.text) ?? 0,
                        color: selectedColor.toARGB32(),
                        iconCodePoint: selectedIcon.codePoint,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Add Account'),
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  void _showArchiveDialog(
      BuildContext context, WidgetRef ref, Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive account?'),
        content: Text('Archive "${account.name}"? It won\'t appear in lists.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Haptics.medium();
              await ref.read(accountRepositoryProvider).archive(account.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}
