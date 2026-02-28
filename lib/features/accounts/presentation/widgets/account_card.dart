import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/extensions/currency_ext.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final double balance;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AccountCard({
    super.key,
    required this.account,
    required this.balance,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final acctColor = Color(account.color);

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: acctColor.withValues(alpha: 0.15),
                child: Icon(
                  IconData(account.iconCodePoint,
                      fontFamily: 'MaterialIcons'),
                  color: acctColor,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      account.type.name[0].toUpperCase() +
                          account.type.name.substring(1),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                balance.formatCurrency(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
