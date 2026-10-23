import 'package:flutter_test/flutter_test.dart';
import 'package:vi_xinh_mobile/services/sync_service.dart';

void main() {
  group('SyncService tests', () {
    test('default URL initialization and baseUrl setter', () {
      final service = SyncService();
      expect(service.baseUrl, isNotEmpty);

      service.baseUrl = 'http://192.168.1.10:5000';
      expect(service.baseUrl, equals('http://192.168.1.10:5000'));
    });

    test('SyncResult properties constructor', () {
      final res = SyncResult(
        success: true,
        syncedCount: 5,
        message: 'Đồng bộ thành công',
      );
      expect(res.success, isTrue);
      expect(res.syncedCount, equals(5));
      expect(res.message, contains('Đồng bộ'));
    });
  });
}
