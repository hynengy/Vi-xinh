import '../models/transaction_model.dart';

class DartReceiptExtractor {
  static const List<String> knownChains = [
    'HIGHLANDS COFFEE',
    'THE COFFEE HOUSE',
    'PHUC LONG',
    'PHÚC LONG',
    'CIRCLE K',
    'WINMART+',
    'WINMART',
    'CO.OPMART',
    '7-ELEVEN',
    'MINISTOP',
    'GS25',
    'FAMILYMART',
    'LOTTE MART',
    'BIG C',
    'GO!',
    'KFC',
    'LOTTERIA',
    'JOLLIBEE',
    'TOCOTOCO',
    'MIXUE',
    'DING TEA',
    'STARBUCKS',
    'KICHI-KICHI',
    'GOGI HOUSE',
    'HAIDILAO',
    'PIZZA 4P',
    'PIZZA HUT',
    'THAIHOAMART',
    'SIMPLE STAY',
  ];

  static const List<String> restaurantPrefixes = [
    'nhà hàng', 'nha hang', 'quán', 'quan', 'tiệm', 'tiem',
    'cà phê', 'ca phe', 'coffee', 'cafe', 'trà sữa', 'tra sua',
    'bánh mì', 'banh mi', 'bakery', 'bếp', 'bep', 'ẩm thực', 'am thuc',
    'hải sản', 'hai san', 'cơm', 'com', 'phở', 'pho', 'bún', 'bun',
    'lẩu', 'lau', 'nướng', 'nuong', 'buffet', 'bar', 'pub', 'bistro',
    'siêu thị', 'sieu thi', 'mart', 'store', 'shop'
  ];

  static const List<String> merchantIgnoreKeywords = [
    'phiếu thanh toán', 'phieu thanh toan', 'hóa đơn gtgt', 'phiếu thu', 'hóa đơn', 'hoá đơn',
    'receipt', 'invoice', 'bill', 'vat', 'thu ngân', 'thu ngan', 'cashier',
    'nhân viên', 'nhan vien', 'bàn số', 'ban so', 'bàn:', 'ban:', 'khách hàng',
    'ngày', 'ngay', 'giờ', 'gio', 'stt', 'đơn giá', 'don gia', 'số:', 'so:', 'bảng tính tiền',
    'hotline', 'điện thoại', 'dien thoai', 'đt:', 'dt:', 'tel:', 'phone:', 'sđt', 'sdt:',
    'địa chỉ', 'dia chi', 'đ/c', 'dc:', 'đc:', 'address', 'addr',
    'mã số thuế', 'ma so thue', 'mst', 'tax code', 'wifi', 'mật khẩu', 'pass:',
    'tổng cộng', 'tong cong', 'thành tiền', 'thanh tien', 'thanh toan', 'tiền mặt',
  ];

  static List<String> cleanText(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static bool isPhoneNumberStr(String s) {
    final digits = s.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10 &&
        (digits.startsWith('03') ||
            digits.startsWith('05') ||
            digits.startsWith('07') ||
            digits.startsWith('08') ||
            digits.startsWith('09'))) {
      return true;
    }
    if (digits.length == 11 && digits.startsWith('02')) return true;
    if ((digits.length == 8 || digits.length == 10) &&
        (digits.startsWith('1800') || digits.startsWith('1900'))) {
      return true;
    }
    return false;
  }

