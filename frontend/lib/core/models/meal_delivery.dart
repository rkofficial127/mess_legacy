class MealDelivery {
  final String id;
  final String userId;
  final DateTime date;
  final String mealType;
  final DateTime deliveredAt;
  final String deliveredBy;

  MealDelivery({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.deliveredAt,
    required this.deliveredBy,
  });

  factory MealDelivery.fromJson(Map<String, dynamic> json) => MealDelivery(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: DateTime.parse(json['date'] as String),
        mealType: json['meal_type'] as String,
        deliveredAt: DateTime.parse(json['delivered_at'] as String),
        deliveredBy: json['delivered_by'] as String,
      );
}
