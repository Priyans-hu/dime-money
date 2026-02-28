import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/providers/database_provider.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/features/transactions/data/repositories/transaction_repository.dart';
import 'package:dime_money/features/categories/data/repositories/category_repository.dart';
import 'package:dime_money/features/accounts/data/repositories/account_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(databaseProvider));
});

final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

final recentTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchRecent(5);
});

final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final allAccountsProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAll();
});

final mostFrequentCategoryProvider = FutureProvider<int?>((ref) {
  return ref.watch(transactionRepositoryProvider).mostFrequentCategoryId();
});

final searchTransactionsProvider =
    StreamProvider.family<List<Transaction>, String>((ref, query) {
  return ref.watch(transactionRepositoryProvider).search(query);
});
