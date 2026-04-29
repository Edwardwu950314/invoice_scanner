# Invoice Scanner

一個使用 Flutter、Riverpod、Google ML Kit 與本機儲存的發票掃描 App，並支援後端資料同步與中獎號碼管理。

## 專案特色

- 相機掃描與相簿匯入
- Google ML Kit 離線 OCR
- 發票號碼、日期、店家、金額自動解析
- 掃描後可手動修正欄位
- 發票資料與圖片永久儲存在裝置本機
- 可與後端 MySQL / PHP API 同步
- 支援中獎號碼管理與對獎功能

## 環境需求

- Flutter SDK 3.5 以上
- Dart SDK 3.5 以上
- Android Studio 或 Xcode（依平台選用）
- Android 模擬器或實機
- XAMPP / Apache / MySQL
- Node.js 18 以上（若要啟動 backend/server.js）

## 安裝環境

1. 安裝 Flutter。
2. 確認 Flutter 與 Dart 可用：

```bash
flutter --version
dart --version
```

3. 在專案根目錄執行依賴安裝：

```bash
flutter pub get
```

4. 若是 Android 專案，請確認已完成模擬器或實機偵錯設定。

## 啟動後端

此專案目前有兩種後端使用方式，App 主要預設串接的是 PHP API；`backend/server.js` 則是可另外啟動的 Node 版本。

### 方案 A：啟動 PHP + MySQL 後端（App 預設使用）

1. 啟動 XAMPP 的 Apache 與 MySQL。
2. 匯入資料庫結構與初始資料：

```bash
mysql -u root < backend/init.sql
```

如果你的 MySQL 沒有設定在環境變數，請改用 XAMPP 內建的 mysql 指令或 phpMyAdmin 匯入 `backend/init.sql`。

3. 確認 `backend/` 這個資料夾已透過 Apache 對外提供，路徑需能對應到：

```text
http://10.0.2.2/invoice_scanner/
```

4. 主要 API 檔案如下：

- `backend/invoices.php`：發票新增、查詢、刪除
- `backend/winning.php`：中獎號碼 CRUD
- `backend/check.php`：對獎查詢
- `backend/db.php`：資料庫連線設定

### 方案 B：啟動 Node 版 API

如果你要測試 `backend/server.js`，可以另外啟動 Node API：

```bash
cd backend
npm install
npm start
```

Node 版預設會跑在 `http://localhost:3000`，提供發票與中獎號碼的 REST API。

## 執行 App

### Android 模擬器

```bash
flutter run
```

App 預設使用 `http://10.0.2.2/invoice_scanner` 作為後端位置，這是 Android 模擬器對應到本機電腦的位址。

### 實機測試

如果要在實體手機上測試，請把 `lib/services/api_service.dart` 裡的 `baseUrl` 改成你電腦的區網 IP，例如：

```dart
static const String baseUrl = 'http://192.168.1.10/invoice_scanner';
```

然後再執行：

```bash
flutter run
```

## Flutter 權限設定

App 需要以下權限才能正常掃描與存取相簿：

- 相機
- 相簿 / 圖片存取

如果你要修改平台權限，請查看：

- Android：`android/app/src/main/AndroidManifest.xml`
- iOS：`ios/Runner/Info.plist`

## Dart 檔案簡介

以下整理專案中主要的 Dart 檔案與用途。

