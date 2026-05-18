const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
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
