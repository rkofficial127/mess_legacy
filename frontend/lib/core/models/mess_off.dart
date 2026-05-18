class MessOff {
  final String id;
  final DateTime date;
  final String mealType;
  final String? reason;
  final String createdBy;
  final DateTime createdAt;

  const MessOff({
    required this.id,
    required this.date,
    required this.mealType,
    this.reason,
    required this.createdBy,
    required this.createdAt,
  });

  factory MessOff.fromJson(Map<String, dynamic> json) => MessOff(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        mealType: json['meal_type'] as String,
        reason: json['reason'] as String?,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
