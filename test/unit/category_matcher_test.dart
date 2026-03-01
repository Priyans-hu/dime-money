import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/features/sms_import/data/services/category_matcher.dart';

void main() {
  late AppDatabase db;
  late List<Category> categories;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categories = await db.select(db.categories).get();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('CategoryMatcher', () {
    group('match', () {
      test('matches food merchants', () {
        final id = CategoryMatcher.match('Swiggy', categories);
        expect(id, isNotNull);
        final cat = categories.firstWhere((c) => c.id == id);
        expect(cat.name, 'Food & Drinks');
      });

      test('matches transport merchants', () {
        final id = CategoryMatcher.match('Uber', categories);
        expect(id, isNotNull);
        final cat = categories.firstWhere((c) => c.id == id);
        expect(cat.name, 'Transport');
      });

      test('matches shopping merchants', () {
        final id = CategoryMatcher.match('Amazon', categories);
        expect(id, isNotNull);
        final cat = categories.firstWhere((c) => c.id == id);
        expect(cat.name, 'Shopping');
      });

      test('matches bills merchants', () {
        final id = CategoryMatcher.match('Airtel', categories);
        expect(id, isNotNull);
        final cat = categories.firstWhere((c) => c.id == id);
        expect(cat.name, 'Bills & Utilities');
      });

      test('matches entertainment merchants', () {
        final id = CategoryMatcher.match('Netflix', categories);
        expect(id, isNotNull);
        final cat = categories.firstWhere((c) => c.id == id);
        expect(cat.name, 'Entertainment');
      });

      test('matches health merchants', () {
        final id = CategoryMatcher.match('Apollo Pharmacy', categories);
        expect(id, isNotNull);
        final cat = categories.firstWhere((c) => c.id == id);
        expect(cat.name, 'Health');
      });

      test('returns null for unknown merchant', () {
        expect(CategoryMatcher.match('RandomXYZ123', categories), isNull);
      });

      test('returns null for null merchant', () {
        expect(CategoryMatcher.match(null, categories), isNull);
      });

      test('returns null for empty merchant', () {
        expect(CategoryMatcher.match('', categories), isNull);
      });

      test('case insensitive matching', () {
        final id = CategoryMatcher.match('SWIGGY', categories);
        expect(id, isNotNull);
        final cat = categories.firstWhere((c) => c.id == id);
        expect(cat.name, 'Food & Drinks');
      });

      test('does not match partial words (word boundary)', () {
        // "ola" should not match "chocolate"
        expect(CategoryMatcher.match('chocolate', categories), isNull);
      });
    });

    group('otherCategoryId', () {
      test('returns Other category id', () {
        final id = CategoryMatcher.otherCategoryId(categories);
        expect(id, isNotNull);
        final cat = categories.firstWhere((c) => c.id == id);
        expect(cat.name, 'Other');
      });

      test('returns null for empty categories', () {
        expect(CategoryMatcher.otherCategoryId([]), isNull);
      });
    });
  });
}
