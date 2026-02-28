import 'package:drift/drift.dart';
import 'package:dime_money/core/database/converters.dart';


class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text().map(const AccountTypeConverter())();
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  IntColumn get color => integer()();
  IntColumn get iconCodePoint => integer()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
