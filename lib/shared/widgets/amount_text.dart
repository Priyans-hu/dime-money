import 'package:flutter/material.dart';
import 'package:dime_money/core/extensions/currency_ext.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final String currencySymbol;
  final TextStyle? style;
  final bool colored;
  final bool compact;

  const AmountText({
    super.key,
    required this.amount,
    this.currencySymbol = '\$',
    this.style,
    this.colored = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = compact
        ? amount.formatCompact(symbol: currencySymbol)
        : amount.formatCurrency(symbol: currencySymbol);

    Color? color;
    if (colored) {
      color = amount >= 0 ? Colors.green : Colors.red;
    }

    return Text(
      text,
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color,
      ),
    );
  }
}
