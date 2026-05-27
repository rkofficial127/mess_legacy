import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../models/bill.dart';
import '../models/meal_plan.dart';
import '../models/mess_off.dart';
import '../models/subscription.dart';
import '../models/user.dart';

class MealAttendance {
  final DateTime date;
  final String mealType;
  final bool messOff;
  final int totalSubscribed;
  final int totalTaking;
  final int totalSkipped;
  final List<AttendanceUser> taking;
  final List<AttendanceUser> skipped;

  MealAttendance({
    required this.date,
    required this.mealType,
    required this.messOff,
    required this.totalSubscribed,
    required this.totalTaking,
    required this.totalSkipped,
    required this.taking,
    required this.skipped,
  });

  factory MealAttendance.fromJson(Map<String, dynamic> json) => MealAttendance(
        date: DateTime.parse(json['date'] as String),
        mealType: json['meal_type'] as String,
        messOff: json['mess_off'] as bool,
        totalSubscribed: json['total_subscribed'] as int,
        totalTaking: json['total_taking'] as int,
        totalSkipped: json['total_skipped'] as int,
        taking: (json['taking'] as List)
            .map((j) => AttendanceUser.fromJson(j))
            .toList(),
        skipped: (json['skipped'] as List)
            .map((j) => AttendanceUser.fromJson(j))
            .toList(),
      );
}

class AttendanceUser {
  final String userId;
  final String fullName;
  final String email;
  final String planName;

  AttendanceUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.planName,
  });

  factory AttendanceUser.fromJson(Map<String, dynamic> json) => AttendanceUser(
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        planName: json['plan_name'] as String,
      );
}

final usersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final res =
      await ApiClient.dio.get('/api/users', queryParameters: {'include_inactive': true});
  return (res.data as List).map((j) => User.fromJson(j)).toList();
});

final plansProvider =
    FutureProvider.autoDispose<List<MealPlan>>((ref) async {
  final res = await ApiClient.dio.get('/api/meal-plans');
  return (res.data as List).map((j) => MealPlan.fromJson(j)).toList();
});

final adminBillsProvider =
    FutureProvider.autoDispose.family<List<Bill>, ({int month, int year})>(
        (ref, args) async {
  final res = await ApiClient.dio.get('/api/bills', queryParameters: {
    'month': args.month,
    'year': args.year,
  });
  return (res.data as List).map((j) => Bill.fromJson(j)).toList();
});

final userSubscriptionProvider = FutureProvider.autoDispose
    .family<Subscription?, ({String userId, int month, int year})>(
        (ref, args) async {
  try {
    final res = await ApiClient.dio.get(
      '/api/subscriptions/user/${args.userId}',
      queryParameters: {'month': args.month, 'year': args.year},
    );
    return Subscription.fromJson(res.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

final userBillsProvider = FutureProvider.autoDispose
    .family<List<Bill>, ({String userId, int? month, int? year})>(
        (ref, args) async {
  final params = <String, dynamic>{};
  if (args.month != null) params['month'] = args.month;
  if (args.year != null) params['year'] = args.year;
  final res = await ApiClient.dio.get(
    '/api/bills/user/${args.userId}',
    queryParameters: params,
  );
  return (res.data as List).map((j) => Bill.fromJson(j)).toList();
});

Future<User> createUser({
  required String email,
  required String fullName,
  required String password,
  required String phone,
  String role = 'USER',
}) async {
  final res = await ApiClient.dio.post('/api/users', data: {
    'email': email,
    'full_name': fullName,
    'password': password,
    'phone': phone,
    'role': role,
  });
  return User.fromJson(res.data);
}

Future<void> assignSubscription({
  required String userId,
  required String planId,
  required int month,
  required int year,
}) async {
  await ApiClient.dio.post('/api/subscriptions', data: {
    'user_id': userId,
    'meal_plan_id': planId,
    'month': month,
    'year': year,
  });
}

Future<List<MessOff>> createMessOff({
  required List<DateTime> dates,
  required String mealType,
  String? reason,
}) async {
  final res = await ApiClient.dio.post('/api/mess-off', data: {
    'dates': dates.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
    'meal_type': mealType,
    if (reason != null) 'reason': reason,
  });
  return (res.data as List).map((j) => MessOff.fromJson(j)).toList();
}

Future<List<Bill>> generateBills(int month, int year) async {
  final res = await ApiClient.dio.post('/api/bills/generate', data: {
    'month': month,
    'year': year,
  });
  return (res.data as List).map((j) => Bill.fromJson(j)).toList();
}

Future<Bill> generateBillForUser(String userId, int month, int year) async {
  final res = await ApiClient.dio.post('/api/bills/generate-user', data: {
    'user_id': userId,
    'month': month,
    'year': year,
  });
  return Bill.fromJson(res.data);
}

Future<User> updateUser({
  required String userId,
  String? fullName,
  String? phone,
  String? role,
  bool? isActive,
}) async {
  final data = <String, dynamic>{};
  if (fullName != null) data['full_name'] = fullName;
  if (phone != null) data['phone'] = phone;
  if (role != null) data['role'] = role;
  if (isActive != null) data['is_active'] = isActive;
  final res = await ApiClient.dio.put('/api/users/$userId', data: data);
  return User.fromJson(res.data);
}

final attendanceProvider = FutureProvider.autoDispose
    .family<MealAttendance, ({String date, String? mealType})>(
        (ref, args) async {
  final params = <String, dynamic>{'target_date': args.date};
  if (args.mealType != null) params['meal_type'] = args.mealType;
  final res = await ApiClient.dio
      .get('/api/reports/meal-attendance', queryParameters: params);
  return MealAttendance.fromJson(res.data);
});

Future<void> createExtraMeal({
  required String userId,
  required DateTime date,
  required String mealType,
  String? note,
}) async {
  await ApiClient.dio.post('/api/extra-meals', data: {
    'user_id': userId,
    'date': DateFormat('yyyy-MM-dd').format(date),
    'meal_type': mealType,
    if (note != null && note.isNotEmpty) 'note': note,
  });
}

Future<void> deleteExtraMeal(String extraId) async {
  await ApiClient.dio.delete('/api/extra-meals/$extraId');
}
