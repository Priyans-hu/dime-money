import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:dime_money/features/dashboard/presentation/widgets/spending_donut.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/core/database/app_database.dart';

void main() {
  group('SpendingDonut empty state labels', () {
    Widget buildWithPeriod(DashboardPeriod period) {
      return ProviderScope(
        overrides: [
          dashboardPeriodProvider.overrideWith((_) {
            final notifier = DashboardPeriodNotifier();
            // ignore: invalid_use_of_protected_member
            notifier.state = period;
            return notifier;
          }),
          dashboardCategoryBreakdownProvider.overrideWith(
            (ref) async => <int, double>{},
          ),
          allCategoriesProvider.overrideWith(
            (ref) => Stream.value(<Category>[]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SpendingDonut()),
        ),
      );
    }

    testWidgets('shows "No expenses today" for daily period', (tester) async {
      await tester.pumpWidget(buildWithPeriod(DashboardPeriod.daily));
      await tester.pumpAndSettle();
      expect(find.text('No expenses today'), findsOneWidget);
    });

    testWidgets('shows "No expenses this week" for weekly period',
        (tester) async {
      await tester.pumpWidget(buildWithPeriod(DashboardPeriod.weekly));
      await tester.pumpAndSettle();
      expect(find.text('No expenses this week'), findsOneWidget);
    });

    testWidgets('shows "No expenses this month" for monthly period',
        (tester) async {
      await tester.pumpWidget(buildWithPeriod(DashboardPeriod.monthly));
      await tester.pumpAndSettle();
      expect(find.text('No expenses this month'), findsOneWidget);
    });
  });
}
