import 'package:flutter/material.dart';
import 'package:dime_money/core/theme/color_tokens.dart';

class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double limit;

  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

    Color barColor;
    if (pct < 0.75) {
      barColor = AppColors.budgetSafe;
    } else if (pct < 0.90) {
      barColor = AppColors.budgetWarning;
    } else {
      barColor = AppColors.budgetDanger;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 8,
        backgroundColor: barColor.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation(barColor),
      ),
    );
  }
}
