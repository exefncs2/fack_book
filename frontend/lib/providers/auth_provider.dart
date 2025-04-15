// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// 身份驗證提供者，管理用戶登入狀態和相關操作
class AuthProvider with ChangeNotifier {
  User? _user;  // 當前登入用戶
  bool _isLoading = false;  // 加載狀態標誌
  String? _error;  // 錯誤信息
  
  // 服務和存儲實例
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// 構造函數，接收 API 服務
  AuthProvider(this._apiService);

  // 獲取器
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  /// 使用 QR 碼會話 ID 登入
  /// 
  /// 發送會話 ID 到伺服器並處理登入結果
  Future<bool> loginWithQrSession(String sessionId) async {
    print('開始登入流程，會話 ID: $sessionId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('發送登入請求...');
      final user = await _apiService.loginWithQrSession(sessionId);
      print('收到伺服器響應: ${user.username}');
      _user = user;
      
      // 將令牌存儲到安全存儲中
      if (_apiService.token != null) {
        await _storage.write(key: 'auth_token', value: _apiService.token);
        print('令牌已保存到安全存儲');
      }
      
      // 更新狀態並通知監聽者
      _isLoading = false;
      notifyListeners();
      return true;  // 登入成功
    } catch (e) {
      print('登入失敗，錯誤詳情: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;  // 登入失敗
    }
  }

  /// 嘗試使用存儲的令牌自動登入
  /// 
  /// 檢查是否有保存的令牌，如有則自動登入
  Future<bool> tryAutoLogin() async {
    print('嘗試自動登入');
    // 從安全存儲中讀取令牌
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      print('沒有找到存儲的令牌');
      return false;  // 沒有存儲的令牌
    }

    // 設置加載狀態
    _isLoading = true;
    notifyListeners();

    try {
      // 設置 API 服務的令牌
      _apiService.setToken(token);
      
      // 使用令牌獲取用戶信息
      final user = await _apiService.getUserInfo();
      _user = user;
      
      // 更新狀態並通知監聽者
      _isLoading = false;
      notifyListeners();
      print('自動登入成功: ${user.username}');
      return true;  // 自動登入成功
    } catch (e) {
      print('自動登入失敗: $e');
      // 令牌無效，清除存儲
      await _storage.delete(key: 'auth_token');
      _apiService.clearToken();
      _isLoading = false;
      notifyListeners();
      return false;  // 自動登入失敗
    }
  }

  /// 登出當前用戶
  /// 
  /// 清除存儲的令牌和用戶信息
  Future<void> logout() async {
    print('執行登出操作');
    // 從安全存儲中刪除令牌
    await _storage.delete(key: 'auth_token');
    
    // 清除 API 服務中的令牌
    _apiService.clearToken();
    
    // 清除用戶信息並通知監聽者
    _user = null;
    notifyListeners();
    print('用戶已登出');
  }
}