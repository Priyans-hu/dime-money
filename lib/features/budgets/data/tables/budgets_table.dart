import 'package:drift/drift.dart';
import 'package:dime_money/features/categories/data/tables/categories_table.dart';

@DataClassName('Budget')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get amount => real()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId, year, month},
      ];
}
