import 'package:intl/intl.dart';

class DateFormatter {

  // Try multiple known input formats before giving up
  static DateTime? _tryParse(String dateStr) {
    // 1. Standard ISO — DateTime.parse handles this natively
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // 2. Add any other formats your API might send 👇
    final inputFormats = [
      'dd-MMM-yyyy',   // 14-Apr-2026
      'dd/MM/yyyy',    // 14/04/2026
      'MM/dd/yyyy',    // 04/14/2026
      'yyyy/MM/dd',    // 2026/04/14
      'dd-MM-yyyy',    // 14-04-2026
      'MMM dd, yyyy',  // Apr 14, 2026
      'd MMM yyyy',    // 14 Apr 2026
    ];

    for (final fmt in inputFormats) {
      try {
        return DateFormat(fmt).parseStrict(dateStr.trim());
      } catch (_) {}
    }

    return null; // All formats failed
  }

  // Format: "14-Apr-2026"
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    final date = _tryParse(dateStr);
    if (date == null) return 'Invalid date';
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  // Format: "14-Apr-2026 (Tuesday)"
  static String formatDateWithDay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    final date = _tryParse(dateStr);
    if (date == null) return 'Invalid date';
    return '${DateFormat('dd-MMM-yyyy').format(date)} (${DateFormat('EEEE').format(date)})';
  }

  static String formatTimeWithAmPm(String time) {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }
}