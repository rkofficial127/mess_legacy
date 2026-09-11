import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';

final myDeliveryStatusProvider =
    FutureProvider.autoDispose<Map<String, bool>>((ref) async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final res = await ApiClient.dio.get('/api/meal-deliveries/me',
      queryParameters: {'target_date': today});
  return Map<String, bool>.from(res.data['delivered'] as Map);
});
