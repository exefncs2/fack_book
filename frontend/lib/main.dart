// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'screens/login_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/home_screen.dart';

/// 應用入口點
void main() {
  // 確保 Flutter 框架已初始化
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

/// 應用主類別
class MyApp extends StatelessWidget {
  // 建立 API 服務實例並設置固定的伺服器地址
  final apiService = ApiService(initialUrl: 'http://192.168.1.112:8000');

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // 註冊所有提供者
      providers: [
        // API 服務
        Provider<ApiService>.value(value: apiService),
        // 身份驗證提供者
        ChangeNotifierProvider(create: (ctx) => AuthProvider(apiService)),
        // 貼文提供者
        ChangeNotifierProvider(create: (ctx) => PostProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'FakeBook',
        // 應用主題設置
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0.5,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 1.0,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        // 使用 InitialScreen 作為初始頁面
        home: InitialScreen(),
        // 應用頁面路由
        routes: {
          '/login': (ctx) => LoginScreen(),
          '/qr-scanner': (ctx) => QrScannerScreen(),
          '/home': (ctx) => HomeScreen(),
        },
      ),
    );
  }
}

/// 初始化頁面，處理自動登入嘗試
class InitialScreen extends StatefulWidget {
  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    // 延遲執行，確保頁面已經完全構建
    Future.microtask(() => _checkAutoLogin());
  }

  /// 檢查自動登入
  void _checkAutoLogin() async {
    // 獲取認證提供者
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // 嘗試自動登入
    final success = await authProvider.tryAutoLogin();
    
    // 根據登入結果導航到相應頁面
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 顯示載入中畫面
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',  // 如果有應用 logo 的話
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.message,
                size: 80,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'FakeBook',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('正在連接到伺服器...'),
          ],
        ),
      ),
    );
  }
}