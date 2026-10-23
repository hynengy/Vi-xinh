import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';

class SyncResult {
  final bool success;
  final int syncedCount;
  final String message;
  final List<dynamic>? serverTransactions;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    required this.message,
    this.serverTransactions,
  });
}

class SyncService {
  String _baseUrl;

  SyncService({String? baseUrl})
      : _baseUrl = baseUrl ?? _detectDefaultUrl();

  static String _detectDefaultUrl() {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000';
      }
    } catch (_) {}
    return 'http://127.0.0.1:5000';
  }

  String get baseUrl => _baseUrl;
  set baseUrl(String url) => _baseUrl = url;

  /// Kiểm tra kết nối tới Backend Server
  Future<bool> checkConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/stats'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Đồng bộ danh sách giao dịch cục bộ lên Web Server
  Future<SyncResult> syncTransactions({
    required int userId,
    required List<TransactionModel> transactions,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final syncedCount = data['synced_count'] as int? ?? 0;
        final serverTxs = data['transactions'] as List<dynamic>?;
        return SyncResult(
          success: true,
          syncedCount: syncedCount,
          message: 'Đồng bộ thành công $syncedCount giao dịch',
          serverTransactions: serverTxs,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Máy chủ phản hồi mã ${response.statusCode}',
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Không thể kết nối máy chủ ($e)',
      );
    }
  }
}
