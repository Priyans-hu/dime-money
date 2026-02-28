import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

final accountBalancesProvider =
    FutureProvider<Map<int, double>>((ref) async {
  final accountRepo = ref.watch(accountRepositoryProvider);
  final accounts = await accountRepo.getAll();
  final balances = <int, double>{};
  for (final account in accounts) {
    balances[account.id] = await accountRepo.computeBalance(account.id);
  }
  return balances;
});
