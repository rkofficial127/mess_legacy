class ExtraMeal {
  final String id;
  final String userId;
  final DateTime date;
  final String mealType;
  final String? note;
  final String createdBy;
  final DateTime createdAt;

  const ExtraMeal({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    this.note,
    required this.createdBy,
    required this.createdAt,
  });

  factory ExtraMeal.fromJson(Map<String, dynamic> json) => ExtraMeal(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: DateTime.parse(json['date'] as String),
        mealType: json['meal_type'] as String,
        note: json['note'] as String?,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
