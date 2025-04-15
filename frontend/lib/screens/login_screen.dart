// lib/screens/login_screen.dart
import 'package:flutter/material.dart';

/// 登入頁面，提供掃描 QR 碼登入的入口
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登入'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 歡迎標題
            Text(
              '歡迎使用 QR 碼登入',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            // 簡短說明
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                '請掃描網頁上的 QR 碼以完成登入',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            
            SizedBox(height: 40),
            
            // 掃描按鈕
            ElevatedButton.icon(
              icon: Icon(Icons.qr_code_scanner),
              label: Text('掃描 QR 碼'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                // 導航到 QR 碼掃描頁面
                Navigator.of(context).pushNamed('/qr-scanner');
              },
            ),
          ],
        ),
      ),
    );
  }
}