| 檔案 | 功能說明 |
|---|---|
| `lib/main.dart` | App 入口與路由設定，整合 Riverpod、GoRouter 與主題。 |
| `lib/features/main/presentation/main_screen.dart` | 底部導覽列外殼，負責切換主要頁面並保留分頁狀態。 |
| `lib/features/scanner/presentation/scanner_page.dart` | 相機掃描頁，提供拍照、相簿選圖與跳轉到明細頁。 |
| `lib/features/scanner/presentation/scanner_provider.dart` | 掃描流程的狀態管理，串接 OCR、圖片處理與解析。 |
| `lib/features/scanner/presentation/scanner_settings_page.dart` | 掃描前處理設定頁，可調整灰階、降噪、二值化等參數。 |
| `lib/features/scanner/presentation/winning_numbers_admin_page.dart` | 中獎號碼管理頁，可查詢、新增、修改與刪除中獎號碼。 |
| `lib/features/scanner/data/ocr_service.dart` | 包裝 Google ML Kit 文字辨識服務。 |
| `lib/features/scanner/data/invoice_parser.dart` | 將 OCR 原始文字解析成發票欄位資料。 |
| `lib/features/scanner/data/image_processing.dart` | 掃描前的影像預處理，包含灰階、降噪、校正與二值化。 |
| `lib/features/scanner/domain/scan_settings.dart` | 掃描前處理參數與預設模式定義。 |
| `lib/features/scanner/domain/entities/invoice_entity.dart` | 發票資料模型，包含 JSON 序列化與 copyWith。 |
| `lib/features/invoice_list/presentation/invoice_list_page.dart` | 發票清單頁，顯示所有已儲存發票與對獎功能。 |
| `lib/features/invoice_list/presentation/invoice_list_provider.dart` | 發票清單狀態管理，負責讀取與刪除同步。 |
| `lib/features/invoice_list/widgets/invoice_card.dart` | 清單中的單筆發票卡片元件。 |
| `lib/features/invoice_detail/presentation/invoice_detail_page.dart` | 發票明細與編輯頁，讓使用者修正 OCR 結果並儲存。 |
| `lib/features/invoice_detail/presentation/invoice_detail_provider.dart` | 發票明細的狀態與儲存流程，會同步本機與後端。 |
| `lib/shared/services/local_storage_service.dart` | 本機儲存服務，負責發票 JSON 與圖片檔案的讀寫。 |
| `lib/shared/widgets/custom_app_bar.dart` | 共用的自訂 AppBar 樣式元件。 |
| `lib/core/constants/app_constants.dart` | 全域常數，例如資料夾名稱與檔名。 |
| `lib/core/theme/app_theme.dart` | 全域主題設定，包含顏色、字體與表單樣式。 |
| `lib/core/utils/date_utils.dart` | 日期格式化工具。 |
| `lib/services/api_service.dart` | App 對後端的 HTTP 呼叫封裝，包含發票與中獎號碼 API。 |
| `test_riverpod.dart` | Riverpod 的最小測試範例檔，用於實驗或驗證 provider 寫法。 |

## 專案架構圖

```text
本專案依照「功能（Feature-first）」拆分

lib/
├── main.dart                                      # App 入口與路由總控
├── core/
│   ├── constants/
│   │   └── app_constants.dart                     # 全域常數與儲存路徑名稱
│   ├── theme/
│   │   └── app_theme.dart                         # 全域主題與元件樣式
│   └── utils/
│       └── date_utils.dart                        # 日期格式化工具
├── features/
│   ├── main/
│   │   └── presentation/
│   │       └── main_screen.dart                   # 底部導覽殼層
│   ├── scanner/
│   │   ├── data/
│   │   │   ├── image_processing.dart              # OCR 前處理管線
│   │   │   ├── invoice_parser.dart                # OCR 文字解析成欄位
│   │   │   └── ocr_service.dart                   # Google ML Kit 文字辨識
│   │   ├── domain/
│   │   │   ├── scan_settings.dart                 # 前處理參數與預設模式
│   │   │   └── entities/
│   │   │       └── invoice_entity.dart            # 發票資料模型
│   │   └── presentation/
│   │       ├── scanner_page.dart                  # 相機掃描頁
│   │       ├── scanner_provider.dart              # 掃描流程狀態管理
│   │       ├── scanner_settings_page.dart         # 掃描前處理設定頁
│   │       └── winning_numbers_admin_page.dart    # 中獎號碼管理頁
│   ├── invoice_detail/
│   │   └── presentation/
│   │       ├── invoice_detail_page.dart           # 發票明細與編輯頁
│   │       └── invoice_detail_provider.dart       # 明細頁狀態與儲存邏輯
│   └── invoice_list/
│       ├── presentation/
│       │   ├── invoice_list_page.dart             # 發票清單頁
│       │   └── invoice_list_provider.dart         # 清單資料狀態管理
│       └── widgets/
│           └── invoice_card.dart                  # 清單中的單筆發票卡片
├── shared/
│   ├── services/
│   │   └── local_storage_service.dart             # 本機 JSON / 圖片儲存
│   └── widgets/
│       └── custom_app_bar.dart                    # 共用自訂 AppBar
└── services/
    └── api_service.dart                           # 後端 API 封裝

其他檔案：
test_riverpod.dart                                  # Riverpod 最小測試範例
```

## 主要檔案功能說明

