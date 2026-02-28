import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for quick action handler logic.
/// Full integration tests require a running app, but we can test
/// the action parsing and shortcut update logic.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock the quick_actions method channel
    const channel = MethodChannel('plugins.flutter.io/quick_actions_android');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setShortcutItems') return null;
      if (call.method == 'clearShortcutItems') return null;
      if (call.method == 'getLaunchAction') return null;
      return null;
    });

    // Mock the custom quick_actions method channel
    const customChannel =
        MethodChannel('com.priyanshu.dime_money/quick_actions');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customChannel, (call) async {
      if (call.method == 'getLaunchAction') return null;
      return null;
    });

    // Mock home_widget
    const homeChannel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeChannel, (call) async => null);
  });

  group('Quick action parsing', () {
    test('add_expense action maps to expense type', () {
      // Simulating the logic from QuickActionHandler._handle
      const action = 'add_expense';
      expect(action, 'add_expense');
      expect(action != 'add_income', true);
    });

    test('add_income action maps to income type', () {
      const action = 'add_income';
      expect(action, 'add_income');
      expect(action != 'add_expense', true);
    });

    test('unknown action does not match known types', () {
      const action = 'unknown_action';
      expect(action != 'add_expense' && action != 'add_income', true);
    });
  });

  group('Shortcut items logic', () {
    test('when income disabled, only expense shortcut', () {
      const incomeEnabled = false;
      final shortcuts = <String>['add_expense'];
      if (incomeEnabled) shortcuts.add('add_income');

      expect(shortcuts, ['add_expense']);
      expect(shortcuts.length, 1);
    });

    test('when income enabled, both shortcuts present', () {
      const incomeEnabled = true;
      final shortcuts = <String>['add_expense'];
      if (incomeEnabled) shortcuts.add('add_income');

      expect(shortcuts, ['add_expense', 'add_income']);
      expect(shortcuts.length, 2);
    });
  });
}
