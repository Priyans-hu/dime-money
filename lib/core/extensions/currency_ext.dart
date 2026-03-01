import 'package:intl/intl.dart';

extension CurrencyExt on double {
  String formatCurrency({String symbol = '\$'}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(this);
  }

  String formatNumber() {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(this);
  }

  String formatCompact({String symbol = '\$'}) {
    if (abs() >= 1000000) {
      return '$symbol${(this / 1000000).toStringAsFixed(1)}M';
    }
    if (abs() >= 1000) {
      return '$symbol${(this / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(symbol: symbol);
  }
}
