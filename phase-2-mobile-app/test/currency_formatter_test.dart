import 'package:flutter_test/flutter_test.dart';
import 'package:vi_xinh_mobile/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter tests', () {
    test('format returns VND string with currency symbol', () {
      final res = CurrencyFormatter.format(150000);
      expect(res.contains('150.000'), isTrue);
      expect(res.contains('₫'), isTrue);
    });

    test('format handles zero and large numbers', () {
      final zero = CurrencyFormatter.format(0);
      expect(zero.contains('0'), isTrue);

      final large = CurrencyFormatter.format(50662000);
      expect(large.contains('50.662.000'), isTrue);
    });

    test('parse extracts raw number correctly', () {
      expect(CurrencyFormatter.parse('150.000 ₫'), 150000.0);
      expect(CurrencyFormatter.parse('42.000 VND'), 42000.0);
      expect(CurrencyFormatter.parse('50.662.000'), 50662000.0);
      expect(CurrencyFormatter.parse(''), 0.0);
    });
  });
}
