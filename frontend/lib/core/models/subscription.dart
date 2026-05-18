class Subscription {
  final String id;
  final String userId;
  final String mealPlanId;
  final int month;
  final int year;
  final bool isActive;
  final String? planName;
  final String? planFoodType;
  final int? planMealsPerDay;
  final double? planMonthlyRate;

  const Subscription({
    required this.id,
    required this.userId,
    required this.mealPlanId,
    required this.month,
    required this.year,
    required this.isActive,
    this.planName,
    this.planFoodType,
    this.planMealsPerDay,
    this.planMonthlyRate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        mealPlanId: json['meal_plan_id'] as String,
        month: json['month'] as int,
        year: json['year'] as int,
        isActive: json['is_active'] as bool,
        planName: json['plan_name'] as String?,
        planFoodType: json['plan_food_type'] as String?,
        planMealsPerDay: json['plan_meals_per_day'] as int?,
        planMonthlyRate: json['plan_monthly_rate'] != null
            ? double.parse(json['plan_monthly_rate'].toString())
            : null,
      );
}
