import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dime_money/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:dime_money/features/transactions/presentation/screens/transaction_history_screen.dart';
import 'package:dime_money/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:dime_money/features/settings/presentation/screens/settings_screen.dart';
import 'package:dime_money/features/accounts/presentation/screens/manage_accounts_screen.dart';
import 'package:dime_money/features/categories/presentation/screens/manage_categories_screen.dart';
import 'package:dime_money/features/recurring/presentation/screens/recurring_screen.dart';
import 'package:dime_money/shared/widgets/app_bottom_nav.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppBottomNav(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionHistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/budgets',
              builder: (context, state) => const BudgetsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'accounts',
                  builder: (context, state) =>
                      const ManageAccountsScreen(),
                ),
                GoRoute(
                  path: 'categories',
                  builder: (context, state) =>
                      const ManageCategoriesScreen(),
                ),
                GoRoute(
                  path: 'recurring',
                  builder: (context, state) =>
                      const RecurringScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
