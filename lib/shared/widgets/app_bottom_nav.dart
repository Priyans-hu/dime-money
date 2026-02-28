import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dime_money/core/utils/haptics.dart';

class AppBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppBottomNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          Haptics.selection();
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Haptics.medium();
          _showQuickAdd(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SizedBox(
        height: 400,
        child: Center(child: Text('Quick Add - Coming Soon')),
      ),
    );
  }
}
