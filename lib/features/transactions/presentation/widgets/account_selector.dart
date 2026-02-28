import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

class AccountSelector extends ConsumerWidget {
  final int? selectedId;
  final ValueChanged<Account> onSelected;

  const AccountSelector({
    super.key,
    this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(allAccountsProvider);

    return accountsAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (accounts) => SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: accounts.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final account = accounts[index];
            final isSelected = account.id == selectedId;
            final acctColor = Color(account.color);

            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconData(account.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    size: 16,
                    color: isSelected ? acctColor : null,
                  ),
                  const SizedBox(width: 4),
                  Text(account.name),
                ],
              ),
              onSelected: (_) {
                Haptics.selection();
                onSelected(account);
              },
            );
          },
        ),
      ),
    );
  }
}
