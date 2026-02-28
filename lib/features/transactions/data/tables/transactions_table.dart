import 'package:drift/drift.dart';
import 'package:dime_money/core/database/converters.dart';
import 'package:dime_money/features/categories/data/tables/categories_table.dart';
import 'package:dime_money/features/accounts/data/tables/accounts_table.dart';
import 'package:dime_money/features/recurring/data/tables/recurring_rules_table.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().map(const TransactionTypeConverter())();
  RealColumn get amount => real()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId =>
      integer().nullable().references(Accounts, #id)();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get date => dateTime()();
  IntColumn get recurringRuleId =>
      integer().nullable().references(RecurringRules, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
