import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../models/bill.dart';
import '../models/meal_plan.dart';
import '../models/mess_off.dart';
import '../models/subscription.dart';
import '../models/user.dart';

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

Future<User> createUser({
  required String email,
  required String fullName,
  required String password,
  String? phone,
  String role = 'USER',
}) async {
  final res = await ApiClient.dio.post('/api/users', data: {
    'email': email,
    'full_name': fullName,
    'password': password,
    if (phone != null) 'phone': phone,
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
