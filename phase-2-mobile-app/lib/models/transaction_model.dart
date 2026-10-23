class LineItem {
  final String name;
  final double amount;
  final String? consumption;
  final String? icon;

  LineItem({
    required this.name,
    required this.amount,
    this.consumption,
    this.icon,
  });

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      name: map['name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      consumption: map['consumption'],
      icon: map['icon'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'consumption': consumption,
      'icon': icon,
    };
  }
}

class TransactionModel {
  final int? id;
  final int userId;
  final String merchantName;
  final double amount;
  final String type; // 'expense' or 'income'
  final String transactionDate;
  final String? transactionTime;
  final int? groupId;
  final String category;
  final String? receiptImagePath;
  final String? rawOcrText;
  final String? notes;
  final List<LineItem> lineItems;

  TransactionModel({
    this.id,
    required this.userId,
    required this.merchantName,
    required this.amount,
    this.type = 'expense',
    required this.transactionDate,
    this.transactionTime = '00:00',
    this.groupId,
    this.category = 'other',
    this.receiptImagePath,
    this.rawOcrText,
    this.notes,
    this.lineItems = const [],
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    var items = <LineItem>[];
    if (map['items'] != null && map['items'] is List) {
      items = (map['items'] as List)
          .map((item) => LineItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    return TransactionModel(
      id: map['id'],
      userId: map['user_id'] ?? 1,
      merchantName: map['merchant_name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'expense',
      transactionDate: map['transaction_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
      transactionTime: map['transaction_time'] ?? '00:00',
      groupId: map['group_id'],
      category: map['category'] ?? 'other',
      receiptImagePath: map['receipt_image_path'],
      rawOcrText: map['raw_ocr_text'],
      notes: map['notes'],
      lineItems: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'merchant_name': merchantName,
      'amount': amount,
      'type': type,
      'transaction_date': transactionDate,
      'transaction_time': transactionTime,
      'group_id': groupId,
      'category': category,
      'receipt_image_path': receiptImagePath,
      'raw_ocr_text': rawOcrText,
      'notes': notes,
    };
  }
}
