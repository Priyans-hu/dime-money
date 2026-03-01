import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/features/sms_import/data/models/parsed_sms.dart';
import 'package:dime_money/features/sms_import/data/services/sms_reader_service.dart';
import 'package:dime_money/features/sms_import/data/services/notification_reader_service.dart';
import 'package:dime_money/features/sms_import/data/services/sms_parser_service.dart';
import 'package:dime_money/features/sms_import/data/services/category_matcher.dart';
import 'package:dime_money/features/sms_import/data/services/duplicate_tracker.dart';
import 'package:dime_money/features/transactions/data/repositories/transaction_repository.dart';
import 'package:dime_money/features/categories/data/repositories/category_repository.dart';
import 'package:dime_money/features/accounts/data/repositories/account_repository.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

enum SmsImportStatus {
  idle,
  requestingPermission,
  scanning,
  parsing,
  ready,
  importing,
  done,
  permissionDenied,
  notificationFallback,
  error,
}

enum ImportSource { sms, notification }

class SmsImportState {
  final SmsImportStatus status;
  final List<ParsedSms> transactions;
  final String? errorMessage;
  final int importedCount;
  final ImportSource? source;

  const SmsImportState({
    this.status = SmsImportStatus.idle,
    this.transactions = const [],
    this.errorMessage,
    this.importedCount = 0,
    this.source,
  });

  SmsImportState copyWith({
    SmsImportStatus? status,
    List<ParsedSms>? transactions,
    String? errorMessage,
    int? importedCount,
    ImportSource? source,
  }) {
    return SmsImportState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage ?? this.errorMessage,
      importedCount: importedCount ?? this.importedCount,
      source: source ?? this.source,
    );
  }

  int get selectedCount => transactions.where((t) => t.selected).length;
}

class SmsImportNotifier extends StateNotifier<SmsImportState> {
  final TransactionRepository _txnRepo;
  final CategoryRepository _catRepo;
  final AccountRepository _acctRepo;
  final _smsReader = SmsReaderService();
  final _notifReader = NotificationReaderService();
  final _parser = SmsParserService();
  final _duplicateTracker = DuplicateTracker();

  SmsImportNotifier(this._txnRepo, this._catRepo, this._acctRepo)
      : super(const SmsImportState());

  /// Start scanning SMS inbox.
  Future<void> startScan() async {
    if (!Platform.isAndroid) {
      _setIfMounted(state.copyWith(
        status: SmsImportStatus.error,
        errorMessage: 'SMS import is only available on Android',
      ));
      return;
    }

    _setIfMounted(state.copyWith(status: SmsImportStatus.requestingPermission));
    final permResult = await _smsReader.requestPermission();

    if (permResult == SmsPermissionResult.denied ||
        permResult == SmsPermissionResult.permanentlyDenied) {
      _setIfMounted(state.copyWith(status: SmsImportStatus.permissionDenied));
      return;
    }

    if (permResult == SmsPermissionResult.notAndroid) {
      _setIfMounted(state.copyWith(
        status: SmsImportStatus.error,
        errorMessage: 'SMS import is only available on Android',
      ));
      return;
    }

    await _scanMessages(ImportSource.sms);
  }

  /// Fallback: scan via notification listener.
  Future<void> startNotificationScan() async {
    _setIfMounted(state.copyWith(status: SmsImportStatus.notificationFallback));

    final hasAccess = await _notifReader.hasPermission();
    if (!hasAccess) {
      await _notifReader.requestPermission();
      // User returns from system settings — recheck
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final granted = await _notifReader.hasPermission();
      if (!granted) {
        _setIfMounted(state.copyWith(
          status: SmsImportStatus.error,
          errorMessage: 'Notification access not granted. Enable it in Settings > Apps > Notification access.',
          source: ImportSource.notification,
        ));
        return;
      }
    }

    await _scanMessages(ImportSource.notification);
  }

