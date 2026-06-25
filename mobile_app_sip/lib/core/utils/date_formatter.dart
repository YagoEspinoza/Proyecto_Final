import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _shortDateFormat.format(date);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateTimeFormat.format(dateTime);
  }

  static String formatDateString(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      return _shortDateFormat.format(parsed);
    } catch (_) {
      return dateStr;
    }
  }
}
