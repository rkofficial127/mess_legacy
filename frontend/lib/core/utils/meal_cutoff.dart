bool isMealCutoffPassed(String mealType, DateTime day) {
  final now = DateTime.now();
  DateTime cutoff;
  if (mealType == 'BREAKFAST') {
    cutoff = DateTime(day.year, day.month, day.day - 1, 20, 0);
  } else if (mealType == 'LUNCH') {
    cutoff = DateTime(day.year, day.month, day.day, 8, 0);
  } else {
    cutoff = DateTime(day.year, day.month, day.day, 16, 0);
  }
  return now.isAfter(cutoff);
}
