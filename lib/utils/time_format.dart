import 'package:intl/intl.dart';

/// Human-friendly time formatting used across chat lists and bubbles.
class TimeFormat {
  TimeFormat._();

  /// "9:41 AM"
  static String clock(DateTime t) => DateFormat.jm().format(t);

  /// Relative label for chat/call lists: time today, "Yesterday",
  /// weekday this week, otherwise a short date.
  static String relative(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(t.year, t.month, t.day);
    final diffDays = today.difference(that).inDays;

    if (diffDays == 0) return DateFormat.jm().format(t);
    if (diffDays == 1) return 'Yesterday';
    if (diffDays < 7) return DateFormat.EEEE().format(t);
    return DateFormat.yMd().format(t);
  }

  /// "0:42" or "12:05" for call/voice-note durations.
  static String duration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// "last seen today at 9:41 AM" style subtitle.
  static String lastSeen(DateTime t) {
    final now = DateTime.now();
    final diffDays =
        DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
    final time = DateFormat.jm().format(t);
    if (diffDays == 0) return 'last seen today at $time';
    if (diffDays == 1) return 'last seen yesterday at $time';
    return 'last seen ${DateFormat.MMMd().format(t)} at $time';
  }
}
