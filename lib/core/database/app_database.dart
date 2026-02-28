import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show Color, Icons;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/converters.dart';
import 'package:dime_money/core/constants/category_defaults.dart';
import 'package:dime_money/features/categories/data/tables/categories_table.dart';
import 'package:dime_money/features/accounts/data/tables/accounts_table.dart';
import 'package:dime_money/features/transactions/data/tables/transactions_table.dart';
import 'package:dime_money/features/budgets/data/tables/budgets_table.dart';
import 'package:dime_money/features/recurring/data/tables/recurring_rules_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Categories,
  Accounts,
  Transactions,
  Budgets,
  RecurringRules,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedDefaults();
      },
    );
  }

  Future<void> _seedDefaults() async {
    // Seed default categories
    for (var i = 0; i < defaultCategories.length; i++) {
      final cat = defaultCategories[i];
      await into(categories).insert(CategoriesCompanion.insert(
        name: cat.name,
        iconCodePoint: cat.icon.codePoint,
        iconFontFamily: Value(cat.icon.fontFamily ?? 'MaterialIcons'),
        color: cat.color.toARGB32(),
        isDefault: const Value(true),
        sortOrder: Value(i),
      ));
    }

    // Seed default Cash account
    await into(accounts).insert(AccountsCompanion.insert(
      name: 'Cash',
      type: AccountType.cash,
      color: const Color(0xFF66BB6A).toARGB32(),
      iconCodePoint: Icons.account_balance_wallet.codePoint,
    ));
  }

}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dime_money.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
