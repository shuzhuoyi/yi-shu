class User {
  final String id;
  final String username;
  final String email;
  final String avatar;
  final bool isPremium;
  final String lastLoginTime;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.avatar = '',
    this.isPremium = false,
    this.lastLoginTime = '',
  });

  // 从JSON创建User对象
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      isPremium: json['is_premium'] ?? false,
      lastLoginTime: json['last_login_time'] ?? '',
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
      'is_premium': isPremium,
      'last_login_time': lastLoginTime,
    };
  }
} 