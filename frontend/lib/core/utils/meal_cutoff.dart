import 'package:intl/intl.dart';

DateTime mealCutoff(String mealType, DateTime day) {
  if (mealType == 'BREAKFAST') {
    return DateTime(day.year, day.month, day.day - 1, 20, 0);
  } else if (mealType == 'LUNCH') {
    return DateTime(day.year, day.month, day.day, 8, 0);
  }
  return DateTime(day.year, day.month, day.day, 16, 0);
}

bool isMealCutoffPassed(String mealType, DateTime day) {
  return DateTime.now().isAfter(mealCutoff(mealType, day));
}

/// Absolute deadline label, e.g. "8:00 AM" or "8:00 PM, 14 Jun"
/// when the cutoff falls on a different day (breakfast).
String skipDeadlineLabel(String mealType, DateTime day) {
  final cutoff = mealCutoff(mealType, day);
  final sameDay = cutoff.year == day.year &&
      cutoff.month == day.month &&
      cutoff.day == day.day;
  final time = DateFormat('h:mm a').format(cutoff);
  return sameDay ? time : '$time, ${DateFormat('d MMM').format(cutoff)}';
}
