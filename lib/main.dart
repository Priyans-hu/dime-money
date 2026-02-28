import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/app.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/providers/database_provider.dart';
import 'package:dime_money/features/recurring/data/repositories/recurring_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create DB and process recurring rules on app start
  final db = AppDatabase();
  final recurringRepo = RecurringRepository(db);
  await recurringRepo.processRules();

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
    ],
    child: const DimeMoneyApp(),
  ));
}
