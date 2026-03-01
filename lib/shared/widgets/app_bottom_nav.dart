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
      floatingActionButton: currentIndex == 3 ? null : Padding(
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
      bottomNavigationBar: _LiquidGlassNavBar(
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

class _LiquidGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final double safeBottom;
  final ColorScheme colorScheme;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _LiquidGlassNavBar({
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
        left: 16,
        right: 16,
        bottom: safeBottom + 12,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.25),
                  width: 0.5,
                ),
              ),
              child: Stack(
                children: [
                  // Sliding active pill indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _pillLeft(context),
                    top: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          width: 56,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Icons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_items.length, (index) {
                      final isSelected = index == currentIndex;
                      final item = _items[index];

                      return GestureDetector(
                        onTap: () => onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 56,
                          height: 64,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                key: ValueKey('${index}_$isSelected'),
                                color: isSelected
                                    ? colorScheme.primary
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.45)),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _pillLeft(BuildContext context) {
    final barWidth = MediaQuery.of(context).size.width - 32; // 16 padding each side
    final slotWidth = barWidth / _items.length;
    return slotWidth * currentIndex + (slotWidth - 56) / 2;
  }
}
