import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/features/budgets/data/repositories/budget_repository.dart';

void main() {
  late AppDatabase db;
  late BudgetRepository repo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BudgetRepository(db);
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('BudgetRepository', () {
    test('upsert creates new budget', () async {
      final categories = await db.select(db.categories).get();
      final now = DateTime.now();

      await repo.upsert(
        categoryId: categories.first.id,
        amount: 300,
        year: now.year,
        month: now.month,
      );

      final budgets = await repo.getForMonth(now.year, now.month);
      expect(budgets.length, 1);
      expect(budgets.first.amount, 300);
    });

    test('upsert updates existing budget for same category/month', () async {
      final categories = await db.select(db.categories).get();
      final now = DateTime.now();

      await repo.upsert(
        categoryId: categories.first.id,
        amount: 300,
        year: now.year,
        month: now.month,
      );
      await repo.upsert(
        categoryId: categories.first.id,
        amount: 500,
        year: now.year,
        month: now.month,
      );

      final budgets = await repo.getForMonth(now.year, now.month);
      expect(budgets.length, 1);
      expect(budgets.first.amount, 500);
    });

    test('deleteById removes budget', () async {
      final categories = await db.select(db.categories).get();
      final now = DateTime.now();

      await repo.upsert(
        categoryId: categories.first.id,
        amount: 300,
        year: now.year,
        month: now.month,
      );

      final budgets = await repo.getForMonth(now.year, now.month);
      expect(budgets.length, 1);

      await repo.deleteById(budgets.first.id);

      final after = await repo.getForMonth(now.year, now.month);
      expect(after, isEmpty);
    });

    test('getForMonth filters by year and month', () async {
      final categories = await db.select(db.categories).get();
      final now = DateTime.now();

      await repo.upsert(
        categoryId: categories.first.id,
        amount: 300,
        year: now.year,
        month: now.month,
      );
      // Different month
      await repo.upsert(
        categoryId: categories.first.id,
        amount: 100,
        year: now.year,
        month: (now.month % 12) + 1,
      );

      final budgets = await repo.getForMonth(now.year, now.month);
      expect(budgets.length, 1);
      expect(budgets.first.amount, 300);
    });

    test('watchForMonth emits updates reactively', () async {
      final categories = await db.select(db.categories).get();
      final now = DateTime.now();

      final stream = repo.watchForMonth(now.year, now.month);

      // Should start empty
      expect(await stream.first, isEmpty);

      await repo.upsert(
        categoryId: categories.first.id,
        amount: 250,
        year: now.year,
        month: now.month,
      );

      final list = await stream.first;
      expect(list.length, 1);
      expect(list.first.amount, 250);
    });
  });
}
