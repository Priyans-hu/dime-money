import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

final incomeEnabledProvider =
    StateNotifierProvider<IncomeEnabledNotifier, bool>((ref) {
  return IncomeEnabledNotifier();
});

class IncomeEnabledNotifier extends StateNotifier<bool> {
  IncomeEnabledNotifier() : super(false) {
    _load();
  }

  static const _key = 'income_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

final currencySymbolProvider =
    StateNotifierProvider<CurrencySymbolNotifier, String>((ref) {
  return CurrencySymbolNotifier();
});

class CurrencySymbolNotifier extends StateNotifier<String> {
  CurrencySymbolNotifier() : super('\$') {
    _load();
  }

  static const _key = 'currency_symbol';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? '\$';
  }

  Future<void> set(String symbol) async {
    state = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, symbol);
  }
}

final autoCheckUpdateProvider =
    StateNotifierProvider<AutoCheckUpdateNotifier, bool>((ref) {
  return AutoCheckUpdateNotifier();
});

class AutoCheckUpdateNotifier extends StateNotifier<bool> {
  AutoCheckUpdateNotifier() : super(true) {
    _load();
  }

  static const _key = 'auto_check_update';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

final biometricEnabledProvider =
    StateNotifierProvider<BiometricEnabledNotifier, bool>((ref) {
  return BiometricEnabledNotifier();
});

class BiometricEnabledNotifier extends StateNotifier<bool> {
  BiometricEnabledNotifier() : super(false) {
    _load();
  }

  static const _key = 'biometric_enabled';
  final _auth = LocalAuthentication();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<bool> toggle() async {
    if (!state) {
      // Enabling: verify biometrics first
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      final didAuth = await _auth.authenticate(
        localizedReason: 'Verify to enable biometric lock',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!didAuth) return false;
    }

    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
    return true;
  }

  Future<void> disable() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
  }
}
