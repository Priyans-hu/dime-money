import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String amount(double value, {String symbol = '\$'}) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(value);
  }

  static String date(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  static String percentage(double value) {
    return '${value.toStringAsFixed(0)}%';
  }
}
