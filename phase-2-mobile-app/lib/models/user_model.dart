class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? password;
  final String? bankName;
  final String? bankBin;
  final String? bankAccount;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.password,
    this.bankName,
    this.bankBin,
    this.bankAccount,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 1,
      username: map['username'] ?? '',
      fullName: map['full_name'] ?? 'Người dùng Ví Xinh',
      email: map['email'],
      phone: map['phone'],
      avatarUrl: map['avatar_url'],
      password: map['password'],
      bankName: map['bank_name'],
      bankBin: map['bank_bin'],
      bankAccount: map['bank_account'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'password': password,
      'bank_name': bankName,
      'bank_bin': bankBin,
      'bank_account': bankAccount,
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? password,
    String? bankName,
    String? bankBin,
    String? bankAccount,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      password: password ?? this.password,
      bankName: bankName ?? this.bankName,
      bankBin: bankBin ?? this.bankBin,
      bankAccount: bankAccount ?? this.bankAccount,
    );
  }

  bool get hasVietQr =>
      (bankBin != null && bankBin!.isNotEmpty) &&
      (bankAccount != null && bankAccount!.isNotEmpty);
}
