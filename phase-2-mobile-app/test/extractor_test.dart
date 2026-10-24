import 'package:flutter_test/flutter_test.dart';
import 'package:vi_xinh_mobile/extractor/dart_receipt_extractor.dart';

void main() {
  group('DartReceiptExtractor - cleanText & parseAmountStr', () {
    test('cleanText trims and removes empty lines', () {
      final input = '''
        HIGHLANDS COFFEE   
        
        28/10/2026
        
        TỔNG TIỀN: 135.000 đ
      ''';
      final lines = DartReceiptExtractor.cleanText(input);
      expect(lines.length, 3);
      expect(lines[0], 'HIGHLANDS COFFEE');
      expect(lines[1], '28/10/2026');
      expect(lines[2], 'TỔNG TIỀN: 135.000 đ');
    });

    test('parseAmountStr handles Vietnamese dots formatting', () {
      expect(DartReceiptExtractor.parseAmountStr('135.000'), 135000.0);
      expect(DartReceiptExtractor.parseAmountStr('50.662.000 đ'), 50662000.0);
      expect(DartReceiptExtractor.parseAmountStr('42.000 VND'), 42000.0);
    });

    test('parseAmountStr handles commas', () {
      expect(DartReceiptExtractor.parseAmountStr('135,000'), 135000.0);
      expect(DartReceiptExtractor.parseAmountStr('1.250,50'), 1250.5);
    });
  });

  group('DartReceiptExtractor - extractMerchant', () {
    test('identifies known retail chains', () {
      final lines1 = ['HIGHLANDS COFFEE', 'Cửa hàng 123', 'Hóa đơn bán lẻ'];
      expect(DartReceiptExtractor.extractMerchant(lines1), 'HIGHLANDS COFFEE');

      final lines2 = ['WINMART+', 'Chi nhánh Cầu Giấy'];
      expect(DartReceiptExtractor.extractMerchant(lines2), 'WINMART+');

      final lines3 = ['CIRCLE K', 'Store #45'];
      expect(DartReceiptExtractor.extractMerchant(lines3), 'CIRCLE K');
    });

    test('identifies room rent notices', () {
      final lines = [
        'THÔNG BÁO TIỀN TRỌ',
        'Phòng 302',
        'Tiền phòng: 3.800.000',
      ];
      expect(DartReceiptExtractor.extractMerchant(lines), 'Tiền trọ Phòng 302');
    });

    test('identifies restaurant by prefix keyword', () {
      final lines = [
        'NHÀ HÀNG HƯƠNG BIỂN',
        'ĐC: 123 Bờ Biển, Đà Nẵng',
        'Hotline: 0912.345.678',
        '1. Cơm chiên: 120.000',
      ];
      expect(DartReceiptExtractor.extractMerchant(lines), 'NHÀ HÀNG HƯƠNG BIỂN');
      expect(DartReceiptExtractor.extractHotline(lines), contains('0912'));
      expect(DartReceiptExtractor.extractAddress(lines), contains('123 Bờ Biển'));
    });
  });

  group('DartReceiptExtractor - extractDate', () {
    test('extracts DD/MM/YYYY date format', () {
      final text = 'Ngày in: 28/10/2026 14:30';
      expect(DartReceiptExtractor.extractDate(text), '2026-10-28');
    });

    test('extracts Vietnamese word date format', () {
      final text = 'Hà Nội, ngày 22 tháng 10 năm 2026';
      expect(DartReceiptExtractor.extractDate(text), '2026-10-22');
    });

    test('extracts room rent month format', () {
      final text = 'Tiền phòng tháng 06/2026';
      expect(DartReceiptExtractor.extractDate(text), '2026-06-01');
    });
  });

  group('DartReceiptExtractor - extractTotal', () {
    test('extracts total amount with TỔNG CỘNG keyword', () {
      final lines = [
        'HIGHLANDS COFFEE',
        'Trà sen vàng: 55.000',
        'Phin sữa đá: 39.000',
        'TỔNG CỘNG: 94.000 đ',
        'Tiền mặt: 100.000',
      ];
      final res = DartReceiptExtractor.extractTotal(lines);
      expect(res['total'], 94000.0);
    });

    test('extracts total when keyword is on preceding line', () {
      final lines = [
        'CỬA HÀNG TIỆN LỢI',
        'Thành tiền',
        '185.000 đ',
      ];
      final res = DartReceiptExtractor.extractTotal(lines);
      expect(res['total'], 185000.0);
    });

    test('does not mistake hotline phone number for total amount', () {
      final lines = [
        'QUÁN ĂN GIA ĐÌNH',
        'Hotline: 0988.123.456',
        '1. Cơm rang dưa bò: 50.000',
        'TỔNG TIỀN: 50.000 đ',
      ];
      final res = DartReceiptExtractor.extractTotal(lines);
      expect(res['total'], 50000.0);
    });
  });

  group('DartReceiptExtractor - extractLineItems', () {
    test('extracts room rental utility line items', () {
      final lines = [
        'THÔNG BÁO TIỀN TRỌ - Phòng 302',
        'Tiền phòng: 3.800.000',
        'Điện | 100 | 150 | 50 | 250.000',
        'Nước | 20 | 28 | 8 | 120.000',
        'Wifi: 100.000',
        'Tổng tiền: 4.270.000 đ',
      ];
      final items = DartReceiptExtractor.extractLineItems(lines);
      final names = items.map((it) => it.name).toList();
      expect(names.any((n) => n.toLowerCase().contains('phòng')), isTrue);
      expect(names.any((n) => n.toLowerCase().contains('điện')), isTrue);
      expect(names.any((n) => n.toLowerCase().contains('nước')), isTrue);
    });

    test('extracts restaurant food dishes and cafe drinks', () {
      final lines = [
        'TIỆM TRÀ SỮA & CÀ PHÊ CHILL',
        'Hotline: 0912.888.999',
        'Ngày: 22/10/2026',
        '1. Trà sữa trân châu đường đen x2    70.000',
        '2. Cà phê sữa đá phin                25.000',
        '3. Khoai tây chiên giòn              30.000',
        'Tổng cộng: 125.000 đ',
      ];
      final items = DartReceiptExtractor.extractLineItems(lines);
      expect(items.length, 3);
      expect(items[0].amount, 70000.0);
      expect(items[0].icon, '🧋');
      expect(items[0].consumption, contains('SL: 2'));
      expect(items[1].amount, 25000.0);
      expect(items[1].icon, '☕');
      expect(items[2].amount, 30000.0);
      expect(items[2].icon, '🍟');
    });

    test('does not extract received cash or change as line items', () {
      final lines = [
        'TRÀ SỮA PHÚC LONG',
        '1. Trà đào cam sả    55.000',
        '2. Bánh croissant     30.000',
        'Tổng cộng: 85.000 đ',
        'Tiền đã nhận: 100.000 đ',
        'Tiền trả lại: 15.000 đ',
      ];
      final items = DartReceiptExtractor.extractLineItems(lines);
      expect(items.length, 2);
      final names = items.map((it) => it.name.toLowerCase()).toList();
      expect(names.any((n) => n.contains('nhận')), isFalse);
      expect(names.any((n) => n.contains('trả lại')), isFalse);
    });

    test('parseAll ignores Tiền đã nhận in total and line items', () {
      const rawText = '''
        TRÀ SỮA PHÚC LONG
        1. Trà đào cam sả    55.000
        2. Bánh croissant     30.000
        Tổng cộng: 85.000 đ
        Tiền đã nhận: 100.000 đ
        Tiền trả lại: 15.000 đ
      ''';
      final tx = DartReceiptExtractor.parseAll(rawText);
      expect(tx.amount, 85000.0);
      expect(tx.lineItems.length, 2);
    });

    test('parseAll ignores wifi, pass, phone, date and time metadata from line items', () {
      const rawText = '''
        THE COFFEE HOUSE
        Wifi: TheCoffeeHouse
        Pass: 12345678
        Hotline: 0912.888.999
        Ngày: 24/10/2026 15:30
        Bàn số: 05
        Thu ngân: Linh
        1. Trà đào cam sả 55.000
        2. Cà phê sữa đá 45.000
        Tổng thanh toán: 100.000
        Tiền đã nhận: 200.000
        Tiền thối lại: 100.000
        Cảm ơn và hẹn gặp lại!
      ''';
      final tx = DartReceiptExtractor.parseAll(rawText);
      expect(tx.amount, 100000.0);
      expect(tx.lineItems.length, 2);
      final names = tx.lineItems.map((it) => it.name.toLowerCase()).toList();
      for (final bad in ['wifi', 'pass', '12345678', '0912', 'hotline', 'ngày', '24/10', '15:30', 'bàn', 'thu ngân', 'tiền đã nhận', 'tiền thối', 'cảm ơn']) {
        expect(names.any((n) => n.contains(bad)), isFalse);
      }
      expect(tx.lineItems[0].amount, 55000.0);
      expect(tx.lineItems[1].amount, 45000.0);
    });

    test('parseAll handles kiotviet 42k receipt format without metadata in line items', () {
      const rawText = '''
HÓA ĐƠN BÁN HÀNG
Số HĐ: HD729652  Ngày: 22/10/2026 14:02
Khách hàng: Khách lẻ
Tên hàng hóa  Đơn giá  SL  T.Tiền
Hổ Vằn Tăm Cay Đen  3.000  1  3.000
Các Loại Ăn Vặt 3k  3.000  1  3.000
Các Loại Ăn Vặt 3k  3.000  1  3.000
Các Loại Ăn Vặt 3k  3.000  1  3.000
Các Loại Ăn Vặt 3k  3.000  1  3.000
Tăng Lực 247 chai  10.000  1  10.000
SNOW BABY Kem ốc quế  15.000  1  15.000
Tổng tiền hàng: 42.000
Chiết khấu: 0
Tổng thanh toán: 42.000
(Bốn mươi hai nghìn đồng chẵn)
KiotViet - Thaihoamart
Cảm ơn và hẹn gặp lại!
      ''';
      final tx = DartReceiptExtractor.parseAll(rawText);
      expect(tx.amount, 42000.0);
      final names = tx.lineItems.map((it) => it.name.toLowerCase()).toList();
      for (final bad in ['hđ', 'hd729652', 'ngày', '22/10', '14:02', 'khách hàng', 'khách lẻ', 'tên hàng', 'kiotviet', 'cảm ơn']) {
        expect(names.any((n) => n.contains(bad)), isFalse);
      }
      expect(tx.lineItems.isNotEmpty, isTrue);
    });
  });
}
