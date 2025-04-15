// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/post.dart';

/// API 服務類，負責與後端伺服器通信
class ApiService {
  // 伺服器 URL，初始化為空，需要在運行時設置
  String baseUrl = '';
  // 存儲身份驗證令牌
  String? token;

  /// 構造函數，可以設置初始 URL
  ApiService({String? initialUrl}) {
    if (initialUrl != null) {
      baseUrl = initialUrl;
    }
  }

  /// 更新基礎 URL
  void updateBaseUrl(String url) {
    baseUrl = url;
    print('API URL 已更新為: $url');
  }

  /// 設置認證令牌
  void setToken(String authToken) {
    token = authToken;
    print('令牌已設置');
  }

  /// 清除認證令牌
  void clearToken() {
    token = null;
    print('令牌已清除');
  }

  /// 使用掃描的 QR 碼會話 ID 進行登入
  /// 
  /// 將掃描到的會話 ID 發送到伺服器以完成登入過程
  Future<User> loginWithQrSession(String sessionId) async {
    if (baseUrl.isEmpty) {
      throw Exception('伺服器 URL 未設置');
    }
    
    print('發送登入請求到 $baseUrl/api/qr-login');
    final response = await http.post(
      Uri.parse('$baseUrl/api/qr-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'session_id': sessionId}),
    );
    
    print('收到響應，狀態碼: ${response.statusCode}');
    if (response.statusCode == 200) {
      final userData = jsonDecode(utf8.decode(response.bodyBytes));
      // 保存令牌以供後續請求使用
      if (userData['token'] != null) {
        token = userData['token'];
        print('已保存登入令牌');
      }
      return User.fromJson(userData);
    } else {
      print('登入失敗: ${response.body}');
      throw Exception('登入失敗: ${response.body}');
    }
  }

  /// 獲取當前登入用戶的信息
  Future<User> getUserInfo() async {
    _checkTokenAndUrl();
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('獲取用戶信息失敗: ${response.body}');
    }
  }

  /// 獲取所有帖子
  Future<List<Post>> getPosts() async {
    _checkTokenAndUrl();
    
    print('獲取帖子列表');
    final response = await http.get(
      Uri.parse('$baseUrl/api/posts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      print('成功獲取帖子列表');
      List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((post) => Post.fromJson(post)).toList();
    } else {
      print('獲取帖子失敗: ${response.body}');
      throw Exception('獲取帖子失敗: ${response.body}');
    }
  }

  /// 創建新帖子
  Future<Post> createPost(String content) async {
    _checkTokenAndUrl();
    
    print('創建新帖子');
    final response = await http.post(
      Uri.parse('$baseUrl/api/posts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'content': content}),
    );
    
    if (response.statusCode == 201) {
      print('帖子創建成功');
      return Post.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      print('創建帖子失敗: ${response.body}');
      throw Exception('創建帖子失敗: ${response.body}');
    }
  }

  /// 添加評論到帖子
  Future<Comment> addComment(int postId, String content) async {
    _checkTokenAndUrl();
    
    print('添加評論到帖子 $postId');
    final response = await http.post(
      Uri.parse('$baseUrl/api/posts/$postId/comments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'content': content}),
    );
    
    if (response.statusCode == 201) {
      print('評論添加成功');
      return Comment.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      print('添加評論失敗: ${response.body}');
      throw Exception('添加評論失敗: ${response.body}');
    }
  }

  /// 檢查令牌和 URL 是否設置
  void _checkTokenAndUrl() {
    if (baseUrl.isEmpty) {
      throw Exception('伺服器 URL 未設置');
    }
    if (token == null) {
      throw Exception('未登入，令牌不存在');
    }
  }
}