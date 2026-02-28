import 'package:drift/drift.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';

class AccountRepository {
  final AppDatabase _db;

  AccountRepository(this._db);

  Stream<List<Account>> watchAll() {
    return (_db.select(_db.accounts)
          ..where((a) => a.isArchived.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .watch();
  }

  Future<List<Account>> getAll() {
    return (_db.select(_db.accounts)
          ..where((a) => a.isArchived.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .get();
  }

  Future<Account?> getById(int id) {
    return (_db.select(_db.accounts)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insert({
    required String name,
    required AccountType type,
    double initialBalance = 0,
    required int color,
    required int iconCodePoint,
  }) {
    return _db.into(_db.accounts).insert(AccountsCompanion.insert(
          name: name,
          type: type,
          initialBalance: Value(initialBalance),
          color: color,
          iconCodePoint: iconCodePoint,
        ));
  }

  Future<void> update(Account account) {
    return _db.update(_db.accounts).replace(account);
  }

  Future<void> archive(int id) async {
    final account = await getById(id);
    if (account != null) {
      await _db.update(_db.accounts).replace(
            account.copyWith(isArchived: true),
          );
    }
  }

  /// Compute balance: initialBalance + income - expense + transfersIn - transfersOut
  Future<double> computeBalance(int accountId) async {
    final account = await getById(accountId);
    if (account == null) return 0;

    double balance = account.initialBalance;

    // Income
    final incomeRows = await (_db.select(_db.transactions)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.type.equals(TransactionType.income.name)))
        .get();
    for (final r in incomeRows) {
      balance += r.amount;
    }

    // Expense
    final expenseRows = await (_db.select(_db.transactions)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.type.equals(TransactionType.expense.name)))
        .get();
    for (final r in expenseRows) {
      balance -= r.amount;
    }

    // Transfers in
    final transfersIn = await (_db.select(_db.transactions)
          ..where((t) =>
              t.toAccountId.equals(accountId) &
              t.type.equals(TransactionType.transfer.name)))
        .get();
    for (final r in transfersIn) {
      balance += r.amount;
    }

    // Transfers out
    final transfersOut = await (_db.select(_db.transactions)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.type.equals(TransactionType.transfer.name)))
        .get();
    for (final r in transfersOut) {
      balance -= r.amount;
    }

    return balance;
  }
}
