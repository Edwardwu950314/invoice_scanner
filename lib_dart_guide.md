# lib Dart 檔案導覽

以下整理 `lib` 目錄內每一個 Dart 檔案的職責，並挑出核心程式段落做重點說明。

## 1. `lib/main.dart`
功能：App 進入點與整體路由配置。它啟動 Riverpod 的 `ProviderScope`，並用 `GoRouter` 建立底部導覽列與發票明細頁的路由。

核心程式：`goRouterProvider` 內的 `StatefulShellRoute.indexedStack`。
這段是整個 App 的導覽中樞，決定掃描頁、清單頁、設定頁如何保留狀態切換，也定義 `/invoice/new` 和 `/invoice/:id` 的明細頁入口。

## 2. `lib/core/theme/app_theme.dart`
功能：全域視覺主題設定。它統一字體、色彩、按鈕、輸入框與 AppBar 風格，讓整個 App 的 UI 保持一致。

核心程式：`ThemeData.lightTheme` 與 `ColorScheme.fromSeed(...)`。
這裡的種子色、`surface`、`scaffoldBackgroundColor` 和各種 `ButtonTheme` 決定了全站視覺語彙，屬於 UI 的基礎層。

## 3. `lib/core/constants/app_constants.dart`
功能：集中管理固定字串與資料夾名稱，避免拼字錯誤造成儲存路徑不一致。

核心程式：`invoiceDirectoryName` 與 `invoiceJsonFileName`。
這兩個常數直接被本地儲存層使用，用來拼出 `Documents/invoices/invoices.json` 這類固定路徑。

## 4. `lib/core/utils/date_utils.dart`
功能：統一日期格式化工具。它封裝 `DateFormat`，避免畫面各處自己寫格式導致顯示不一致。

核心程式：`formatDateTime()` 與 `formatDate()`。
前者用於顯示到分鐘，後者用於清單和明細頁的簡潔日期顯示。

## 5. `lib/features/main/presentation/main_screen.dart`
功能：底部導覽列的外殼頁。它包住 `StatefulNavigationShell`，讓不同分頁切換時保留各自狀態。

核心程式：`navigationShell.goBranch(...)`。
這是分頁切換的關鍵，當使用者重複點同一頁時會回到該分頁初始狀態，這對清單頁和掃描頁都很重要。

## 6. `lib/features/scanner/presentation/scanner_page.dart`
功能：相機掃描頁。負責相機初始化、拍照、切換閃光燈、顯示掃描中的 loading，並把拍到的圖交給 provider 處理。

核心程式：`_initializeCamera()`、`_takePicture()`、`ref.listen<ScannerState>(...)`。
`_initializeCamera()` 建立 `CameraController`，`_takePicture()` 捕捉暫存影像，`ref.listen` 則在辨識完成後導頁到明細建立頁，這三段串起整個掃描流程。

## 7. `lib/features/scanner/presentation/scanner_provider.dart`
功能：掃描流程的狀態與業務邏輯控制器。它把 OCR、解析、建立 `InvoiceEntity` 串在一起，也處理相簿選圖。

核心程式：`processCapturedImage()`。
這段是掃描流程真正的核心：先 OCR，再丟給 `InvoiceParser.parse()`，最後組成 `InvoiceEntity` 並更新狀態，讓 UI 跳到明細頁。

## 8. `lib/features/scanner/data/ocr_service.dart`
功能：包裝 Google ML Kit 的 OCR 呼叫，專門負責把圖片路徑轉成文字。

核心程式：`InputImage.fromFilePath(imagePath)` 與 `_textRecognizer.processImage(...)`。
這兩行是影像辨識的實作核心，前者把檔案交給 ML Kit，後者回傳整張圖的文字內容。

## 9. `lib/features/scanner/data/invoice_parser.dart`
功能：把 OCR 原始文字解析成結構化欄位，例如發票號碼、日期、店名和金額。

核心程式：`RegExp(r'[A-Za-z]{2}-?\d{8}')`、日期 regex、金額 regex。
這個檔案的重點是「非結構化字串轉資料模型」，透過規則比對把 OCR 結果變成可儲存、可編輯的資料。

## 10. `lib/features/scanner/data/image_processing.dart`
功能：掃描前影像前處理管線。它包含灰階、降噪、傾斜校正、裁切、對比增強、二值化與形態學操作，最後輸出暫存 PNG。

核心程式：`preprocessImage()`。
這是整個前處理流程的總入口：依照 `ScanSettings` 決定要跑哪些步驟，再把結果寫回臨時檔。

重點段落：`_deskew()`、`_autoCropDocument()`、`_binarizeImage()`。
`_deskew()` 用角度搜尋估計傾斜；`_autoCropDocument()` 用二值圖找內容邊界；`_binarizeImage()` 則根據 Otsu 或 adaptive threshold 轉成黑白圖。

## 11. `lib/features/scanner/domain/scan_settings.dart`
功能：掃描前處理的設定模型與 enum 定義。它描述哪些影像處理要開啟，以及每個參數的安全預設值。

