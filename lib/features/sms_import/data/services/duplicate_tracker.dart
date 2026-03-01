import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/features/sms_import/data/models/parsed_sms.dart';

class DuplicateTracker {
  static const _key = 'imported_sms_hashes';

  Future<Set<String>> _loadHashes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    return list?.toSet() ?? {};
  }

  Future<void> _saveHashes(Set<String> hashes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, hashes.toList());
  }

  /// Filter out already-imported transactions.
  Future<List<ParsedSms>> filterNew(List<ParsedSms> items) async {
    final existing = await _loadHashes();
    return items.where((item) => !existing.contains(item.smsId)).toList();
  }

  /// Mark transactions as imported.
  Future<void> markImported(List<String> smsIds) async {
    final existing = await _loadHashes();
    existing.addAll(smsIds);
    await _saveHashes(existing);
  }
}
