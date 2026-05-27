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
