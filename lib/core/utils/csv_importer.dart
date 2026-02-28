import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:drift/drift.dart';

class CsvImporter {
  final AppDatabase _db;

  CsvImporter(this._db);

  /// Import transactions from CSV file.
  /// Expected columns: Date, Type, Amount, Category, Account, To Account, Note
  /// Returns number of imported transactions.
  Future<int> importFromFile(File file) async {
    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return 0;

    // Skip header row
    final dataRows = rows.skip(1).toList();
    if (dataRows.isEmpty) return 0;

    // Get or create categories/accounts mapping
    final existingCategories = await _db.select(_db.categories).get();
    final existingAccounts = await _db.select(_db.accounts).get();

    final catMap = {for (final c in existingCategories) c.name: c.id};
    final acctMap = {for (final a in existingAccounts) a.name: a.id};

    int imported = 0;

    for (final row in dataRows) {
      if (row.length < 3) continue;

      final dateStr = row[0].toString();
      final typeStr = row[1].toString().toLowerCase();
      final amountStr = row[2].toString();

      final date = DateTime.tryParse(dateStr);
      final amount = double.tryParse(amountStr);
      if (date == null || amount == null || amount <= 0) continue;

      final type = TransactionType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => TransactionType.expense,
      );

      // Category
      int? categoryId;
      if (row.length > 3 && row[3].toString().isNotEmpty) {
        final catName = row[3].toString();
        categoryId = catMap[catName];
        if (categoryId == null) {
          // Create missing category
          categoryId = await _db
              .into(_db.categories)
              .insert(CategoriesCompanion.insert(
                name: catName,
                iconCodePoint: 0xe5d3, // Icons.more_horiz
                color: 0xFF78909C,
              ));
          catMap[catName] = categoryId;
        }
      }

      // Account
      int accountId;
      if (row.length > 4 && row[4].toString().isNotEmpty) {
        final acctName = row[4].toString();
        accountId = acctMap[acctName] ?? 1; // Default to first account
        if (!acctMap.containsKey(acctName)) {
          accountId = await _db
              .into(_db.accounts)
              .insert(AccountsCompanion.insert(
                name: acctName,
                type: AccountType.bank,
                color: 0xFF42A5F5,
                iconCodePoint: 0xe84f, // Icons.account_balance
              ));
          acctMap[acctName] = accountId;
        }
      } else {
        accountId = acctMap.values.firstOrNull ?? 1;
      }

      // To Account (for transfers)
      int? toAccountId;
      if (row.length > 5 && row[5].toString().isNotEmpty) {
        final toName = row[5].toString();
        toAccountId = acctMap[toName];
      }

      final note = row.length > 6 ? row[6].toString() : '';

      await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              type: type,
              amount: amount,
              categoryId: Value(categoryId),
              accountId: accountId,
              toAccountId: Value(toAccountId),
              note: Value(note),
              date: date,
            ),
          );
      imported++;
    }

    return imported;
  }
}
