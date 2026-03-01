import 'package:dime_money/core/constants/enums.dart';

class ParsedSms {
  final String smsId;
  final String sender;
  final DateTime date;
  final double amount;
  final TransactionType type;
  final String? accountLast4;
  final String? merchant;
  final int? suggestedCategoryId;
  final int? selectedCategoryId;
  final int? selectedAccountId;
  final bool selected;

  const ParsedSms({
    required this.smsId,
    required this.sender,
    required this.date,
    required this.amount,
    required this.type,
    this.accountLast4,
    this.merchant,
    this.suggestedCategoryId,
    this.selectedCategoryId,
    this.selectedAccountId,
    this.selected = true,
  });

  /// Deterministic key for duplicate tracking.
  /// Uses raw composite key (no hashing) to avoid collisions.
  static String computeId(DateTime date, double amount, TransactionType type) {
    return '${date.millisecondsSinceEpoch}|${amount.toStringAsFixed(2)}|${type.name}';
  }

  /// Returns selectedCategoryId if set, otherwise suggestedCategoryId.
  /// Returns null if neither is set.
  int? get effectiveCategoryId => selectedCategoryId ?? suggestedCategoryId;

  ParsedSms copyWith({
    String? smsId,
    String? sender,
    DateTime? date,
    double? amount,
    TransactionType? type,
    String? accountLast4,
    String? merchant,
    int? suggestedCategoryId,
    int? selectedCategoryId,
    int? selectedAccountId,
    bool? selected,
  }) {
    return ParsedSms(
      smsId: smsId ?? this.smsId,
      sender: sender ?? this.sender,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      accountLast4: accountLast4 ?? this.accountLast4,
      merchant: merchant ?? this.merchant,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      selected: selected ?? this.selected,
    );
  }
}
