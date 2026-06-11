const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://mess-api-production.up.railway.app',
);

const Map<String, String> mealEmoji = {
  'BREAKFAST': '🌅',
  'LUNCH': '☀️',
  'DINNER': '🌙',
};

const Map<String, String> mealLabel = {
  'BREAKFAST': 'Breakfast',
  'LUNCH': 'Lunch',
  'DINNER': 'Dinner',
};

const Map<String, String> mealServingTime = {
  'BREAKFAST': '7:30 – 9:30 AM',
  'LUNCH': '12:30 – 2:00 PM',
  'DINNER': '7:30 – 9:00 PM',
};
