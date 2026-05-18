class Bill {
  final String id;
  final String userId;
  final int month;
  final int year;
  final String planName;
  final double planRate;
  final int totalMeals;
  final int skippedMeals;
  final int messOffMeals;
  final double deductionAmount;
  final double finalAmount;
  final DateTime generatedAt;

  const Bill({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.planName,
    required this.planRate,
    required this.totalMeals,
    required this.skippedMeals,
    required this.messOffMeals,
    required this.deductionAmount,
    required this.finalAmount,
    required this.generatedAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        month: json['month'] as int,
        year: json['year'] as int,
        planName: json['plan_name'] as String,
        planRate: double.parse(json['plan_rate'].toString()),
        totalMeals: json['total_meals'] as int,
        skippedMeals: json['skipped_meals'] as int,
        messOffMeals: json['mess_off_meals'] as int,
        deductionAmount: double.parse(json['deduction_amount'].toString()),
        finalAmount: double.parse(json['final_amount'].toString()),
        generatedAt: DateTime.parse(json['generated_at'] as String),
      );
}
