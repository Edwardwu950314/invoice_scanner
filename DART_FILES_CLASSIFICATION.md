# Dart 檔案功能分類

## 📁 專案結構分析

### 1. **應用入口** (Entry Point)
- `lib/main.dart` - 應用程式入口點，設定路由和主題

---

## 2. **核心層** (Core Layer)
負責整個應用通用的工具、常數和主題配置

### 常數管理
- `lib/core/constants/app_constants.dart` - 應用全局常數（API URLs、超時時間等）

### UI 主題
- `lib/core/theme/app_theme.dart` - 應用主題、顏色、字體樣式

### 通用工具
- `lib/core/utils/date_utils.dart` - 日期時間轉換工具

---

## 3. **功能模塊** (Features)
使用 Clean Architecture 模式，按業務功能劃分

### 📷 掃描器功能 (`features/scanner/`)
**用途**: 發票掃描、OCR 識別、圖片處理

#### Data Layer (數據層)
- `data/ocr_service.dart` - OCR 識別服務
- `data/image_processing.dart` - 圖片處理（裁剪、旋轉、優化）
- `data/invoice_parser.dart` - 發票信息解析

#### Domain Layer (領域層)
- `domain/entities/invoice_entity.dart` - 發票實體模型
- `domain/scan_settings.dart` - 掃描設定

#### Presentation Layer (表現層)
- `presentation/scanner_page.dart` - 掃描頁面 UI
- `presentation/scanner_provider.dart` - 掃描頁面邏輯 (Riverpod)
- `presentation/scanner_settings_page.dart` - 掃描設定頁面
- `presentation/winning_numbers_admin_page.dart` - 中獎號碼管理頁面

---

### 📋 發票列表功能 (`features/invoice_list/`)
**用途**: 顯示已掃描發票列表

#### Presentation Layer
- `presentation/invoice_list_page.dart` - 發票列表頁面 UI
- `presentation/invoice_list_provider.dart` - 列表狀態管理 (Riverpod)
- `widgets/invoice_card.dart` - 發票卡片組件

---

### 🔍 發票詳情功能 (`features/invoice_detail/`)
**用途**: 顯示單張發票詳細信息

#### Presentation Layer
- `presentation/invoice_detail_page.dart` - 詳情頁面 UI
- `presentation/invoice_detail_provider.dart` - 詳情頁邏輯 (Riverpod)

---

### 🏠 主屏幕功能 (`features/main/`)
**用途**: 應用主導航和佈局

#### Presentation Layer
- `presentation/main_screen.dart` - 主屏幕框架

---

## 4. **服務層** (Services)
全局應用服務

### API 通信
- `lib/services/api_service.dart` - HTTP API 請求封裝（與後端 PHP 通信）

---

## 5. **共享層** (Shared)
所有模塊共用的服務和組件

### 共享服務
- `lib/shared/services/local_storage_service.dart` - 本地存儲（發票數據持久化）

### 共享組件
- `lib/shared/widgets/custom_app_bar.dart` - 自訂應用欄組件

---

## 📊 分類統計

| 層級 | 類別 | 檔案數 |
|------|------|--------|
| Core | 常數/主題/工具 | 3 |
| Features (Scanner) | Data/Domain/Presentation | 8 |
| Features (Invoice List) | Presentation | 3 |
| Features (Invoice Detail) | Presentation | 2 |
| Features (Main) | Presentation | 1 |
| Services | API | 1 |
| Shared | Services/Widgets | 2 |
| **總計** | | **20** |

---

## 🎯 分類依據

✅ **按層級分類**：Core → Features → Services → Shared
✅ **按功能分類**：掃描、列表、詳情、主導航
✅ **按責任分類**：Data（數據）/ Domain（業務邏輯）/ Presentation（UI）
✅ **按複用範圍**：Core（全局） → Services（應用級） → Shared（模組級） → Features（功能級）