  Future<void> _scanMessages(ImportSource source) async {
    _setIfMounted(state.copyWith(status: SmsImportStatus.scanning, source: source));

    final messages = source == ImportSource.sms
        ? await _smsReader.readFinancialSms()
        : await _notifReader.readFinancialNotifications();

    if (!mounted) return;

    if (messages.isEmpty) {
      _setIfMounted(state.copyWith(
        status: SmsImportStatus.ready,
        transactions: [],
        source: source,
      ));
      return;
    }

    _setIfMounted(state.copyWith(status: SmsImportStatus.parsing));
    var parsed = _parser.parseAll(messages);
    if (!mounted) return;

    parsed = await _duplicateTracker.filterNew(parsed);
    if (!mounted) return;

    final categories = await _catRepo.getAll();
    final accounts = await _acctRepo.getAll();
    if (!mounted) return;

    final defaultAccountId = accounts.isNotEmpty ? accounts.first.id : null;
    final otherCatId = CategoryMatcher.otherCategoryId(categories);

    final enriched = parsed.map((sms) {
      final matchedId = CategoryMatcher.match(sms.merchant, categories);
      return sms.copyWith(
        suggestedCategoryId: matchedId ?? otherCatId,
        selectedCategoryId: matchedId ?? otherCatId,
        selectedAccountId: defaultAccountId,
      );
    }).toList();

    enriched.sort((a, b) => b.date.compareTo(a.date));

    _setIfMounted(state.copyWith(
      status: SmsImportStatus.ready,
      transactions: enriched,
      source: source,
    ));
  }

  /// Import selected transactions into the database.
  Future<void> importSelected() async {
    final selected = state.transactions.where((t) => t.selected).toList();
    if (selected.isEmpty) return;

    // Verify at least one account exists
    final accounts = await _acctRepo.getAll();
    if (!mounted) return;
    if (accounts.isEmpty) {
      _setIfMounted(state.copyWith(
        status: SmsImportStatus.error,
        errorMessage: 'No accounts found. Create an account first.',
      ));
      return;
    }
    final fallbackAccountId = accounts.first.id;

    _setIfMounted(state.copyWith(status: SmsImportStatus.importing));

    int count = 0;
    final importedIds = <String>[];

    for (final sms in selected) {
      if (!mounted) return;
      await _txnRepo.insert(
        type: sms.type,
        amount: sms.amount,
        categoryId: sms.effectiveCategoryId,
        accountId: sms.selectedAccountId ?? fallbackAccountId,
        note: sms.merchant ?? '',
        date: sms.date,
      );
      importedIds.add(sms.smsId);
      count++;
    }

    await _duplicateTracker.markImported(importedIds);

    _setIfMounted(state.copyWith(
      status: SmsImportStatus.done,
      importedCount: count,
    ));
  }

  void toggleItem(int index) {
    final txns = List<ParsedSms>.from(state.transactions);
    txns[index] = txns[index].copyWith(selected: !txns[index].selected);
    state = state.copyWith(transactions: txns);
  }

  void toggleAll(bool selected) {
    final txns = state.transactions.map((t) => t.copyWith(selected: selected)).toList();
    state = state.copyWith(transactions: txns);
  }

  void updateCategory(int index, int categoryId) {
    final txns = List<ParsedSms>.from(state.transactions);
    txns[index] = txns[index].copyWith(selectedCategoryId: categoryId);
    state = state.copyWith(transactions: txns);
  }

  void updateAccount(int index, int accountId) {
    final txns = List<ParsedSms>.from(state.transactions);
    txns[index] = txns[index].copyWith(selectedAccountId: accountId);
    state = state.copyWith(transactions: txns);
  }

  void reset() {
    state = const SmsImportState();
  }

  /// Safe state setter — only sets if notifier is still mounted.
  void _setIfMounted(SmsImportState newState) {
    if (mounted) state = newState;
  }
}

final smsImportProvider =
    StateNotifierProvider<SmsImportNotifier, SmsImportState>((ref) {
  return SmsImportNotifier(
    ref.watch(transactionRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
    ref.watch(accountRepositoryProvider),
  );
});
