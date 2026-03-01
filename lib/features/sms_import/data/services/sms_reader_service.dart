import 'dart:io';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsMessage {
  final String sender;
  final String body;
  final DateTime date;

  const SmsMessage({
    required this.sender,
    required this.body,
    required this.date,
  });
}

enum SmsPermissionResult { granted, denied, permanentlyDenied, notAndroid }

class SmsReaderService {
  static const _bankSenderIds = [
    'HDFCBK', 'SBIINB', 'ICICIB', 'AXISBK', 'KOTAKB', 'PNBSMS',
    'BOIIND', 'CANBNK', 'UNIONB', 'IABORB', 'YESBNK', 'IDFCFB',
    'FEDBNK', 'INDBNK', 'RBLBNK', 'SCBANK', 'CITIBK', 'HSBCBK',
    'DENABNK', 'BARODABNK', 'JIOBNK', 'PAYTMB', 'AIRTEL', 'FINOBNK',
    'AUBANK', 'EABORB',
    // UPI apps
    'GPAY', 'PHONEPE', 'PAYTM', 'AMZNPAY',
  ];

  /// Request SMS permission.
  Future<SmsPermissionResult> requestPermission() async {
    if (!Platform.isAndroid) return SmsPermissionResult.notAndroid;

    final status = await Permission.sms.request();
    if (status.isGranted) return SmsPermissionResult.granted;
    if (status.isPermanentlyDenied) return SmsPermissionResult.permanentlyDenied;
    return SmsPermissionResult.denied;
  }

  /// Check if SMS permission is already granted.
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;
    return (await Permission.sms.status).isGranted;
  }

  /// Read financial SMS from inbox (last 90 days).
  Future<List<SmsMessage>> readFinancialSms() async {
    if (!Platform.isAndroid) return [];

    final query = SmsQuery();
    final messages = await query.querySms(
      kinds: [SmsQueryKind.inbox],
    );

    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final results = <SmsMessage>[];

    for (final msg in messages) {
      if (msg.date == null || msg.date!.isBefore(cutoff)) continue;
      if (msg.body == null || msg.body!.isEmpty) continue;
      if (msg.address == null) continue;

      final sender = msg.address!.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (!_isFinancialSender(sender)) continue;

      results.add(SmsMessage(
        sender: msg.address!,
        body: msg.body!,
        date: msg.date!,
      ));
    }

    return results;
  }

  bool _isFinancialSender(String sender) {
    for (final id in _bankSenderIds) {
      if (sender.contains(id)) return true;
    }
    return false;
  }
}
