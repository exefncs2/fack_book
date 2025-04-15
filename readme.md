# Fack_Book - FastAPI與Flutter結合的留言評論應用

## 專案簡介
Fack_Book是一個集成QR碼登入與留言評論功能的移動應用程式技術展示。本專案使用FastAPI作為後端服務，Flutter作為前端界面，展示了現代化應用程式的開發方法與技術整合。

## 功能特點
- QR碼掃描登入系統
- 即時留言與評論功能
- 簡潔直觀的使用者界面
- 跨平台支援（iOS與Android）

## 安裝指南

### 後端設置 (FastAPI)
1. 進入backend目錄
```
cd backend
```

2. 安裝所需套件
```
pip install -r requirements.txt
```

3. 啟動FastAPI服務
```
python main.py
```
服務啟動後，預設將運行在 `http://localhost:8000`

### 前端設置 (Flutter)
1. 確保Flutter環境已正確安裝
   - 如需Flutter安裝指南，可[參考此教學](https://ithelp.ithome.com.tw/m/articles/10216013)
   - 安裝完成後，執行以下命令確認環境設置：
   ```
   flutter doctor
   ```

2. 進入frontend目錄
```
cd frontend
```

3. 安裝Flutter依賴包
```
flutter pub get
```

4. 運行應用程式
```
flutter run
```

## 使用方法
1. 確保後端FastAPI服務正在運行
2. 在Android或iOS裝置上啟動Flutter應用程式
   - 請確保您的手機已開啟USB偵錯模式並連接到電腦
3. 開啟應用程式後，使用內建的QR碼掃描功能掃描範例登入QR碼
4. 登入後即可使用留言評論功能

## 技術架構
- **後端**: FastAPI (Python)
- **前端**: Flutter (Dart)
- **通訊**: RESTful API
- **身份驗證**: QR碼認證

