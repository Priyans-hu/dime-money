import 'package:drift/drift.dart';
import 'package:dime_money/core/database/app_database.dart';

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  Stream<List<Category>> watchAll() {
    return (_db.select(_db.categories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  Future<List<Category>> getAll() {
    return (_db.select(_db.categories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  Future<Category?> getById(int id) {
    return (_db.select(_db.categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insert({
    required String name,
    required int iconCodePoint,
    String iconFontFamily = 'MaterialIcons',
    required int color,
    int sortOrder = 0,
  }) {
    return _db.into(_db.categories).insert(CategoriesCompanion.insert(
          name: name,
          iconCodePoint: iconCodePoint,
          iconFontFamily: Value(iconFontFamily),
          color: color,
          sortOrder: Value(sortOrder),
        ));
  }

  Future<void> update(Category category) {
    return _db.update(_db.categories).replace(category);
  }

  Future<int> deleteById(int id) {
    return (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }
}
