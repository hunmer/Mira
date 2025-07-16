import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
  }

  static String formatTimeinfo(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}