  static double parseAmountStr(String s) {
    if (s.isEmpty) return 0.0;
    if (isPhoneNumberStr(s)) return 0.0;

    var cleaned = s.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (cleaned.isEmpty) return 0.0;

    // Handle thousand separators
    if (cleaned.contains('.') && cleaned.contains(',')) {
      if (cleaned.indexOf('.') < cleaned.indexOf(',')) {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
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

    final val = double.tryParse(cleaned) ?? 0.0;
    return val;
  }

  static String? extractHotline(List<String> lines) {
    for (var line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('hotline') ||
          lower.contains('đt:') ||
          lower.contains('dt:') ||
          lower.contains('tel:') ||
          lower.contains('sđt:') ||
          lower.contains('sdt:') ||
          lower.contains('phone:')) {
        final match = RegExp(r'\b(0[1-9]\d{1,2}[.\s-]?\d{3,4}[.\s-]?\d{3,4}|1[89]00[.\s-]?\d{4})\b')
            .firstMatch(line);
        if (match != null) return match.group(0);
      }
    }
    for (var line in lines.take(8)) {
      final clean = line.replaceAll(' ', '');
      final match = RegExp(r'\b(0[35789]\d{8}|02\d{9}|1[89]00\d{4})\b').firstMatch(clean);
      if (match != null) return match.group(0);
    }
    return null;
  }

  static String? extractAddress(List<String> lines) {
    for (var line in lines.take(8)) {
      final lower = line.toLowerCase();
      if (lower.startsWith('địa chỉ') ||
          lower.startsWith('dia chi') ||
          lower.startsWith('đ/c:') ||
          lower.startsWith('đc:') ||
          lower.startsWith('dc:') ||
          lower.startsWith('address:')) {
        final parts = line.split(RegExp(r'[:\-]'));
        if (parts.length > 1) return parts.sublist(1).join(':').trim();
      }
    }
    return null;
  }

  static String extractMerchant(List<String> lines) {
    if (lines.isEmpty) return 'Hóa đơn chưa rõ nguồn';

    // 1. Check known brand chains in top lines
    for (var line in lines.take(4)) {
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

    // 3. Check restaurant prefixes in top 6 lines
    for (var line in lines.take(6)) {
      final lower = line.toLowerCase();
      if (merchantIgnoreKeywords.any((ig) => lower.contains(ig))) continue;
      for (var prefix in restaurantPrefixes) {
        if (lower.startsWith(prefix) || lower.contains(' $prefix ')) {
          final clean = line.replaceAll(RegExp(r"[^a-zA-Z0-9À-ỹ\s&'\-]"), '').trim();
          if (clean.length >= 4) return clean;
        }
      }
    }

    // 4. Fallback: First valid non-metadata line
    for (var line in lines.take(6)) {
      final lower = line.toLowerCase();
      if (merchantIgnoreKeywords.any((ig) => lower.contains(ig))) continue;
      final clean = line.replaceAll(RegExp(r"[^a-zA-Z0-9À-ỹ\s&'\-]"), '').trim();
      if (clean.length >= 4 && !clean.contains(RegExp(r'^\d+$'))) {
        return clean;
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
      'tổng cộng', 'tong cong', 'tổng tiền', 'tong tien',
      'thành tiền', 'thanh tien', 'thanh toan', 'thanh toán',
      'total', 'grand total', 'phải thanh toán', 'phai tra', 'amount due'
    ];

    double foundAmount = 0.0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('hotline') ||
          lower.contains('tel:') ||
          lower.contains('phone:') ||
          lower.contains('sđt:') ||
          lower.contains('mst:')) {
        continue;
      }

      for (var kw in totalKeywords) {
        if (lower.contains(kw)) {
          final amountMatches = RegExp(r'[\d.,]{4,}').allMatches(line);
          for (var m in amountMatches) {
            final parsed = parseAmountStr(m.group(0)!);
            if (parsed > foundAmount && !isPhoneNumberStr(m.group(0)!)) {
              foundAmount = parsed;
            }
          }
          if (foundAmount == 0.0 && i + 1 < lines.length) {
            final nextMatches = RegExp(r'[\d.,]{4,}').allMatches(lines[i + 1]);
            for (var m in nextMatches) {
              final parsed = parseAmountStr(m.group(0)!);
              if (parsed > foundAmount && !isPhoneNumberStr(m.group(0)!)) {
                foundAmount = parsed;
              }
            }
          }
        }
      }
    }

    // Fallback: look for largest amount (ignoring phone numbers)
    if (foundAmount == 0.0) {
      for (var line in lines) {
        final lower = line.toLowerCase();
        if (lower.contains('hotline') ||
            lower.contains('tel') ||
            lower.contains('sđt') ||
            lower.contains('phone') ||
            lower.contains('mst')) {
          continue;
        }
        final matches = RegExp(r'[\d.,]{5,}').allMatches(line);
        for (var m in matches) {
          final amt = parseAmountStr(m.group(0)!);
          if (amt >= 5000 && amt <= 2000000000 && amt > foundAmount) {
            foundAmount = amt;
          }
        }
      }
    }

    return {'total': foundAmount};
  }

  static String _detectIcon(String nameLower) {
    if (nameLower.contains('cà phê') ||
        nameLower.contains('cafe') ||
        nameLower.contains('coffee') ||
        nameLower.contains('phin') ||
        nameLower.contains('freeze')) {
      return '☕';
    }
    if (nameLower.contains('trà sữa') || nameLower.contains('tra sua') || nameLower.contains('boba')) {
      return '🧋';
    }
    if (nameLower.contains('trà') || nameLower.contains('tea')) return '🍵';
    if (nameLower.contains('nước ép') || nameLower.contains('sinh tố') || nameLower.contains('nước ngọt')) {
      return '🥤';
    }
    if (nameLower.contains('bia') || nameLower.contains('beer')) return '🍺';
    if (nameLower.contains('phở') ||
        nameLower.contains('bún') ||
        nameLower.contains('mì') ||
        nameLower.contains('miến') ||
        nameLower.contains('hủ tiếu')) {
      return '🍜';
    }
    if (nameLower.contains('cơm') || nameLower.contains('xôi') || nameLower.contains('cháo')) return '🍚';
    if (nameLower.contains('bánh mì') || nameLower.contains('pizza') || nameLower.contains('burger')) {
      return '🥖';
    }
    if (nameLower.contains('lẩu')) return '🍲';
    if (nameLower.contains('nướng') || nameLower.contains('thịt') || nameLower.contains('bò') || nameLower.contains('gà')) {
      return '🥩';
    }
    if (nameLower.contains('tôm') || nameLower.contains('cua') || nameLower.contains('cá') || nameLower.contains('ốc')) {
      return '🦐';
    }
    if (nameLower.contains('rau') || nameLower.contains('salad') || nameLower.contains('nộm')) return '🥗';
    if (nameLower.contains('khoai') || nameLower.contains('snack') || nameLower.contains('nem')) return '🍟';
    if (nameLower.contains('kem') || nameLower.contains('chè') || nameLower.contains('bánh ngọt')) return '🍨';
    if (nameLower.contains('điện')) return '⚡';
    if (nameLower.contains('nước')) return '💧';
    if (nameLower.contains('wifi') || nameLower.contains('mạng')) return '🌐';
    if (nameLower.contains('phòng')) return '🏠';
    return '📦';
  }

  static List<LineItem> extractLineItems(List<String> lines) {
    final items = <LineItem>[];

    final ignoredWords = [
      'thông báo', 'kính gửi', 'hóa đơn', 'hoá đơn', 'receipt', 'invoice',
      'địa chỉ', 'thu ngân', 'cảm ơn', 'hẹn gặp lại', 'thành tiền', 'tổng cộng',
      'tổng tiền', 'total', 'thanh toán', 'hotline', 'điện thoại', 'tel', 'phone',
      'sđt', 'sdt', 'mst', 'thuế', 'wifi', 'ngày', 'date', 'giờ', 'time',
      'tiền mặt', 'tiền thừa', 'tiền thối'
    ];

    for (var line in lines) {
      final lower = line.toLowerCase().trim();
      if (ignoredWords.any((w) => lower.contains(w))) continue;
      if (RegExp(r'\b(s[đd]t|hotline|tel|phone|ng[àa]y|date)\s*[:\s]').hasMatch(lower)) continue;

      // Extract amount at or near end of line
      final matches = RegExp(r'[\d.,]{4,}').allMatches(line).toList();
      if (matches.isEmpty) continue;

      final lastMatch = matches.last;
      final amt = parseAmountStr(lastMatch.group(0)!);
      if (amt < 1000 || isPhoneNumberStr(lastMatch.group(0)!)) continue;

      var rawName = line.substring(0, lastMatch.start).trim();
      if (rawName.isEmpty) continue;

      // Check quantity (e.g. x2, 2 lon, 1.5 kg)
      String? qtyStr;
      final qtyMatch = RegExp(r'(?:x|\*|\bSL:?)\s*(\d+(?:[.,]\d+)?)\b', caseSensitive: false)
          .firstMatch(rawName);
      if (qtyMatch != null) {
        qtyStr = 'SL: ${qtyMatch.group(1)}';
        rawName = rawName.replaceRange(qtyMatch.start, qtyMatch.end, '').trim();
      }

      var cleanName = rawName
          .replaceAll(RegExp(r'^\d+[\.\-\s]+'), '') // strip STT "1.", "2 - "
          .replaceAll(RegExp(r"[{}[\]()=><|/\\~¬_#*+!¿‘`“”—\.;:]"), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleanName.length < 3) continue;

      final icon = _detectIcon(cleanName.toLowerCase());

      if (!items.any((it) => it.name.toLowerCase() == cleanName.toLowerCase())) {
        items.add(LineItem(
          name: cleanName,
          amount: amt,
          icon: icon,
          consumption: qtyStr,
        ));
      }
    }

    return items;
  }

  static TransactionModel parseAll(String rawOcr) {
    final lines = cleanText(rawOcr);
    final merchant = extractMerchant(lines);
    final date = extractDate(rawOcr);
    final hotline = extractHotline(lines);
    final address = extractAddress(lines);
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
        lower.contains('cà phê') ||
        lower.contains('nhà hàng') ||
        lower.contains('quán') ||
        lower.contains('tiệm') ||
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

    final notesList = <String>[];
    if (hotline != null) notesList.add('Hotline: $hotline');
    if (address != null) notesList.add('ĐC: $address');
    if (items.isNotEmpty) {
      final summary = items.take(3).map((it) => it.name).join(', ');
      notesList.add('Món: $summary${items.length > 3 ? ' (+${items.length - 3})' : ''}');
    }

    return TransactionModel(
      userId: 1,
      merchantName: merchant,
      amount: total,
      transactionDate: date,
      category: cat,
      notes: notesList.isNotEmpty ? notesList.join(' · ') : null,
      rawOcrText: rawOcr,
      lineItems: items,
    );
  }
}
