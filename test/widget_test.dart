import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/app.dart';

void main() {
  testWidgets('App launches and shows bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DimeMoneyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
