import 'package:drift/drift.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';

class RecurringRepository {
  final AppDatabase _db;

  RecurringRepository(this._db);

  Stream<List<RecurringRule>> watchAll() {
    return (_db.select(_db.recurringRules)
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .watch();
  }

  Future<List<RecurringRule>> getActive() {
    return (_db.select(_db.recurringRules)
          ..where((r) => r.isActive.equals(true)))
        .get();
  }

  Future<int> insert({
    required TransactionType type,
    required double amount,
    int? categoryId,
    required int accountId,
    String note = '',
    required RecurrenceType recurrence,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    return _db.into(_db.recurringRules).insert(RecurringRulesCompanion.insert(
          type: type,
          amount: amount,
          categoryId: Value(categoryId),
          accountId: accountId,
          note: Value(note),
          recurrence: recurrence,
          startDate: startDate,
          endDate: Value(endDate),
        ));
  }

  Future<void> update(RecurringRule rule) {
    return _db.update(_db.recurringRules).replace(rule);
  }

  Future<int> deleteById(int id) {
    return (_db.delete(_db.recurringRules)..where((r) => r.id.equals(id))).go();
  }

  /// Process all active rules: generate transactions since lastProcessed
  Future<int> processRules() async {
    final rules = await getActive();
    int generated = 0;
    final now = DateTime.now();

    for (final rule in rules) {
      // Skip if end date passed
      if (rule.endDate != null && rule.endDate!.isBefore(now)) continue;

      DateTime nextDue = rule.lastProcessed ?? rule.startDate;

      while (true) {
        nextDue = _nextOccurrence(nextDue, rule.recurrence);
        if (nextDue.isAfter(now)) break;

        await _db.into(_db.transactions).insert(
              TransactionsCompanion.insert(
                type: rule.type,
                amount: rule.amount,
                categoryId: Value(rule.categoryId),
                accountId: rule.accountId,
                note: Value(rule.note),
                date: nextDue,
                recurringRuleId: Value(rule.id),
              ),
            );
        generated++;
      }

      // Update lastProcessed
      await _db.update(_db.recurringRules).replace(
            rule.copyWith(lastProcessed: Value(now)),
          );
    }

    return generated;
  }

  DateTime _nextOccurrence(DateTime from, RecurrenceType recurrence) {
    switch (recurrence) {
      case RecurrenceType.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceType.biweekly:
        return from.add(const Duration(days: 14));
      case RecurrenceType.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurrenceType.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}
