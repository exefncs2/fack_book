// lib/screens/qr_scanner_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// QR 碼掃描頁面，用於掃描網頁生成的 QR 碼進行登入
class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('掃描 QR 碼登入'),
      ),
      body: Column(
        children: [
          // QR 碼掃描區域
          Expanded(
            flex: 5,
            child: MobileScanner(
              // 掃描到 QR 碼時的回調
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                // 如果有掃描結果且第一個結果有值
                if (barcodes.isNotEmpty && barcodes[0].rawValue != null) {
                  final qrData = barcodes[0].rawValue!;
                  // 處理掃描到的 QR 碼數據
                  _processQrCode(context, qrData);
                }
              },
            ),
          ),
          // 掃描引導提示
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '請將攝像頭對準網頁上的 QR 碼',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 處理掃描到的 QR 碼數據
  void _processQrCode(BuildContext context, String qrData) async {
    // 防止多次掃描觸發多次處理
    if (Provider.of<AuthProvider>(context, listen: false).isLoading) {
      return;
    }
    print('掃描到的 QR 碼數據: $qrData');

    try {
      // 解析 QR 碼數據
      final decodedData = json.decode(qrData);
      final sessionId = decodedData['session_id'];
       print('解析後的 JSON 數據: $decodedData');
       print('提取的會話 ID: $sessionId');
      // 驗證數據格式
      if (sessionId == null) {
        throw Exception('QR 碼數據格式不正確');
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 顯示加載對話框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("正在驗證...")
            ],
          ),
        ),
      );

      // 嘗試使用會話 ID 登入
      final success = await authProvider.loginWithQrSession(sessionId);
      print('登入結果: $success, 錯誤: ${authProvider.error}');
      // 關閉加載對話框
      Navigator.of(context).pop();

      if (success) {
        // 登入成功，導航到主頁
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // 登入失敗，顯示錯誤
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登入失敗: ${authProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
    } catch (e) {
      // 處理 QR 碼解析錯誤
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('無效的 QR 碼: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}