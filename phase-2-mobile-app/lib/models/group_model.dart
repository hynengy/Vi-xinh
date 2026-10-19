class GroupMemberModel {
  final int userId;
  final String fullName;
  final String role;
  final double paidFund;
  final double debt;
  final String? avatarUrl;

  GroupMemberModel({
    required this.userId,
    required this.fullName,
    this.role = 'member',
    this.paidFund = 0.0,
    this.debt = 0.0,
    this.avatarUrl,
  });

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      userId: map['user_id'] ?? map['id'] ?? 0,
      fullName: map['full_name'] ?? map['name'] ?? '',
      role: map['role'] ?? 'member',
      paidFund: (map['paid_fund'] as num?)?.toDouble() ?? 0.0,
      debt: (map['debt'] as num?)?.toDouble() ?? 0.0,
      avatarUrl: map['avatar_url'],
    );
  }
}

class GroupModel {
  final int id;
  final String name;
  final String? description;
  final int createdBy;
  final double balance;
  final List<GroupMemberModel> members;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.balance = 0.0,
    this.members = const [],
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    var memberList = <GroupMemberModel>[];
    if (map['members'] != null && map['members'] is List) {
      memberList = (map['members'] as List)
          .map((m) => GroupMemberModel.fromMap(m as Map<String, dynamic>))
          .toList();
    }
    return GroupModel(
      id: map['id'] ?? 1,
      name: map['name'] ?? 'Quỹ Chi Tiêu Chung',
      description: map['description'],
      createdBy: map['created_by'] ?? 1,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      members: memberList,
    );
  }
}
