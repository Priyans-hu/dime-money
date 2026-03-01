import 'dart:io';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'sms_reader_service.dart';

class NotificationReaderService {
  /// Check if notification listener permission is granted.
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;
    return await NotificationListenerService.isPermissionGranted();
  }

  /// Open system settings to grant notification access.
  Future<void> requestPermission() async {
    if (!Platform.isAndroid) return;
    await NotificationListenerService.requestPermission();
  }

  /// Read active notifications that look like financial messages.
  /// Returns them in SmsMessage format for unified parsing.
  Future<List<SmsMessage>> readFinancialNotifications() async {
    if (!Platform.isAndroid) return [];

    final hasAccess = await NotificationListenerService.isPermissionGranted();
    if (!hasAccess) return [];

    final events = await NotificationListenerService.getActiveNotifications();
    final results = <SmsMessage>[];

    for (final event in events) {
      final text = _extractText(event);
      if (text == null || text.isEmpty) continue;
      if (!_looksFinancial(text)) continue;

      results.add(SmsMessage(
        sender: event.packageName ?? 'notification',
        body: text,
        date: DateTime.now(),
      ));
    }

    return results;
  }

  String? _extractText(ServiceNotificationEvent event) {
    final parts = <String>[];
    if (event.title != null && event.title!.isNotEmpty) {
      parts.add(event.title!);
    }
    if (event.content != null && event.content!.isNotEmpty) {
      parts.add(event.content!);
    }
    return parts.isEmpty ? null : parts.join(' ');
  }

  static final _financialPattern = RegExp(
    r'(?:Rs\.?|INR|₹)\s*[\d,]+|debited|credited|spent|received|withdrawn|a/c|account',
    caseSensitive: false,
  );

  bool _looksFinancial(String text) {
    return _financialPattern.hasMatch(text);
  }
}
