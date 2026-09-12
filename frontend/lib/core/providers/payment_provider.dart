import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/payment.dart';

final myBalanceProvider = FutureProvider.autoDispose<Balance>((ref) async {
  final res = await ApiClient.dio.get('/api/payments/me/balance');
  return Balance.fromJson(res.data);
});

final myPaymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  final res = await ApiClient.dio.get('/api/payments/me');
  return (res.data as List).map((j) => Payment.fromJson(j)).toList();
});
