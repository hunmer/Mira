class UserModel {
  final String id;
  final String phone;
  final String? nickname;
  final String? avatar;
  final String? password;

  UserModel({
    required this.id,
    required this.phone,
    this.nickname,
    this.avatar,
    this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phone: json['phone'],
      nickname: json['nickname'],
      avatar: json['avatar'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'avatar': avatar,
      'password': password,
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? nickname,
    String? avatar,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      password: password ?? this.password,
    );
  }
}
