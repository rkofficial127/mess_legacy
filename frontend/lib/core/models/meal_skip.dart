class MealSkip {
  final String id;
  final String userId;
  final DateTime date;
  final String mealType;
  final DateTime createdAt;

  const MealSkip({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.createdAt,
  });

  factory MealSkip.fromJson(Map<String, dynamic> json) => MealSkip(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: DateTime.parse(json['date'] as String),
        mealType: json['meal_type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
