import 'package:flutter_test/flutter_test.dart';
import 'package:vi_xinh_mobile/services/vietqr_service.dart';

void main() {
  group('VietQrService tests', () {
    test('banks list contains major Vietnamese banks', () {
      expect(VietQrService.banks.any((b) => b.name == 'Vietcombank'), isTrue);
      expect(VietQrService.banks.any((b) => b.name == 'Techcombank'), isTrue);
      expect(VietQrService.banks.any((b) => b.name == 'MB Bank'), isTrue);
    });

    test('imageUrl generates correct VietQR URL format', () {
      final url = VietQrService.imageUrl(
        bankBin: '970436',
        accountNo: '0123456789',
        accountName: 'NGUYEN THUY HIEN',
        amount: 250000,
        addInfo: 'Tien an trua',
      );

      expect(url, isNotNull);
      expect(url!.startsWith('https://img.vietqr.io/image/970436-0123456789-compact2.png'), isTrue);
      expect(url.contains('accountName=NGUYEN%20THUY%20HIEN'), isTrue);
      expect(url.contains('amount=250000'), isTrue);
    });

    test('imageUrl returns null if bankBin or accountNo is empty', () {
      expect(VietQrService.imageUrl(bankBin: '', accountNo: '123', accountName: 'A'), isNull);
      expect(VietQrService.imageUrl(bankBin: '970436', accountNo: '', accountName: 'A'), isNull);
    });
  });
}
