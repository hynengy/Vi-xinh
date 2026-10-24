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

  static bool isTimeStr(String s) {
    final trimmed = s.trim();
    if (RegExp(r'^(?:[01]?\d|2[0-3])[:.][0-5]\d(?::[0-5]\d)?$').hasMatch(trimmed)) return true;
    if (RegExp(r'\b(?:[01]?\d|2[0-3])[:.][0-5]\d\b').hasMatch(trimmed)) return true;
    return false;
  }

  static bool isDateStr(String s) {
    final trimmed = s.trim();
    if (RegExp(r'\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b').hasMatch(trimmed)) return true;
    if (RegExp(r'^(?:202[3-9]|2030)$').hasMatch(trimmed)) return true;
    return false;
  }

  static bool isPhoneNumberStr(String s) {
    final trimmed = s.trim();
    if (RegExp(r'\b(?:0[1-9]\d{1,2}[.\s-]?\d{3,4}[.\s-]?\d{3,4}|1[89]00[.\s-]?\d{4})\b').hasMatch(trimmed)) {
      return true;
    }
    final digits = s.replaceAll(RegExp(r'[^\d]'), '');
    if ((digits.length == 10 || digits.length == 11) && digits.startsWith('0')) return true;
    if ((digits.length == 8 || digits.length == 10) && (digits.startsWith('1800') || digits.startsWith('1900'))) return true;
    if (digits.length >= 9 && digits.startsWith('84')) return true;
    return false;
  }

  static double parseAmountStr(String s) {
    if (s.isEmpty) return 0.0;
    final trimmed = s.trim();
    if (isPhoneNumberStr(trimmed) || isTimeStr(trimmed) || isDateStr(trimmed)) return 0.0;
    if (trimmed == '2023' || trimmed == '2024' || trimmed == '2025' || trimmed == '2026' || trimmed == '2027' || trimmed == '2028' || trimmed == '2029' || trimmed == '2030') {
      return 0.0;
    }

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
    if (val < 1000 || val > 2000000000) return 0.0;
    return val;
  }

  static String? extractHotline(List<String> lines) {
    for (var line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('hotline') ||
          lower.contains('hotine') ||
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
    for (var i = 0; i < lines.take(10).length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('địa chỉ') ||
          lower.contains('dia chi') ||
          lower.contains('đ/c') ||
          lower.contains('đc:') ||
          lower.contains('dc:') ||
          lower.contains('address:')) {
        final parts = line.split(RegExp(r'[:\-]'));
        if (parts.length > 1) {
          var addr = parts.sublist(1).join(':').trim();
          if (i + 1 < lines.length && lines[i + 1].trim().length <= 15 && !lines[i + 1].toLowerCase().contains('hotline')) {
            addr = '$addr, ${lines[i + 1].trim()}';
          }
          return addr;
        }
      }
      if (lower.contains('võ văn kiệt') ||
          lower.contains('võ van kiệt') ||
          lower.contains('bình thủy') ||
          lower.contains('binh thủy') ||
          lower.contains('cần thơ') ||
          lower.contains('ung hòa') ||
          lower.contains('lê lợi') ||
          lower.contains('tràng tiền')) {
        final clean = line.replaceAll(RegExp(r'^[^a-zA-ZÀ-ỹ0-9]+'), '').trim();
        if (clean.length >= 8 && !isPhoneNumberStr(clean)) return clean;
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

    // 3. Check restaurant prefixes in top 8 lines
    for (var line in lines.take(8)) {
      var clean = line.replaceAll(RegExp(r'^[^a-zA-ZÀ-ỹ]+'), '').trim();
      clean = clean.replaceAll(RegExp(r'^[A-Z0-9\-_#*+!¿‘`“”—\.;:°§@\s]{1,4}(?=(?:tạp|tap|quán|quan|nhà|nha|tiệm|tiem|cà|ca|cafe|cửa|cua|siêu|sieu)\b)', caseSensitive: false), '').trim();
      final lower = clean.toLowerCase();
      if (merchantIgnoreKeywords.any((ig) => lower.contains(ig))) continue;
      for (var prefix in restaurantPrefixes) {
        if (lower.startsWith(prefix) || lower.contains(' $prefix ')) {
          final res = clean.replaceAll(RegExp(r"[^a-zA-Z0-9À-ỹ\s&'\-]"), '').trim();
          if (res.length >= 4) return res;
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

  static Map<String, dynamic> extractDiscount(List<String> lines) {
    final discountKeywords = [
      'giảm giá', 'giam gia', 'chiết khấu', 'chiet khau',
      'khuyến mãi', 'khuyen mai', 'voucher', 'coupon', 'discount', 'km', 'ưu đãi'
    ];

    for (var line in lines) {
      final lower = line.toLowerCase();
      if (discountKeywords.any((kw) => lower.contains(kw))) {
        final matches = RegExp(r'[\d.,]{4,}').allMatches(line);
        for (var m in matches) {
          final amt = parseAmountStr(m.group(0)!);
          if (amt >= 1000) {
            return {'amount': amt, 'note': 'Ưu đãi: -${amt.toInt()} ₫'};
          }
        }
      }
    }
    return {'amount': 0.0, 'note': null};
  }

  static Map<String, dynamic> extractTotal(List<String> lines) {
    final duePaymentKeywords = [
      'khách phải trả', 'khach phai tra',
      'cần thanh toán', 'can thanh toan',
      'phải thanh toán', 'phai thanh toan',
      'tổng thanh toán', 'tong thanh toan',
      'tổng cộng', 'tong cong',
      'tổng tiền', 'tong tien',
      'tiền thanh toán', 'tien thanh toan',
      'amount due', 'net amount', 'grand total', 'total'
    ];
    final paidKeywords = [
      'tiền đã nhận', 'tien da nhan',
      'đã nhận', 'da nhan',
      'tiền nhận', 'tien nhan',
      'số tiền nhận', 'so tien nhan',
      'nhận của khách', 'nhan cua khach',
      'tiền khách đưa', 'tien khach dua',
      'khách đưa', 'khach dua',
      'tiền đưa', 'tien dua',
      'tiền khách trả', 'tien khach tra',
      'khách trả', 'khach tra',
      'tiền mặt', 'tien mat',
      'chuyển khoản', 'chuyen khoan',
      'quẹt thẻ', 'quet the',
      'đã thanh toán', 'da thanh toan'
    ];
    final changeKeywords = [
      'tiền thừa', 'tien thua',
      'tiền thối', 'tien thoi',
      'thối lại', 'thoi lai',
      'trả lại', 'tra lai',
      'tiền trả lại', 'tien tra lai',
      'tiền thối lại', 'tien thoi lai',
      'change'
    ];
    final subtotalKeywords = [
      'tổng tiền hàng', 'tong tien hang',
      'cộng tiền hàng', 'cong tien hang',
      'tạm tính', 'tam tinh',
      'tiền hàng', 'tien hang',
      'subtotal'
    ];

    double dueAmount = 0.0;
    double paidCash = 0.0;
    double changeAmount = 0.0;
    double subtotal = 0.0;
    final discountData = extractDiscount(lines);
    final double discount = discountData['amount'] ?? 0.0;

    for (var i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('hotline') ||
          lower.contains('tel:') ||
          lower.contains('phone:') ||
          lower.contains('sđt:') ||
          lower.contains('mst:') ||
          lower.contains('stk:') ||
          lower.contains('stk')) {
        continue;
      }

      final isPaid = paidKeywords.any((kw) => lower.contains(kw));
      final isChange = changeKeywords.any((kw) => lower.contains(kw));

      // 1. Tiền thừa / tiền thối
      if (changeAmount == 0.0 && isChange) {
        final matches = RegExp(r'[\d.,]{4,}').allMatches(line);
        for (var m in matches) {
          final amt = parseAmountStr(m.group(0)!);
          if (amt >= 1000 && !isPhoneNumberStr(m.group(0)!)) {
            changeAmount = amt;
            break;
          }
        }
      }

      // 2. Tiền mặt khách đưa / Tiền đã nhận (TUYỆT ĐỐI KHÔNG GHI NHẬN LÀ TỔNG PHẢI TRẢ)
      if (paidCash == 0.0 && isPaid && !isChange) {
        final matches = RegExp(r'[\d.,]{4,}').allMatches(line);
        for (var m in matches) {
          final amt = parseAmountStr(m.group(0)!);
          if (amt >= 1000 && !isPhoneNumberStr(m.group(0)!)) {
            paidCash = amt;
            break;
          }
        }
      }

      // 3. Khách phải trả / Tổng cộng / Tổng tiền (BỎ QUA NẾU LÀ DÒNG TIỀN ĐÃ NHẬN HOẶC TIỀN THỪA)
      if (dueAmount == 0.0 && !isPaid && !isChange && duePaymentKeywords.any((kw) => lower.contains(kw))) {
        final matches = RegExp(r'[\d.,]{4,}').allMatches(line);
        for (var m in matches) {
          final amt = parseAmountStr(m.group(0)!);
          if (amt >= 1000 && !isPhoneNumberStr(m.group(0)!)) {
            dueAmount = amt;
            break;
          }
        }
        if (dueAmount == 0.0 && i + 1 < lines.length) {
          final nextLow = lines[i + 1].toLowerCase();
          if (!paidKeywords.any((kw) => nextLow.contains(kw)) && !changeKeywords.any((kw) => nextLow.contains(kw))) {
            final nextMatches = RegExp(r'[\d.,]{4,}').allMatches(lines[i + 1]);
            for (var m in nextMatches) {
              final amt = parseAmountStr(m.group(0)!);
              if (amt >= 1000 && !isPhoneNumberStr(m.group(0)!)) {
                dueAmount = amt;
                break;
              }
            }
          }
        }
      }

      // 4. Dòng tiền hàng / tạm tính
      if (subtotal == 0.0 && !isPaid && !isChange && subtotalKeywords.any((kw) => lower.contains(kw))) {
        final matches = RegExp(r'[\d.,]{4,}').allMatches(line);
        for (var m in matches) {
          final amt = parseAmountStr(m.group(0)!);
          if (amt >= 1000 && !isPhoneNumberStr(m.group(0)!)) {
            subtotal = amt;
            break;
          }
        }
      }
    }

    double finalAmount = 0.0;
    if (dueAmount > 0.0) {
      finalAmount = dueAmount;
    } else if (paidCash > 0.0 && changeAmount > 0.0 && paidCash > changeAmount) {
      // Ví dụ: Khách đưa 200k, thối 50k -> thực chi = 150k
      finalAmount = paidCash - changeAmount;
    } else if (subtotal > 0.0 && discount > 0.0) {
      finalAmount = subtotal - discount;
    } else if (subtotal > 0.0) {
      finalAmount = subtotal;
    } else if (paidCash > 0.0 && changeAmount == 0.0) {
      finalAmount = paidCash;
    }

    // Fallback: look for largest amount (ignoring phone numbers, time, and received/change lines)
    if (finalAmount == 0.0) {
      for (var line in lines) {
        final lower = line.toLowerCase();
        if (lower.contains('hotline') ||
            lower.contains('tel') ||
            lower.contains('sđt') ||
            lower.contains('phone') ||
            lower.contains('mst') ||
            paidKeywords.any((kw) => lower.contains(kw)) ||
            changeKeywords.any((kw) => lower.contains(kw))) {
          continue;
        }
        final matches = RegExp(r'[\d.,]{5,}').allMatches(line);
        for (var m in matches) {
          final amt = parseAmountStr(m.group(0)!);
          if (amt >= 5000 && amt <= 2000000000 && amt > finalAmount) {
            finalAmount = amt;
          }
        }
      }
    }

    return {
      'total': finalAmount,
      'subtotal': subtotal > 0 ? subtotal : finalAmount,
      'discount': discount
    };
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
    return '';
  }

  static List<LineItem> extractLineItems(List<String> lines) {
    final items = <LineItem>[];

    final ignoredWords = [
      'thông báo', 'kính gửi', 'hóa đơn', 'hoá đơn', 'receipt', 'invoice',
      'địa chỉ', 'thu ngân', 'cảm ơn', 'hẹn gặp lại', 'thành tiền', 'tổng cộng',
      'tổng tiền', 'total', 'thanh toán', 'hotline', 'điện thoại', 'tel', 'phone',
      'sđt', 'sdt', 'mst', 'thuế', 'wifi', 'ngày', 'date', 'giờ', 'time',
      'tiền mặt', 'tiền thừa', 'tiền thối', 'trong nhà', 'mang về', 'bàn',
      'administrator', 'đơn giá', 'don gia', 'sl',
      // Tuyệt đối không coi các dòng thanh toán / tiền đã nhận / tiền thối là món hàng:
      'tiền đã nhận', 'tien da nhan', 'đã nhận', 'da nhan', 'tiền nhận', 'tien nhan',
      'số tiền nhận', 'so tien nhan', 'nhận của khách', 'nhan cua khach',
      'tiền khách đưa', 'tien khach dua', 'khách đưa', 'khach dua', 'tiền đưa', 'tien dua',
      'tiền khách trả', 'tien khach tra', 'khách trả', 'khach tra',
      'tiền trả lại', 'tien tra lai', 'tiền thối lại', 'trả lại', 'tra lai', 'thối lại', 'thoi lai',
      'khách phải trả', 'khach phai tra', 'cần thanh toán', 'can thanh toan',
      'tổng thanh toán', 'tong thanh toan', 'tạm tính', 'tam tinh', 'chiết khấu', 'giảm giá'
    ];

    bool isSkipLine(String l) {
      final low = l.toLowerCase().trim();
      if (low.isEmpty) return true;

      // 1. Số điện thoại & Hotline
      if (low.contains('hotline') ||
          low.contains('hotine') ||
          low.contains('điện thoại') ||
          low.contains('dien thoai') ||
          low.contains('tel') ||
          low.contains('phone') ||
          low.contains('sđt') ||
          low.contains('sdt') ||
          low.contains('cskh') ||
          low.contains('liên hệ') ||
          low.contains('lien he') ||
          low.contains('zalo')) {
        return true;
      }
      if (RegExp(r'\b(?:0[1-9]\d{1,2}[.\s-]?\d{3,4}[.\s-]?\d{3,4}|1[89]00[.\s-]?\d{4})\b').hasMatch(low)) {
        return true;
      }
      if (isPhoneNumberStr(l)) return true;

      // 2. Wifi, Mật khẩu, Password
      if (low.contains('wifi') ||
          low.contains('wi-fi') ||
          low.contains('pass') ||
          low.contains('password') ||
          low.contains('mật khẩu') ||
          low.contains('mat khau') ||
          low.contains('mk:') ||
          low.contains('mk ') ||
          low.contains('pw:') ||
          low.contains('pw ')) {
        return true;
      }

      // 3. Ngày tháng, Giờ giấc
      if (low.contains('ngày') ||
          low.contains('ngay') ||
          low.contains('date') ||
          low.contains('giờ vào') ||
          low.contains('gio vao') ||
          low.contains('giờ ra') ||
          low.contains('gio ra') ||
          low.contains('in lúc') ||
          low.contains('lập lúc') ||
          low.contains('thời gian') ||
          low.contains('thoi gian')) {
        return true;
      }
      if (RegExp(r'\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b').hasMatch(low)) {
        return true;
      }
      if (RegExp(r'\b(?:gi[ờo]|time)\s*[:\s]').hasMatch(low)) {
        return true;
      }

      // 4. Số hóa đơn, Mã phiếu, Hóa đơn
      if (low.contains('số hđ') ||
          low.contains('so hd') ||
          low.contains('sđ hd') ||
          low.contains('sd hd') ||
          low.contains('mã hđ') ||
          low.contains('ma hd') ||
          low.contains('mã bill') ||
          low.contains('số bill') ||
          low.contains('số phiếu') ||
          low.contains('so phieu') ||
          low.contains('hóa đơn') ||
          low.contains('hoá đơn') ||
          low.contains('receipt') ||
          low.contains('invoice') ||
          low.contains('order no') ||
          RegExp(r'\b(?:hd\d+|bill\d+|inv[a-z0-9]+)\b', caseSensitive: false).hasMatch(low)) {
        return true;
      }

      // 5. Khách hàng, Thu ngân, Nhân viên, Bàn
      if (low.contains('khách hàng') ||
          low.contains('khach hang') ||
          low.contains('khách lẻ') ||
          low.contains('khach le') ||
          low.contains('thu ngân') ||
          low.contains('thu ngan') ||
          low.contains('cashier') ||
          low.contains('nhân viên') ||
          low.contains('nhan vien') ||
          low.contains('nv bán hàng') ||
          low.contains('nv:') ||
          low.contains('nv ') ||
          low.contains('bàn số') ||
          low.contains('ban so') ||
          low.contains('bàn:') ||
          low.contains('ban:') ||
          low.contains('phòng vip') ||
          low.contains('khu vực') ||
          low.contains('trong nhà') ||
          low.contains('mang về')) {
        return true;
      }

      // 6. Địa chỉ, MST, STK
      if (low.contains('địa chỉ') ||
          low.contains('dia chi') ||
          low.contains('đ/c') ||
          low.contains('đc:') ||
          low.contains('dc:') ||
          low.contains('address') ||
          low.contains('mst') ||
          low.contains('mã số thuế') ||
          low.contains('stk:') ||
          low.contains('stk ') ||
          low.contains('tài khoản')) {
        return true;
      }

      // 7. Header bảng
      if (low.contains('tên hàng') ||
          low.contains('hàng hóa') ||
          low.contains('hang hoa') ||
          low.contains('thực đơn') ||
          low.contains('thuc don') ||
          low.contains('mặt hàng') ||
          low.contains('t.tiền') ||
          low.contains('t.tien') ||
          (low.contains('đơn giá') && low.contains('thành tiền')) ||
          (low.contains('đơn giá') && low.contains('sl')) ||
          (low.contains('don gia') && low.contains('thanh tien'))) {
        return true;
      }

      // 8. Dòng thanh toán, tiền đã nhận, tiền thừa, tổng
      if (low.contains('tổng cộng') ||
          low.contains('tong cong') ||
          low.contains('tổng tiền') ||
          low.contains('tong tien') ||
          low.contains('tổng thanh toán') ||
          low.contains('tong thanh toan') ||
          low.contains('tạm tính') ||
          low.contains('tam tinh') ||
          low.contains('thành tiền') ||
          low.contains('thanh tien') ||
          low.contains('khách phải trả') ||
          low.contains('khach phai tra') ||
          low.contains('cần thanh toán') ||
          low.contains('chiết khấu') ||
          low.contains('chiet khau') ||
          low.contains('giảm giá') ||
          low.contains('khuyến mãi') ||
          low.contains('thuế') ||
          low.contains('vat') ||
          low.contains('tiền đã nhận') ||
          low.contains('đã nhận') ||
          low.contains('tiền nhận') ||
          low.contains('khách đưa') ||
          low.contains('tiền khách đưa') ||
          low.contains('tiền mặt') ||
          low.contains('chuyển khoản') ||
          low.contains('quẹt thẻ') ||
          low.contains('tiền thừa') ||
          low.contains('tiền thối') ||
          low.contains('trả lại') ||
          low.contains('thối lại')) {
        return true;
      }

      // 9. Lời chào, footer
      if (low.contains('cảm ơn') ||
          low.contains('cam on') ||
          low.contains('hẹn gặp lại') ||
          low.contains('chúc quý khách') ||
          low.contains('thank you') ||
          low.contains('see you again') ||
          low.contains('kiotviet') ||
          low.contains('thaihoamart') ||
          low.contains('phần mềm') ||
          low.contains('powered by')) {
        return true;
      }

      if (ignoredWords.any((w) => low.contains(w))) return true;
      return false;
    }

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (isSkipLine(line)) {
        i++;
        continue;
      }

      double? amt;
      String rawName = '';
      String? qtyStr;

      // 1. Single-line parsing
      final matches = RegExp(r'[\d.,]{4,}').allMatches(line).toList();
      if (matches.isNotEmpty) {
        final lastM = matches.last;
        final v = parseAmountStr(lastM.group(0)!);
        if (v >= 1000 && !isPhoneNumberStr(lastM.group(0)!)) {
          amt = v;
          rawName = line.substring(0, lastM.start).trim();
        }
      }

      // 2. Two-line pairing (POS KiotViet / Supermarket)
      if (amt == null && i + 1 < lines.length) {
        final nextLine = lines[i + 1];
        if (!isSkipLine(nextLine)) {
          final nextMatches = RegExp(r'[\d.,]{4,}').allMatches(nextLine).toList();
          if (nextMatches.isNotEmpty) {
            final lastM = nextMatches.last;
            final v = parseAmountStr(lastM.group(0)!);
            if (v >= 1000 && !isPhoneNumberStr(lastM.group(0)!)) {
              amt = v;
              rawName = line;
              i++; // Nhảy qua dòng giá
            }
          }
        }
      }

      if (amt != null && amt >= 1000 && rawName.isNotEmpty) {
        double qtyNum = 1.0;
        double? unitPrice;

        // Mult pattern: e.g. '2 x 35.000'
        final multMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:x|\*)\s*(\d{1,3}(?:[.,]\d{3})+|\d{4,9})', caseSensitive: false)
            .firstMatch(rawName);
        if (multMatch != null) {
          final q = double.tryParse(multMatch.group(1)!.replaceAll(',', '.')) ?? 1.0;
          final p = parseAmountStr(multMatch.group(2)!);
          if (q > 0 && p >= 100) {
            qtyNum = q;
            unitPrice = p;
            qtyStr = 'SL: ${q.truncate() == q ? q.toInt() : q}';
            rawName = rawName.replaceRange(multMatch.start, multMatch.end, '').trim();
          }
        }

        // Single quantity match
        if (qtyStr == null || qtyStr.isEmpty) {
          final qtyMatch = RegExp(r'(?:x|\*|\bSL:?|\bso luong:?)\s*(\d+(?:[.,]\d+)?)\b', caseSensitive: false)
              .firstMatch(rawName);
          if (qtyMatch != null) {
            final q = double.tryParse(qtyMatch.group(1)!.replaceAll(',', '.')) ?? 1.0;
            if (q > 0 && q < 500) {
              qtyNum = q;
              qtyStr = 'SL: ${q.truncate() == q ? q.toInt() : q}';
              rawName = rawName.replaceRange(qtyMatch.start, qtyMatch.end, '').trim();
            }
          }
        }

        // End price and quantity match: e.g. "3.000 1"
        final endPriceQtyMatch = RegExp(r'(\d{1,3}(?:[.,]\d{3})+|\d{4,9})\s+(\d+(?:[.,]\d+)?)$').firstMatch(rawName);
        if (endPriceQtyMatch != null) {
          final upCand = parseAmountStr(endPriceQtyMatch.group(1)!);
          final qCand = double.tryParse(endPriceQtyMatch.group(2)!.replaceAll(',', '.'));
          if (upCand >= 100 && qCand != null && qCand > 0 && qCand < 500) {
            unitPrice = upCand;
            qtyNum = qCand;
            qtyStr = 'SL: ${qCand.truncate() == qCand ? qCand.toInt() : qCand}';
            rawName = rawName.substring(0, endPriceQtyMatch.start).trim();
          }
        }

        unitPrice ??= (qtyNum > 0 ? (amt / qtyNum) : amt);
        if (qtyStr == null || qtyStr.isEmpty) {
          qtyStr = 'SL: ${qtyNum.truncate() == qtyNum ? qtyNum.toInt() : qtyNum}';
        }

        var cleanName = rawName
            .replaceAll(RegExp(r'^\d+[\.\-\s]+'), '')
            .replaceAll(RegExp(r"[{}[\]()=><|/\\~¬_#*+!¿‘`“”—\.;:]"), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        final lowerClean = cleanName.toLowerCase();
        final isMetadataOrPayment = [
          'hotline', 'điện thoại', 'dien thoai', 'tel', 'phone', 'sđt', 'sdt', 'cskh', 'zalo',
          'wifi', 'wi-fi', 'pass', 'password', 'mật khẩu', 'mat khau', 'mk', 'pw',
          'ngày', 'ngay', 'date', 'giờ', 'gio', 'time', 'tháng', 'năm', 'thời gian',
          'số hđ', 'so hd', 'mã hđ', 'ma hd', 'mã bill', 'số bill', 'số phiếu', 'so phieu', 'hóa đơn', 'hoá đơn',
          'khách hàng', 'khách lẻ', 'thu ngân', 'cashier', 'nhân viên', 'bàn', 'trong nhà', 'mang về',
          'địa chỉ', 'mst', 'stk', 'tài khoản', 'ngân hàng',
          'tên hàng', 'hàng hóa', 'thực đơn', 'đơn giá', 'thành tiền', 't.tiền',
          'tổng cộng', 'tổng tiền', 'tổng thanh toán', 'thanh toán', 'tiền mặt', 'chuyển khoản',
          'tiền đã nhận', 'đã nhận', 'tiền nhận', 'khách đưa', 'tiền khách đưa', 'khách trả', 'tiền khách trả',
          'tiền thừa', 'tiền thối', 'thối lại', 'trả lại', 'tiền trả lại',
          'cảm ơn', 'hẹn gặp lại', 'chúc quý khách', 'thank you', 'kiotviet', 'thaihoamart', 'phần mềm'
        ].any((pw) => lowerClean.contains(pw));
        if (isMetadataOrPayment) {
          i++;
          continue;
        }

        if (amt >= 2023 && amt <= 2030) {
          i++;
          continue;
        }

        if (cleanName.length >= 4 &&
            RegExp(r'[aeiouyáàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ]', caseSensitive: false).hasMatch(cleanName)) {
          final icon = _detectIcon(cleanName.toLowerCase());
          final existingIdx = items.indexWhere((it) => it.name.toLowerCase() == cleanName.toLowerCase());
          if (existingIdx != -1) {
            final existing = items[existingIdx];
            final newQty = existing.quantity + qtyNum;
            final newAmt = existing.amount + amt;
            items[existingIdx] = LineItem(
              name: existing.name,
              amount: newAmt,
              quantity: newQty,
              unitPrice: existing.unitPrice,
              icon: existing.icon,
              consumption: 'SL: ${newQty.truncate() == newQty ? newQty.toInt() : newQty}',
            );
          } else {
            items.add(LineItem(
              name: cleanName,
              amount: amt,
              quantity: qtyNum,
              unitPrice: unitPrice,
              icon: icon,
              consumption: qtyStr,
            ));
          }
        }
      }

      i++;
    }

    return items;
  }

  static String? extractTime(String raw) {
    for (var line in raw.split('\n')) {
      final m = RegExp(r'(?:gi[ờo]\s*(?:v[àa]o|ra|in|l[ậa]p)?|time|l[úu]c|t[ạa]i)\s*[:\s\-]*([01]?\d|2[0-3])[:.]([0-5]\d)(?:[:.]([0-5]\d))?', caseSensitive: false).firstMatch(line);
      if (m != null) {
        final hh = int.tryParse(m.group(1)!) ?? 0;
        final mm = int.tryParse(m.group(2)!) ?? 0;
        final ss = m.group(3);
        final base = '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
        return ss != null ? '$base:${ss.padLeft(2, '0')}' : base;
      }
    }
    final dtMatch = RegExp(r'\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\s+([01]?\d|2[0-3])[:.]([0-5]\d)\b').firstMatch(raw);
    if (dtMatch != null) {
      final hh = int.tryParse(dtMatch.group(1)!) ?? 0;
      final mm = int.tryParse(dtMatch.group(2)!) ?? 0;
      return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
    }
    return null;
  }

  static String? extractInvoiceNumber(List<String> lines) {
    for (var line in lines) {
      final m = RegExp(r'(?:s[ốo]\s*h[đd]|so\s*hd|m[ãa]\s*h[đd]|ma\s*hd|s[ốo]\s*phi[ếe]u|so\s*phieu|m[ãa]\s*bill|s[ốo]\s*bill|invoice\s*(?:no|num)?|receipt\s*(?:no|num)?|bill\s*(?:no|num)?|s[ốo]\s*:|so\s*:)\s*[:\s\-#]*([A-Z0-9\-_#/]{2,25})', caseSensitive: false).firstMatch(line);
      if (m != null) {
        final inv = m.group(1)!.trim();
        if (inv.length >= 3 && !inv.toLowerCase().contains('thanh') && !inv.toLowerCase().contains('toan')) {
          return inv;
        }
      }
    }
    final fullText = lines.join('\n');
    final spec = RegExp(r'\b(HD\d{4,12}|BILL\d{4,12}|INV[A-Z0-9\-_]{3,12})\b', caseSensitive: false).firstMatch(fullText);
    if (spec != null) return spec.group(1);
    return null;
  }

  static double extractVat(List<String> lines) {
    for (var line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('vat') || lower.contains('gtgt') || lower.contains('thuế')) {
        final matches = RegExp(r'(?:\d{1,3}(?:[.,\s]\d{3})+|\d{4,9})').allMatches(line);
        if (matches.isNotEmpty) {
          final v = parseAmountStr(matches.last.group(0)!);
          if (v >= 100) return v;
        }
      }
    }
    return 0.0;
  }

  static String? extractPaymentMethod(List<String> lines) {
    final lower = lines.join(' ').toLowerCase();
    if (lower.contains('chuyển khoản') || lower.contains('chuyen khoan') || lower.contains('banking')) {
      return 'Chuyển khoản';
    }
    if (lower.contains('quẹt thẻ') || lower.contains('thẻ') || lower.contains('pos') || lower.contains('visa')) {
      return 'Thẻ ngân hàng';
    }
    if (lower.contains('momo')) return 'Ví MoMo';
    if (lower.contains('zalopay')) return 'Ví ZaloPay';
    if (lower.contains('vnpay') || lower.contains('qr')) return 'Quét mã QR';
    if (lower.contains('tiền mặt') || lower.contains('tien mat')) return 'Tiền mặt';
    return null;
  }

  static TransactionModel parseAll(String rawOcr) {
    final lines = cleanText(rawOcr);
    final merchant = extractMerchant(lines);
    final date = extractDate(rawOcr);
    final timeStr = extractTime(rawOcr) ?? '12:00';
    final invoiceNo = extractInvoiceNumber(lines);
    final hotline = extractHotline(lines);
    final address = extractAddress(lines);
    final totalData = extractTotal(lines);
    final vat = extractVat(lines);
    final pttt = extractPaymentMethod(lines);
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
    if (invoiceNo != null) notesList.add('Số HĐ: $invoiceNo');
    if (timeStr != '12:00') notesList.add('Giờ: $timeStr');
    if (hotline != null) notesList.add('Hotline: $hotline');
    if (address != null) notesList.add('ĐC: $address');
    if (pttt != null) notesList.add('PTTT: $pttt');
    final double discount = totalData['discount'] ?? 0.0;
    if (discount > 0) notesList.add('Ưu đãi: -${discount.toInt()} ₫');
    if (vat > 0) notesList.add('VAT: +${vat.toInt()} ₫');
    if (items.isNotEmpty) {
      final summary = items.take(3).map((it) => '${it.name} (x${it.quantity.truncate() == it.quantity ? it.quantity.toInt() : it.quantity})').join(', ');
      notesList.add('Món: $summary${items.length > 3 ? ' (+${items.length - 3})' : ''}');
    }

    return TransactionModel(
      userId: 1,
      merchantName: merchant,
      amount: total,
      transactionDate: date,
      transactionTime: timeStr,
      category: cat,
      notes: notesList.isNotEmpty ? notesList.join(' · ') : null,
      rawOcrText: rawOcr,
      lineItems: items,
    );
  }
}
