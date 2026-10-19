import '../models/transaction_model.dart';

class DartReceiptExtractor {
  static const List<String> knownChains = [
    'HIGHLANDS COFFEE',
    'CIRCLE K',
    'WINMART',
    'PHUC LONG',
    'THE COFFEE HOUSE',
    'LOTTERIA',
    'KFC',
    'GS25',
    '7-ELEVEN',
    'FAMILYMART',
    'MINISTOP',
    'STARBUCKS',
    'TOCOTOCO',
    'DING TEA',
    'MIXUE',
    'CHICHI',
  ];

  static List<String> cleanText(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static double parseAmountStr(String s) {
    if (s.isEmpty) return 0.0;
    var cleaned = s.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (cleaned.isEmpty) return 0.0;

    // Handle thousand separators
    if (cleaned.contains('.') && cleaned.contains(',')) {
      if (cleaned.indexOf('.') < cleaned.indexOf(',')) {
        // European style 1.250,50
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // US style 1,250.50
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        cleaned = cleaned.replaceAll('.', '');
      }
    } else if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        cleaned = cleaned.replaceAll(',', '');
      }
    }

    return double.tryParse(cleaned) ?? 0.0;
  }

  static String extractMerchant(List<String> lines) {
    if (lines.isEmpty) return 'Hóa đơn chưa rõ nguồn';

    // 1. Check known brand chains
    for (var line in lines.take(6)) {
      final upper = line.toUpperCase();
      for (var chain in knownChains) {
        if (upper.contains(chain)) {
          return chain;
        }
      }
    }

    // 2. Check room rent notices
    final fullText = lines.join(' ').toLowerCase();
    if (fullText.contains('tiền trọ') ||
        fullText.contains('phòng trọ') ||
        fullText.contains('nhà trọ') ||
        fullText.contains('thông báo tiền trọ')) {
      final roomMatch = RegExp(r'phòng\s*[:\s]*(\d+[a-zA-Z]?)', caseSensitive: false)
          .firstMatch(fullText);
      if (roomMatch != null) {
        return 'Tiền trọ Phòng ${roomMatch.group(1)}';
      }
      return 'Hóa đơn tiền phòng';
    }

    // 3. Fallback to first non-generic top line
    for (var line in lines.take(4)) {
      final lower = line.toLowerCase();
      if (!lower.contains('hóa đơn') &&
          !lower.contains('hoa don') &&
          !lower.contains('receipt') &&
          !lower.contains('phiếu thanh toán') &&
          line.length >= 3) {
        return line;
      }
    }

    return lines.first;
  }

  static String extractDate(String fullText) {
    // Standard format DD/MM/YYYY or DD-MM-YYYY
    final dmyMatch = RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})\b')
        .firstMatch(fullText);
    if (dmyMatch != null) {
      final d = dmyMatch.group(1)!.padLeft(2, '0');
      final m = dmyMatch.group(2)!.padLeft(2, '0');
      final y = dmyMatch.group(3)!;
      return '$y-$m-$d';
    }

    // Vietnamese word format: Ngày DD tháng MM năm YYYY
    final vnMatch = RegExp(r'ngày\s*(\d{1,2})\s*tháng\s*(\d{1,2})\s*năm\s*(\d{4})',
            caseSensitive: false)
        .firstMatch(fullText);
    if (vnMatch != null) {
      final d = vnMatch.group(1)!.padLeft(2, '0');
      final m = vnMatch.group(2)!.padLeft(2, '0');
      final y = vnMatch.group(3)!;
      return '$y-$m-$d';
    }

    // Room rent format: Tháng MM/YYYY
    final monthMatch = RegExp(r'tháng\s*(\d{1,2})[\/\-](\d{4})', caseSensitive: false)
        .firstMatch(fullText);
    if (monthMatch != null) {
      final m = monthMatch.group(1)!.padLeft(2, '0');
      final y = monthMatch.group(2)!;
      return '$y-$m-01';
    }

    return DateTime.now().toIso8601String().substring(0, 10);
  }

  static Map<String, dynamic> extractTotal(List<String> lines) {
    final totalKeywords = [
      'tổng cộng',
      'tong cong',
      'tổng tiền',
      'tong tien',
      'thành tiền',
      'thanh tien',
      'thanh toan',
      'thanh toán',
      'total',
      'grand total',
      'phải thanh toán',
      'phai tra',
    ];

    double foundAmount = 0.0;

    // Search for keywords
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      for (var kw in totalKeywords) {
        if (lower.contains(kw)) {
          // Look on same line
          final amountMatches = RegExp(r'[\d.,]{4,}').allMatches(line);
          if (amountMatches.isNotEmpty) {
            final parsed = parseAmountStr(amountMatches.last.group(0)!);
            if (parsed > foundAmount) foundAmount = parsed;
          } else if (i + 1 < lines.length) {
            // Look on next line
            final nextMatches = RegExp(r'[\d.,]{4,}').allMatches(lines[i + 1]);
            if (nextMatches.isNotEmpty) {
              final parsed = parseAmountStr(nextMatches.first.group(0)!);
              if (parsed > foundAmount) foundAmount = parsed;
            }
          }
        }
      }
    }

    // If still 0, look for largest reasonable VND amount
    if (foundAmount == 0.0) {
      for (var line in lines) {
        final matches = RegExp(r'[\d.,]{5,}').allMatches(line);
        for (var m in matches) {
          final amt = parseAmountStr(m.group(0)!);
          if (amt >= 5000 && amt <= 100000000 && amt > foundAmount) {
            foundAmount = amt;
          }
        }
      }
    }

    return {'total': foundAmount};
  }

  static List<LineItem> extractLineItems(List<String> lines) {
    final items = <LineItem>[];

    final servicePatterns = [
      {'keyword': 'tiền phòng', 'name': 'Tiền thuê phòng', 'icon': '🏠'},
      {'keyword': 'tiền điện', 'name': 'Tiền điện', 'icon': '⚡'},
      {'keyword': 'điện', 'name': 'Tiền điện sinh hoạt', 'icon': '⚡'},
      {'keyword': 'tiền nước', 'name': 'Tiền nước', 'icon': '💧'},
      {'keyword': 'nước', 'name': 'Tiền nước sinh hoạt', 'icon': '💧'},
      {'keyword': 'mạng', 'name': 'Internet & Wifi', 'icon': '🌐'},
      {'keyword': 'internet', 'name': 'Internet & Wifi', 'icon': '🌐'},
      {'keyword': 'wifi', 'name': 'Internet & Wifi', 'icon': '🌐'},
      {'keyword': 'vệ sinh', 'name': 'Phí vệ sinh môi trường', 'icon': '🧹'},
      {'keyword': 'dịch vụ', 'name': 'Dịch vụ chung', 'icon': '🏢'},
      {'keyword': 'gửi xe', 'name': 'Phí gửi xe', 'icon': '🛵'},
      {'keyword': 'xe máy', 'name': 'Phí gửi xe máy', 'icon': '🛵'},
    ];

    for (var line in lines) {
      final lower = line.toLowerCase();
      for (var sp in servicePatterns) {
        if (lower.contains(sp['keyword']!)) {
          final amountMatches = RegExp(r'[\d.,]{4,}').allMatches(line);
          if (amountMatches.isNotEmpty) {
            final amt = parseAmountStr(amountMatches.last.group(0)!);
            if (amt > 0 && !items.any((it) => it.name == sp['name'])) {
              items.add(LineItem(
                name: sp['name']!,
                amount: amt,
                icon: sp['icon'],
                consumption: line.contains('kw') || line.contains('khối') ? line : 'Trọn gói',
              ));
            }
          }
        }
      }
    }

    return items;
  }

  static TransactionModel parseAll(String rawOcr) {
    final lines = cleanText(rawOcr);
    final merchant = extractMerchant(lines);
    final date = extractDate(rawOcr);
    final totalData = extractTotal(lines);
    final items = extractLineItems(lines);

    double total = totalData['total'] ?? 0.0;
    if (total == 0.0 && items.isNotEmpty) {
      total = items.fold(0.0, (sum, it) => sum + it.amount);
    }

    // Determine category
    String cat = 'other';
    final lower = merchant.toLowerCase();
    if (lower.contains('trọ') || lower.contains('phòng')) {
      cat = 'bills';
    } else if (lower.contains('coffee') ||
        lower.contains('kfc') ||
        lower.contains('lotteria') ||
        lower.contains('phúc long') ||
        lower.contains('highlands')) {
      cat = 'food';
    } else if (lower.contains('winmart') ||
        lower.contains('circle k') ||
        lower.contains('gs25') ||
        lower.contains('7-eleven')) {
      cat = 'shopping';
    }

    return TransactionModel(
      userId: 1,
      merchantName: merchant,
      amount: total,
      transactionDate: date,
      category: cat,
      rawOcrText: rawOcr,
      lineItems: items,
    );
  }
}
