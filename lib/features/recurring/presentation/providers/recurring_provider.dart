import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/providers/database_provider.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/features/recurring/data/repositories/recurring_repository.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(databaseProvider));
});

final allRecurringRulesProvider = StreamProvider<List<RecurringRule>>((ref) {
  return ref.watch(recurringRepositoryProvider).watchAll();
});
