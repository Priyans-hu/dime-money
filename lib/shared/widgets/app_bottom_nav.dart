import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/transactions/presentation/widgets/quick_add_sheet.dart';
import 'package:dime_money/features/budgets/presentation/widgets/add_budget_sheet.dart';

class AppBottomNav extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppBottomNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 72 + safeBottom),
        child: FloatingActionButton(
          onPressed: () {
            Haptics.medium();
            if (currentIndex == 2) {
              showAddBudgetSheet(context, ref);
            } else {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const QuickAddSheet(),
              );
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _PillNavBar(
        currentIndex: currentIndex,
        safeBottom: safeBottom,
        colorScheme: colorScheme,
        isDark: isDark,
        onTap: (index) {
          Haptics.selection();
          navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          );
        },
      ),
    );
  }
}

class _PillNavBar extends StatelessWidget {
  final int currentIndex;
  final double safeBottom;
  final ColorScheme colorScheme;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _PillNavBar({
    required this.currentIndex,
    required this.safeBottom,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
    (icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long),
    (icon: Icons.pie_chart_outline, activeIcon: Icons.pie_chart),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: safeBottom + 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : colorScheme.surface)
                  .withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_items.length, (index) {
                final isSelected = index == currentIndex;
                final item = _items[index];

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
