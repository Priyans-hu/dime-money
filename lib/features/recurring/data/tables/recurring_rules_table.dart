import 'package:drift/drift.dart';
import 'package:dime_money/core/database/converters.dart';
import 'package:dime_money/features/categories/data/tables/categories_table.dart';
import 'package:dime_money/features/accounts/data/tables/accounts_table.dart';

class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().map(const TransactionTypeConverter())();
  RealColumn get amount => real()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get recurrence => text().map(const RecurrenceTypeConverter())();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get lastProcessed => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
