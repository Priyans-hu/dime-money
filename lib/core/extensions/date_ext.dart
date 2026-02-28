import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String get formatted => DateFormat('MMM d, y').format(this);
  String get shortFormatted => DateFormat('MMM d').format(this);
  String get timeFormatted => DateFormat('h:mm a').format(this);
  String get monthYear => DateFormat('MMMM y').format(this);
  String get dayMonth => DateFormat('d MMM').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  DateTime get startOfMonth => DateTime(year, month);
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  DateTime get startOfWeek {
    final diff = weekday - DateTime.monday;
    return subtract(Duration(days: diff)).startOfDay;
  }

  DateTime get endOfWeek {
    return startOfWeek.add(const Duration(days: 6)).endOfDay;
  }

  String get relativeLabel {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    return formatted;
  }
}
