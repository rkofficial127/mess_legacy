import 'package:flutter/foundation.dart' show kIsWeb;

// Web build: same-origin (backend serves the frontend), so a relative
// base URL avoids hardcoding a host that will change across deploys.
// Native builds need an absolute URL since there's no "page origin".
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kIsWeb ? '' : 'https://mess-legacy.onrender.com',
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