核心程式：`ScanSettings`、`DenoiseMethod`、`ThresholdMethod`、`hasAnyProcessing`。
這個檔案的價值在於把所有前處理選項集中成可傳遞的設定物件，讓 `image_processing.dart` 不需要硬編碼參數。

## 12. `lib/features/scanner/domain/entities/invoice_entity.dart`
功能：發票資料模型。它是 App 最核心的資料實體，包含掃描時間、圖片路徑、OCR 原文、解析欄位與手動修改旗標。

核心程式：`fromJson()`、`toJson()`、`copyWith()`。
`fromJson()` / `toJson()` 負責本地儲存互轉，`copyWith()` 則支援不可變資料更新，這對 Riverpod 狀態與明細編輯都很重要。

## 13. `lib/shared/services/local_storage_service.dart`
功能：本地儲存服務。它負責讀寫 `invoices.json`，並管理圖片複製到 App 專屬文件目錄。

核心程式：`_getInvoicesFile()`、`readInvoices()`、`saveInvoice()`、`copyImageToAppDirectory()`。
`_getInvoicesFile()` 決定儲存路徑，`readInvoices()` 反序列化清單，`saveInvoice()` 做新增或覆寫，`copyImageToAppDirectory()` 則把暫存圖轉成永久保存的實體檔案。

## 14. `lib/services/api_service.dart`
功能：後端 API 呼叫封裝層。它集中管理新增、查詢、刪除、對獎等 HTTP 請求，讓 UI 與 provider 不必直接處理 URL 與 JSON。

核心程式：`periodFromDate()`、`addInvoice()`、`deleteInvoiceByNumber()`、`checkWinners()`。
這裡最重要的是把發票日期轉成期別代碼，以及在本地 UUID 與後端整數 ID 不一致時，改用發票號碼同步資料。

## 15. `lib/features/invoice_detail/presentation/invoice_detail_provider.dart`
功能：明細頁的狀態控制器。它接收掃描結果，允許欄位編輯，並在儲存時同步寫入本地資料與後端。

核心程式：`updateField()` 與 `save()`。
`updateField()` 會把修改反映到 `InvoiceEntity`，`save()` 則先把圖片複製到永久資料夾，再寫入本地 JSON，最後嘗試推送後端。

## 16. `lib/features/invoice_detail/presentation/invoice_detail_page.dart`
功能：發票明細與編輯頁。它顯示發票圖片、OCR 原文與表單欄位，讓使用者修正辨識錯誤後儲存。

核心程式：儲存按鈕的 `onPressed`。
這段把文字欄位轉回 `double` / `DateTime`，呼叫 provider 更新狀態，顯示 loading dialog，最後完成儲存並回到清單頁，是使用者編輯流程的收束點。

## 17. `lib/features/invoice_list/presentation/invoice_list_provider.dart`
功能：發票清單的非同步狀態管理。它負責初始讀取、排序、重新整理與刪除本地與後端資料。

核心程式：`loadInvoices()` 與 `deleteInvoice()`。
`loadInvoices()` 讀本地資料後按日期排序，`deleteInvoice()` 先刪本地 JSON，再嘗試刪後端，這樣可維持離線可用性。

## 18. `lib/features/invoice_list/presentation/invoice_list_page.dart`
功能：發票清單頁。它呈現發票列表、總花費卡片、下拉更新、對獎功能與刪除確認對話框。

核心程式：`_buildTotalExpenseCard()`、`_checkWinners()`、`_confirmDelete()`。
總花費卡片負責即時計算支出，對獎流程負責呼叫後端並顯示結果，而刪除流程則把清單與本地資料同步更新。

## 19. `lib/features/invoice_list/widgets/invoice_card.dart`
功能：清單中的單筆發票卡片元件。它呈現店家、號碼、日期、金額與刪除按鈕，並提供點擊跳轉。

核心程式：卡片內的 `InkWell` 與右側刪除按鈕。
這個元件的重點是把資料展示和互動分離得很清楚：主卡負責進入明細，垃圾桶負責刪除。

## 20. `lib/shared/widgets/custom_app_bar.dart`
功能：共用 AppBar 元件。它把全站頂部列做成漸層、圓角與統一字重，減少每個頁面重複寫樣式。

核心程式：`flexibleSpace` 的漸層背景與 `shape` 圓角設定。
這兩段是視覺識別的主體，讓明細頁、清單頁等頁面的頂部風格一致。

## 核心流程總結

這個專案的主流程可以濃縮成：

`ScannerPage` 取得圖片 → `ScannerNotifier` 觸發 OCR → `OcrService` 取得原文 → `InvoiceParser` 解析欄位 → `InvoiceEntity` 成形 → `InvoiceDetailPage` 修正 → `LocalStorageService` 永久儲存 → `ApiService` 同步後端。

而 `ImageProcessing` 與 `ScanSettings` 則是這條流程在 OCR 前的前處理層，用來提高辨識品質。