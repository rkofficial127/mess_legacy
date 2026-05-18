class MealPlan {
  final String id;
  final String name;
  final String foodType;
  final int mealsPerDay;
  final double monthlyRate;
  final bool isActive;

  const MealPlan({
    required this.id,
    required this.name,
    required this.foodType,
    required this.mealsPerDay,
    required this.monthlyRate,
    required this.isActive,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        foodType: json['food_type'] as String,
        mealsPerDay: json['meals_per_day'] as int,
        monthlyRate: double.parse(json['monthly_rate'].toString()),
        isActive: json['is_active'] as bool,
      );
}
