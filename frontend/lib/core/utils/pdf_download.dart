import 'package:dio/dio.dart';
import '../api/api_client.dart';
import 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart'
    if (dart.library.io) 'pdf_download_mobile.dart' as platform;

Future<void> downloadBillPdf({
  required String billId,
  required String filename,
}) async {
  final res = await ApiClient.dio.get(
    '/api/bills/$billId/export',
    options: Options(responseType: ResponseType.bytes),
  );
  await platform.savePdf(res.data, filename);
}

Future<void> downloadMyBillPdf({
  required int month,
  required int year,
  required String filename,
}) async {
  final res = await ApiClient.dio.get(
    '/api/bills/me/export',
    queryParameters: {'month': month, 'year': year},
    options: Options(responseType: ResponseType.bytes),
  );
  await platform.savePdf(res.data, filename);
}
