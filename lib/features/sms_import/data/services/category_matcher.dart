import 'package:dime_money/core/database/app_database.dart';

class CategoryMatcher {
  static const _keywordMap = <String, String>{
    // Food & Drinks
    'swiggy': 'Food & Drinks',
    'zomato': 'Food & Drinks',
    'dominos': 'Food & Drinks',
    'pizza': 'Food & Drinks',
    'restaurant': 'Food & Drinks',
    'cafe': 'Food & Drinks',
    'food': 'Food & Drinks',
    'burger': 'Food & Drinks',
    'starbucks': 'Food & Drinks',
    'mcdonald': 'Food & Drinks',
    'kfc': 'Food & Drinks',
    'dunkin': 'Food & Drinks',
    'biryani': 'Food & Drinks',
    'barbeque': 'Food & Drinks',
    'dineout': 'Food & Drinks',
    'eatsure': 'Food & Drinks',
    'blinkit': 'Food & Drinks',
    'zepto': 'Food & Drinks',
    'bigbasket': 'Food & Drinks',
    'grofers': 'Food & Drinks',
    'instamart': 'Food & Drinks',

    // Transport
    'uber': 'Transport',
    'ola': 'Transport',
    'rapido': 'Transport',
    'metro': 'Transport',
    'fuel': 'Transport',
    'petrol': 'Transport',
    'diesel': 'Transport',
    'iocl': 'Transport',
    'bpcl': 'Transport',
    'hpcl': 'Transport',
    'irctc': 'Transport',
    'railways': 'Transport',
    'makemytrip': 'Transport',
    'goibibo': 'Transport',
    'redbus': 'Transport',
    'parking': 'Transport',
    'fastag': 'Transport',
    'toll': 'Transport',

    // Shopping
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',
    'ajio': 'Shopping',
    'meesho': 'Shopping',
    'nykaa': 'Shopping',
    'snapdeal': 'Shopping',
    'croma': 'Shopping',
    'reliance': 'Shopping',
    'dmart': 'Shopping',
    'mall': 'Shopping',
    'shop': 'Shopping',
    'store': 'Shopping',
    'mart': 'Shopping',
    'tatacliq': 'Shopping',

    // Bills & Utilities
    'electricity': 'Bills & Utilities',
    'airtel': 'Bills & Utilities',
    'jio': 'Bills & Utilities',
    'vodafone': 'Bills & Utilities',
    'bsnl': 'Bills & Utilities',
    'broadband': 'Bills & Utilities',
    'wifi': 'Bills & Utilities',
    'recharge': 'Bills & Utilities',
    'insurance': 'Bills & Utilities',
    'lic': 'Bills & Utilities',
    'premium': 'Bills & Utilities',
    'water': 'Bills & Utilities',
    'gas': 'Bills & Utilities',
    'rent': 'Bills & Utilities',
    'emi': 'Bills & Utilities',
    'loan': 'Bills & Utilities',
    'bill': 'Bills & Utilities',
    'postpaid': 'Bills & Utilities',
    'prepaid': 'Bills & Utilities',

    // Entertainment
    'netflix': 'Entertainment',
    'hotstar': 'Entertainment',
    'prime': 'Entertainment',
    'spotify': 'Entertainment',
    'youtube': 'Entertainment',
    'bookmyshow': 'Entertainment',
    'cinema': 'Entertainment',
    'movie': 'Entertainment',
    'pvr': 'Entertainment',
    'inox': 'Entertainment',
    'game': 'Entertainment',
    'steam': 'Entertainment',
    'playstation': 'Entertainment',

    // Health
    'hospital': 'Health',
    'pharmacy': 'Health',
    'medical': 'Health',
    'doctor': 'Health',
    'apollo': 'Health',
    'pharmeasy': 'Health',
    'netmeds': 'Health',
    'medplus': 'Health',
    'tata1mg': 'Health',
    'gym': 'Health',
    'fitness': 'Health',
    'cult': 'Health',

    // Education
    'school': 'Education',
    'college': 'Education',
    'university': 'Education',
    'course': 'Education',
    'udemy': 'Education',
    'coursera': 'Education',
    'unacademy': 'Education',
    'byjus': 'Education',
    'exam': 'Education',
    'tuition': 'Education',
    'book': 'Education',
  };

  /// Match a merchant string to a category ID from the database.
  /// Returns null if no match found (caller should use "Other" category).
  static int? match(String? merchant, List<Category> categories) {
    if (merchant == null || merchant.isEmpty) return null;

    final lower = merchant.toLowerCase();

    // Find matching category name from keywords (word boundary match)
    String? matchedCategoryName;
    for (final entry in _keywordMap.entries) {
      final pattern = RegExp('\\b${RegExp.escape(entry.key)}\\b');
      if (pattern.hasMatch(lower)) {
        matchedCategoryName = entry.value;
        break;
      }
    }

    if (matchedCategoryName == null) return null;

    // Find category ID by name
    for (final cat in categories) {
      if (cat.name == matchedCategoryName) return cat.id;
    }

    return null;
  }

  /// Get the "Other" category ID as fallback.
  static int? otherCategoryId(List<Category> categories) {
    for (final cat in categories) {
      if (cat.name == 'Other') return cat.id;
    }
    return null;
  }
}
