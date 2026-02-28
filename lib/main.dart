import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/app.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/providers/database_provider.dart';
import 'package:dime_money/features/recurring/data/repositories/recurring_repository.dart';
import 'package:home_widget/home_widget.dart';
import 'package:dime_money/core/utils/widget_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set iOS App Group for widget data sharing
  await HomeWidget.setAppGroupId('group.com.priyanshu.dimeMoney');

  // Create DB and process recurring rules on app start
  final db = AppDatabase();
  final recurringRepo = RecurringRepository(db);
  await recurringRepo.processRules();

  // Update home screen widget data
  await updateWidgetData(db);

  // Check auto-update preference
  final prefs = await SharedPreferences.getInstance();
  final autoCheck = prefs.getBool('auto_check_update') ?? true;

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
    ],
    child: DimeMoneyApp(checkForUpdate: autoCheck),
  ));
}
