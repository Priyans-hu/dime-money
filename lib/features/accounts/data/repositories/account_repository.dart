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

    final result = await _db.customSelect(
      'SELECT '
      "COALESCE(SUM(CASE WHEN type = 'income' AND account_id = ?1 THEN amount ELSE 0 END), 0) AS income, "
      "COALESCE(SUM(CASE WHEN type = 'expense' AND account_id = ?1 THEN amount ELSE 0 END), 0) AS expense, "
      "COALESCE(SUM(CASE WHEN type = 'transfer' AND to_account_id = ?1 THEN amount ELSE 0 END), 0) AS tin, "
      "COALESCE(SUM(CASE WHEN type = 'transfer' AND account_id = ?1 THEN amount ELSE 0 END), 0) AS tout "
      'FROM transactions WHERE account_id = ?1 OR to_account_id = ?1',
      variables: [Variable.withInt(accountId)],
    ).getSingle();

    return account.initialBalance +
        result.read<double>('income') -
        result.read<double>('expense') +
        result.read<double>('tin') -
        result.read<double>('tout');
  }

  /// Compute total balance across all non-archived accounts in a single query.
  Future<double> computeTotalBalance() async {
    // Sum initial balances
    final initResult = await _db.customSelect(
      'SELECT COALESCE(SUM(initial_balance), 0) AS total '
      'FROM accounts WHERE is_archived = 0',
    ).getSingle();
    final initTotal = initResult.read<double>('total');

    // Get IDs of non-archived accounts for transaction filtering
    final accounts = await getAll();
    if (accounts.isEmpty) return initTotal;

    final ids = accounts.map((a) => a.id).toList();
    final placeholders = ids.map((_) => '?').join(',');
    final vars = ids.map((id) => Variable.withInt(id)).toList();

    // Sum income, expense, transfer-in, transfer-out for all active accounts
    final result = await _db.customSelect(
      'SELECT '
      "COALESCE(SUM(CASE WHEN type = 'income' AND account_id IN ($placeholders) THEN amount ELSE 0 END), 0) AS income, "
      "COALESCE(SUM(CASE WHEN type = 'expense' AND account_id IN ($placeholders) THEN amount ELSE 0 END), 0) AS expense, "
      "COALESCE(SUM(CASE WHEN type = 'transfer' AND to_account_id IN ($placeholders) AND account_id NOT IN ($placeholders) THEN amount ELSE 0 END), 0) AS tin, "
      "COALESCE(SUM(CASE WHEN type = 'transfer' AND account_id IN ($placeholders) AND to_account_id NOT IN ($placeholders) THEN amount ELSE 0 END), 0) AS tout "
      'FROM transactions',
      variables: [...vars, ...vars, ...vars, ...vars, ...vars, ...vars],
    ).getSingle();

    return initTotal +
        result.read<double>('income') -
        result.read<double>('expense') +
        result.read<double>('tin') -
        result.read<double>('tout');
  }
}
