import 'package:drift/drift.dart';
import 'package:dime_money/core/database/app_database.dart';

class BudgetRepository {
  final AppDatabase _db;

  BudgetRepository(this._db);

  Stream<List<Budget>> watchForMonth(int year, int month) {
    return (_db.select(_db.budgets)
          ..where(
              (b) => b.year.equals(year) & b.month.equals(month)))
        .watch();
  }

  Future<List<Budget>> getForMonth(int year, int month) {
    return (_db.select(_db.budgets)
          ..where(
              (b) => b.year.equals(year) & b.month.equals(month)))
        .get();
  }

  Future<void> upsert({
    required int categoryId,
    required double amount,
    required int year,
    required int month,
  }) async {
    // Check if exists
    final existing = await (_db.select(_db.budgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) &
              b.year.equals(year) &
              b.month.equals(month)))
        .getSingleOrNull();

    if (existing != null) {
      await _db
          .update(_db.budgets)
          .replace(existing.copyWith(amount: amount));
    } else {
      await _db.into(_db.budgets).insert(BudgetsCompanion.insert(
            categoryId: categoryId,
            amount: amount,
            year: year,
            month: month,
          ));
    }
  }

  Future<int> deleteById(int id) {
    return (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();
  }
}
