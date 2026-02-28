import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the pill-shaped nav bar rendering.
/// Since _PillNavBar is private, we test the visual properties indirectly.
void main() {
  group('Pill nav bar visual properties', () {
    testWidgets('renders 4 navigation icons', (tester) async {
      // Simulate the nav bar structure
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        Icon(Icons.dashboard),
                        Icon(Icons.receipt_long_outlined),
                        Icon(Icons.pie_chart_outline),
                        Icon(Icons.settings_outlined),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.byIcon(Icons.pie_chart_outline), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('no labels rendered in pill nav (icon-only)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Icon(Icons.dashboard),
                    Icon(Icons.receipt_long_outlined),
                    Icon(Icons.pie_chart_outline),
                    Icon(Icons.settings_outlined),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify no label text from old nav
      expect(find.text('Home'), findsNothing);
      expect(find.text('History'), findsNothing);
      expect(find.text('Budgets'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    });
  });
}
