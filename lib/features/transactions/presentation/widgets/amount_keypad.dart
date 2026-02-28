import 'package:flutter/material.dart';
import 'package:dime_money/core/utils/haptics.dart';

class AmountKeypad extends StatelessWidget {
  final String currentAmount;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback? onDone;

  const AmountKeypad({
    super.key,
    required this.currentAmount,
    required this.onAmountChanged,
    this.onDone,
  });

  void _onKey(String key) {
    Haptics.light();
    String amount = currentAmount;

    if (key == 'backspace') {
      if (amount.isNotEmpty) {
        amount = amount.substring(0, amount.length - 1);
      }
    } else if (key == '.') {
      if (!amount.contains('.')) {
        amount = amount.isEmpty ? '0.' : '$amount.';
      }
    } else {
      // Limit decimal places to 2
      if (amount.contains('.')) {
        final parts = amount.split('.');
        if (parts[1].length >= 2) return;
      }
      // Prevent leading zeros (except "0.")
      if (amount == '0' && key != '.') {
        amount = key;
      } else {
        amount += key;
      }
    }

    onAmountChanged(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _keys)
          Row(
            children: row.map((key) {
              if (key == 'done') {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FilledButton(
                      onPressed: onDone,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.check, size: 28),
                    ),
                  ),
                );
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: TextButton(
                    onPressed: () => _onKey(key),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor:
                          colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                    ),
                    child: key == 'backspace'
                        ? Icon(Icons.backspace_outlined,
                            color: colorScheme.onSurface)
                        : Text(
                            key,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: colorScheme.onSurface),
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', 'backspace'],
  ];
}