- `lib/main.dart`：建立路由、ProviderScope 與 App 主體。
- `lib/features/main/presentation/main_screen.dart`：控制底部導覽列與分頁切換。
- `lib/features/scanner/presentation/scanner_page.dart`：拍照、選圖、觸發 OCR 與跳轉明細。
- `lib/features/scanner/presentation/scanner_provider.dart`：管理掃描狀態與 OCR 流程。
- `lib/features/scanner/presentation/scanner_settings_page.dart`：調整掃描前處理參數。
- `lib/features/scanner/presentation/winning_numbers_admin_page.dart`：維護中獎號碼資料。
- `lib/features/scanner/data/ocr_service.dart`：封裝 Google ML Kit OCR。
- `lib/features/scanner/data/invoice_parser.dart`：解析發票號碼、日期、店家與金額。
- `lib/features/scanner/data/image_processing.dart`：執行影像前處理提升辨識率。
- `lib/features/scanner/domain/scan_settings.dart`：定義前處理設定與預設值。
- `lib/features/scanner/domain/entities/invoice_entity.dart`：發票資料模型與 JSON 轉換。
- `lib/features/invoice_list/presentation/invoice_list_page.dart`：顯示本機保存的發票列表。
- `lib/features/invoice_list/presentation/invoice_list_provider.dart`：讀取、排序、刪除發票資料。
- `lib/features/invoice_list/widgets/invoice_card.dart`：顯示單筆發票卡片。
- `lib/features/invoice_detail/presentation/invoice_detail_page.dart`：編輯發票欄位與儲存。
- `lib/features/invoice_detail/presentation/invoice_detail_provider.dart`：協調本機與後端儲存。
- `lib/shared/services/local_storage_service.dart`：讀寫發票 JSON 與圖片檔案。
- `lib/shared/widgets/custom_app_bar.dart`：全站共用的自訂 AppBar。
- `lib/core/constants/app_constants.dart`：集中管理固定名稱與路徑。
- `lib/core/theme/app_theme.dart`：定義全域視覺主題。
- `lib/core/utils/date_utils.dart`：統一日期格式化。
- `lib/services/api_service.dart`：呼叫後端 PHP API。
- `test_riverpod.dart`：測試 Riverpod 的示意檔。

## 完整流程圖

```text
整體流程

原始圖片
  ↓
┌──────────────────────────────────────────────┐
│ 多重前處理策略嘗試（ocr_service.dart）       │
└──────────────────────────────────────────────┘
  ↓
├→ 方案 1：安全前處理（Safe）
│   └─ [灰階] → [降噪] → [增強] → [二值化] → OCR
├→ 方案 2：增強前處理（Enhanced）
│   └─ [灰階] → [傾斜校正] → [對比增強] → [自適應二值化] → OCR
├→ 方案 3：最小化前處理（Minimal）
│   └─ [灰階] → [二值化] → OCR
└→ 方案 4：原圖（Original）
    └─ 直接 OCR

  ↓
┌──────────────────────────────────────────────┐
│ 結果評分與選擇                               │
│ （基於能否解析出發票欄位）                   │
└──────────────────────────────────────────────┘
  ↓
OCR 最佳結果
  ↓
┌──────────────────────────────────────────────┐
│ 文字正規化（ocr_service.dart）               │
│ ├─ 全形 → 半形（數字、英文）                 │
│ ├─ 特殊符號替換                               │
│ └─ 格式統一                                   │
└──────────────────────────────────────────────┘
  ↓
標準化文字
  ↓
┌──────────────────────────────────────────────┐
│ 發票欄位解析（invoice_parser.dart）          │
│ ├─ 發票號碼                                   │
│ ├─ 發票日期                                   │
│ ├─ 店家名稱                                   │
│ └─ 消費金額                                   │
└──────────────────────────────────────────────┘
  ↓
InvoiceEntity
  ↓
┌──────────────────────────────────────────────┐
│ 明細確認與修正（invoice_detail_page.dart）    │
│ ├─ 檢視 OCR 原文                               │
│ ├─ 手動修正欄位                               │
│ └─ 按下儲存                                   │
└──────────────────────────────────────────────┘
  ↓
┌──────────────────────────────────────────────┐
│ 儲存流程（invoice_detail_provider.dart）      │
│ ├─ 複製圖片到永久資料夾                       │
│ ├─ 寫入本機 JSON                              │
│ └─ 同步後端 API                               │
└──────────────────────────────────────────────┘
  ↓
本機保存完成

  ↓
┌──────────────────────────────────────────────┐
│ 發票清單更新（invoice_list_provider.dart）    │
│ ├─ 重新讀取本機資料                           │
│ ├─ 依日期排序                                 │
│ └─ 刷新清單頁面                               │
└──────────────────────────────────────────────┘

  ↓
使用者可在清單頁查看、對獎或刪除
```

## 備註

- `lib/services/api_service.dart` 目前預設連到 `http://10.0.2.2/invoice_scanner`。
- 若你改成自己的主機或手機實機，記得同步調整 API 位址。
- `backend/` 內同時保留 PHP API 與 Node API，實際採用哪一種要以你的部署方式為準。
