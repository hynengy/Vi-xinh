class BudgetModel {
  final int? id;
  final int userId;
  final String category;
  final double limitAmount;

  BudgetModel({
    this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 1,
      category: map['category'] as String? ?? 'other',
      limitAmount: (map['limit_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category': category,
      'limit_amount': limitAmount,
    };
  }
}

class FundLedgerModel {
  final int? id;
  final int groupId;
  final int userId;
  final String memberName;
  final double amount;
  final String type; // contribute | expense
  final String note;
  final String createdAt;

  FundLedgerModel({
    this.id,
    required this.groupId,
    required this.userId,
    required this.memberName,
    required this.amount,
    required this.type,
    required this.note,
    required this.createdAt,
  });

  factory FundLedgerModel.fromMap(Map<String, dynamic> map) {
    return FundLedgerModel(
      id: map['id'] as int?,
      groupId: map['group_id'] as int? ?? 0,
      userId: map['user_id'] as int? ?? 0,
      memberName: map['full_name'] as String? ?? map['member_name'] as String? ?? 'Thành viên',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: map['type'] as String? ?? 'contribute',
      note: map['note'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
