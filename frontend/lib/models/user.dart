// lib/models/user.dart

/// 用戶模型類，用於表示登入用戶的信息
class User {
  final String username;
  final String token;

  /// 構造函數，初始化用戶屬性
  User({
    required this.username,
    required this.token,
  });

  /// 從 JSON 創建 User 對象的工廠方法
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      token: json['token'],
    );
  }

  /// 將 User 對象轉換為 JSON 的方法
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'token': token,
    };
  }
}