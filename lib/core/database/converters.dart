import 'package:drift/drift.dart';
import 'package:dime_money/core/constants/enums.dart';

class TransactionTypeConverter extends TypeConverter<TransactionType, String> {
  const TransactionTypeConverter();

  @override
  TransactionType fromSql(String fromDb) {
    return TransactionType.values.firstWhere((e) => e.name == fromDb);
  }

  @override
  String toSql(TransactionType value) => value.name;
}

class AccountTypeConverter extends TypeConverter<AccountType, String> {
  const AccountTypeConverter();

  @override
  AccountType fromSql(String fromDb) {
    return AccountType.values.firstWhere((e) => e.name == fromDb);
  }

  @override
  String toSql(AccountType value) => value.name;
}

class RecurrenceTypeConverter extends TypeConverter<RecurrenceType, String> {
  const RecurrenceTypeConverter();

  @override
  RecurrenceType fromSql(String fromDb) {
    return RecurrenceType.values.firstWhere((e) => e.name == fromDb);
  }

  @override
  String toSql(RecurrenceType value) => value.name;
}
