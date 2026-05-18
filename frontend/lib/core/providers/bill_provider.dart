import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/bill.dart';

final myBillProvider =
    FutureProvider.autoDispose.family<Bill?, ({int month, int year})>(
        (ref, args) async {
  try {
    final res = await ApiClient.dio.get('/api/bills/me', queryParameters: {
      'month': args.month,
      'year': args.year,
    });
    return Bill.fromJson(res.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});
