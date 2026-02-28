import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:dime_money/features/settings/presentation/providers/settings_provider.dart';

class LockGate extends ConsumerStatefulWidget {
  final Widget child;

  const LockGate({super.key, required this.child});

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  String? _errorMessage;
  final _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biometricEnabled = ref.read(biometricEnabledProvider);
      if (biometricEnabled) {
        setState(() => _isLocked = true);
        _authenticate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final biometricEnabled = ref.read(biometricEnabledProvider);
    if (!biometricEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      setState(() => _isLocked = true);
    } else if (state == AppLifecycleState.resumed && _isLocked) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    setState(() => _errorMessage = null);
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: 'Unlock Dime Money',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuth) {
        setState(() => _isLocked = false);
      } else {
        setState(() => _errorMessage = 'Authentication failed');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Biometric authentication unavailable');
    }
  }

  void _disableLock() {
    ref.read(biometricEnabledProvider.notifier).disable();
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 64),
                const SizedBox(height: 16),
                const Text('Dime Money is locked'),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _disableLock,
                  child: const Text('Disable biometric lock'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
