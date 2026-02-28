import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dime_money/core/database/app_database.dart';

class CsvExporter {
  final AppDatabase _db;

  CsvExporter(this._db);

  Future<void> exportAndShare() async {
    final transactions = await (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    final categories = await _db.select(_db.categories).get();
    final accounts = await _db.select(_db.accounts).get();

    final catMap = {for (final c in categories) c.id: c.name};
    final acctMap = {for (final a in accounts) a.id: a.name};

    final rows = <List<String>>[
      ['Date', 'Type', 'Amount', 'Category', 'Account', 'To Account', 'Note'],
      ...transactions.map((t) => [
            t.date.toIso8601String(),
            t.type.name,
            t.amount.toStringAsFixed(2),
            t.categoryId != null ? (catMap[t.categoryId] ?? '') : '',
            acctMap[t.accountId] ?? '',
            t.toAccountId != null ? (acctMap[t.toAccountId] ?? '') : '',
            t.note,
          ]),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/dime_money_export.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Dime Money Export',
    );
  }
}
