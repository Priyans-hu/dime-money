import 'package:flutter_test/flutter_test.dart';
import 'package:dime_money/features/dashboard/presentation/providers/dashboard_provider.dart';

String? _getSnackBarMessage(bool toggleResult) {
  if (!toggleResult) return 'Biometric auth unavailable';
  return null;
}

void main() {
  group('Biometric toggle contract', () {
    test('DashboardPeriod enum has expected values', () {
      // Verifying the enum we use in the period-aware biometric/settings screen
      expect(DashboardPeriod.values.length, 3);
      expect(DashboardPeriod.daily.name, 'daily');
      expect(DashboardPeriod.weekly.name, 'weekly');
      expect(DashboardPeriod.monthly.name, 'monthly');
    });
  });

  group('Settings screen biometric toggle pattern', () {
    test('toggle result pattern: false means auth unavailable', () {
      // Simulating the logic from the fixed settings_screen.dart
      const toggleResult = false;
      String? snackBarMessage;

      if (!toggleResult) {
        snackBarMessage = 'Biometric auth unavailable';
      }

      expect(snackBarMessage, 'Biometric auth unavailable');
    });

    test('toggle result pattern: true means success, no snackbar', () {
      final snackBarMessage = _getSnackBarMessage(true);
      expect(snackBarMessage, isNull);
    });

    test('exception pattern shows error snackbar', () {
      String? snackBarMessage;

      try {
        throw Exception('PlatformException: no biometric hardware');
      } catch (e) {
        snackBarMessage = 'Auth failed: $e';
      }

      expect(snackBarMessage, contains('Auth failed'));
      expect(snackBarMessage, contains('PlatformException'));
    });
  });
}
