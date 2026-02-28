import 'package:drift/drift.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';

class TransactionRepository {
  final AppDatabase _db;

  TransactionRepository(this._db);

  Stream<List<Transaction>> watchAll() {
    return (_db.select(_db.transactions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Stream<List<Transaction>> watchRange(DateTime start, DateTime end) {
    return (_db.select(_db.transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Stream<List<Transaction>> watchRecent(int limit) {
    return (_db.select(_db.transactions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ])
          ..limit(limit))
        .watch();
  }

  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) {
    return (_db.select(_db.transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<int> insert({
    required TransactionType type,
    required double amount,
    int? categoryId,
    required int accountId,
    int? toAccountId,
    String note = '',
    required DateTime date,
    int? recurringRuleId,
  }) {
    return _db.into(_db.transactions).insert(TransactionsCompanion.insert(
          type: type,
          amount: amount,
          categoryId: Value(categoryId),
          accountId: accountId,
          toAccountId: Value(toAccountId),
          note: Value(note),
          date: date,
          recurringRuleId: Value(recurringRuleId),
        ));
  }

  Future<void> update(Transaction txn) {
    return _db.update(_db.transactions).replace(txn);
  }

  Future<int> deleteById(int id) {
    return (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  // Aggregation: sum expenses by category for a month
  Future<Map<int, double>> expensesByCategoryForMonth(
      int year, int month) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);

    final query = _db.select(_db.transactions)
      ..where((t) =>
          t.type.equals(TransactionType.expense.name) &
          t.date.isBetweenValues(start, end) &
          t.categoryId.isNotNull());

    final rows = await query.get();
    final map = <int, double>{};
    for (final row in rows) {
      map[row.categoryId!] = (map[row.categoryId!] ?? 0) + row.amount;
    }
    return map;
  }

  // Total income/expense for a date range
  Future<({double income, double expense})> totalsForRange(
      DateTime start, DateTime end) async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.date.isBetweenValues(start, end)))
        .get();

    double income = 0, expense = 0;
    for (final row in rows) {
      if (row.type == TransactionType.income) {
        income += row.amount;
      } else if (row.type == TransactionType.expense) {
        expense += row.amount;
      }
    }
    return (income: income, expense: expense);
  }

  // Search by note or category name
  Stream<List<Transaction>> search(String query) {
    final pattern = '%$query%';
    return (_db.select(_db.transactions)
          ..where((t) => t.note.like(pattern))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }
}
