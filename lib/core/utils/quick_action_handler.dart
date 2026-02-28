import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/router/app_router.dart' show rootNavigatorKey;
import 'package:dime_money/features/transactions/presentation/widgets/quick_add_sheet.dart';

class QuickActionHandler {
  static const _channel =
      MethodChannel('com.priyanshu.dime_money/quick_actions');
  static final QuickActions _quickActions = QuickActions();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Check if app was launched via a quick action (Android method channel)
      try {
        final launchAction =
            await _channel.invokeMethod<String>('getLaunchAction');
        if (launchAction != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handle(launchAction);
          });
        }
      } catch (_) {
        // Method channel not available
      }

      // Listen for actions while app is running (Android)
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'quickAction') {
          final action = call.arguments as String?;
          if (action != null) _handle(action);
        }
      });

      // iOS quick actions via plugin
      _quickActions.initialize((action) {
        _handle(action);
      });
    } catch (_) {
      // Quick actions not available on this platform
    }
  }

  static void _handle(String action) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;

    TransactionType? type;
    if (action == 'add_expense') {
      type = TransactionType.expense;
    } else if (action == 'add_income') {
      type = TransactionType.income;
    }

    if (type != null) {
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => QuickAddSheet(initialType: type),
      );
    }
  }

  static Future<void> updateShortcuts(bool incomeEnabled) async {
    final shortcuts = <ShortcutItem>[
      const ShortcutItem(
        type: 'add_expense',
        localizedTitle: 'Add Expense',
        icon: 'ic_shortcut_expense',
      ),
      if (incomeEnabled)
        const ShortcutItem(
          type: 'add_income',
          localizedTitle: 'Add Income',
          icon: 'ic_shortcut_income',
        ),
    ];

    try {
      await _quickActions.setShortcutItems(shortcuts);
    } catch (_) {}
  }
}
