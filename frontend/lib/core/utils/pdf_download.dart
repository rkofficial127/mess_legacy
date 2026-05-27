import 'package:dio/dio.dart';
import '../api/api_client.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> downloadBillPdf({
  required String billId,
  required String filename,
}) async {
  final res = await ApiClient.dio.get(
    '/api/bills/$billId/export',
    options: Options(responseType: ResponseType.bytes),
  );
  _triggerDownload(res.data, filename);
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
  _triggerDownload(res.data, filename);
}

void _triggerDownload(List<int> bytes, String filename) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
