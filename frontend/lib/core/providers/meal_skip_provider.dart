import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../models/extra_meal.dart';
import '../models/meal_skip.dart';
import '../models/mess_off.dart';
import '../models/subscription.dart';

final subscriptionProvider =
    FutureProvider.autoDispose<Subscription?>((ref) async {
  try {
    final res = await ApiClient.dio.get('/api/subscriptions/me');
    return Subscription.fromJson(res.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

final monthSkipsProvider =
    FutureProvider.autoDispose.family<List<MealSkip>, ({int month, int year})>(
        (ref, args) async {
  final res = await ApiClient.dio
      .get('/api/meal-skips/me', queryParameters: {
    'month': args.month,
    'year': args.year,
  });
  return (res.data as List).map((j) => MealSkip.fromJson(j)).toList();
});

final messOffProvider =
    FutureProvider.autoDispose.family<List<MessOff>, ({int month, int year})>(
        (ref, args) async {
  final res =
      await ApiClient.dio.get('/api/mess-off', queryParameters: {
    'month': args.month,
    'year': args.year,
  });
  return (res.data as List).map((j) => MessOff.fromJson(j)).toList();
});

Future<MealSkip> createSkip(DateTime date, String mealType) async {
  final res = await ApiClient.dio.post('/api/meal-skips', data: {
    'date': DateFormat('yyyy-MM-dd').format(date),
    'meal_type': mealType,
  });
  return MealSkip.fromJson(res.data);
}

Future<void> cancelSkip(String skipId) async {
  await ApiClient.dio.delete('/api/meal-skips/$skipId');
}

Future<List<MealSkip>> bulkSkipDay(DateTime date) async {
  final res = await ApiClient.dio.post('/api/meal-skips/bulk', data: {
    'date': DateFormat('yyyy-MM-dd').format(date),
  });
  return (res.data as List).map((j) => MealSkip.fromJson(j)).toList();
}

final extraMealsProvider = FutureProvider.autoDispose
    .family<List<ExtraMeal>, ({int month, int year})>((ref, args) async {
  final res = await ApiClient.dio
      .get('/api/extra-meals/me', queryParameters: {
    'month': args.month,
    'year': args.year,
  });
  return (res.data as List).map((j) => ExtraMeal.fromJson(j)).toList();
});
