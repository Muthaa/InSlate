// import '../core/constants/mpesa_patterns.dart';

class ParserUtils {
  ParserUtils._();

  static String? firstMatch(RegExp pattern, String text, int group) {
    final match = pattern.firstMatch(text);

    if (match == null) {
      return null;
    }

    return match.group(group);
  }

  static DateTime parseMpesaDate(String date, String time) {
    final dateParts = date.split('/');
    final timeParts = time.split(' ');

    final clock = timeParts[0].split(':');

    var hour = int.parse(clock[0]);
    final minute = int.parse(clock[1]);

    final amPm = timeParts[1].toUpperCase();

    if (amPm == 'PM' && hour != 12) {
      hour += 12;
    }

    if (amPm == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(
      2000 + int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
      hour,
      minute,
    );
  }
}
