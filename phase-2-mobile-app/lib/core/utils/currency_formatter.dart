import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'vi_VN',
  );

  static String format(double amount) {
    return _vndFormat.format(amount);
  }

  static String formatCompact(double amount) {
    return '${_compactFormat.format(amount)} ₫';
  }

  static double parse(String formatted) {
    final clean = formatted
        .replaceAll('₫', '')
        .replaceAll('VND', '')
        .replaceAll('đ', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(clean) ?? 0.0;
  }
}
