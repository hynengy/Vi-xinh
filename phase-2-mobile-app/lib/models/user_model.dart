class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 1,
      username: map['username'] ?? '',
      fullName: map['full_name'] ?? 'Người dùng Ví Xinh',
      email: map['email'],
      phone: map['phone'],
      avatarUrl: map['avatar_url'],
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
    };
  }
}
