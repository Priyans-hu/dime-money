import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/features/sms_import/data/models/parsed_sms.dart';
import 'sms_reader_service.dart';

class SmsParserService {
  static final _amountPattern = RegExp(
    r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final _debitPattern = RegExp(
    r'debited|spent|paid|withdrawn|purchase|debit|sent|payment\s+of',
    caseSensitive: false,
  );

  static final _creditPattern = RegExp(
    r'credited|received|refund|cashback|credit|deposited',
    caseSensitive: false,
  );

  static final _accountPattern = RegExp(
    r'(?:a/c|ac|account|acct)[\s*]*(?:no\.?\s*)?[xX*]*(\d{4})',
    caseSensitive: false,
  );

  static final _merchantPattern = RegExp(
    r'(?:to|at|for|towards)\s+([A-Za-z0-9][A-Za-z0-9\s&.-]{1,30}?)(?:\s+on|\s+ref|\s+via|\s+using|\.|,|$)',
    caseSensitive: false,
  );

  static final _otpPattern = RegExp(
    r'\bOTP\b|one.?time.?password|verification\s+code|\bCVV\b',
    caseSensitive: false,
  );

  static final _promoPattern = RegExp(
    r'offer|cashback\s+up\s+to|win|congratulations|apply\s+now|limited\s+period',
    caseSensitive: false,
  );

  /// Parse a list of raw SMS messages into structured transaction data.
  List<ParsedSms> parseAll(List<SmsMessage> messages) {
    final results = <ParsedSms>[];
    for (final msg in messages) {
      final parsed = parse(msg);
      if (parsed != null) results.add(parsed);
    }
    return results;
  }

  /// Parse a single SMS. Returns null if not a valid transaction message.
  ParsedSms? parse(SmsMessage msg) {
    final body = msg.body;

    // Skip OTP and promotional messages
    if (_otpPattern.hasMatch(body)) return null;
    if (_promoPattern.hasMatch(body)) return null;

    // Extract amount (required)
    final amountMatch = _amountPattern.firstMatch(body);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    // Determine type
    final isDebit = _debitPattern.hasMatch(body);
    final isCredit = _creditPattern.hasMatch(body);

    // If neither debit nor credit keyword found, skip
    if (!isDebit && !isCredit) return null;

    // If both found, prioritize based on order in text
    TransactionType type;
    if (isDebit && isCredit) {
      final debitPos = _debitPattern.firstMatch(body)!.start;
      final creditPos = _creditPattern.firstMatch(body)!.start;
      type = debitPos < creditPos ? TransactionType.expense : TransactionType.income;
    } else {
      type = isDebit ? TransactionType.expense : TransactionType.income;
    }

    // Extract account last 4 digits
    final accountMatch = _accountPattern.firstMatch(body);
    final accountLast4 = accountMatch?.group(1);

    // Extract merchant
    String? merchant;
    final merchantMatch = _merchantPattern.firstMatch(body);
    if (merchantMatch != null) {
      merchant = merchantMatch.group(1)?.trim();
      // Clean up merchant name
      if (merchant != null && merchant.length < 2) merchant = null;
    }

    final smsId = ParsedSms.computeId(msg.date, amount, type);

    return ParsedSms(
      smsId: smsId,
      sender: msg.sender,
      date: msg.date,
      amount: amount,
      type: type,
      accountLast4: accountLast4,
      merchant: merchant,
    );
  }
}
