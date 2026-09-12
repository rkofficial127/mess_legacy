class Payment {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String? note;
  final String recordedBy;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    this.note,
    required this.recordedBy,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        amount: double.parse(json['amount'].toString()),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        recordedBy: json['recorded_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Balance {
  final String userId;
  final double totalPaid;
  final double totalBilled;
  final double balance;

  Balance({
    required this.userId,
    required this.totalPaid,
    required this.totalBilled,
    required this.balance,
  });

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        userId: json['user_id'] as String,
        totalPaid: double.parse(json['total_paid'].toString()),
        totalBilled: double.parse(json['total_billed'].toString()),
        balance: double.parse(json['balance'].toString()),
      );
}
