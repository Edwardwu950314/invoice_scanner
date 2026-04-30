/// 發票明細與編輯頁面 (Invoice Detail Page)
/// 
/// 功能說明：
/// 1. 展示單筆發票的完整資訊（包含掃描圖片）
/// 2. 允許使用者編輯四個主要欄位（號碼、店家、金額、日期）
/// 3. 提供儲存按鈕，將修改寫入本地資料庫與後端
/// 4. 支援 OCR 原文查看（用於驗證辨識結果）
///
/// 使用場景：
/// - 掃描完成後自動跳入此頁（isNew = true），用於確認和編輯
/// - 從清單點擊發票卡片進入（isNew = false），用於檢視和修改
///
/// 狀態管理：
/// - 使用 Riverpod 的 NotifierProvider.family，因為每筆發票有不同的初始資料
/// - 本地文字框狀態（TextEditingController）與 provider 狀態分開管理

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../scanner/domain/entities/invoice_entity.dart';
import 'invoice_detail_provider.dart';

/// 發票明細編輯頁
///
/// 使用 ConsumerStatefulWidget 因為需要：
/// 1. 管理 TextEditingController（本地狀態）
/// 2. 整合 Riverpod provider（全域狀態）
class InvoiceDetailPage extends ConsumerStatefulWidget {
  /// 要編輯的發票實體（可能剛掃描完，或從清單點進來）
  final InvoiceEntity invoice;
  
  /// 是否為全新掃描的發票
  /// true: 標題為「確認發票內容」，強調確認而非編輯
  /// false: 標題為「發票明細」，強調檢視和修改
  final bool isNew;

  const InvoiceDetailPage({super.key, required this.invoice, this.isNew = false});

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

/// 發票明細頁面的狀態類別
///
/// 職責：
/// - 初始化和管理四個文字輸入框的控制器
/// - 監聽使用者的編輯輸入
/// - 協調本地狀態與 Riverpod provider 狀態
/// - 處理儲存邏輯（包括對話框、導航等）
class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  // ============ 文字輸入框控制器 ============
  /// 發票號碼輸入框（如 WR-73786487）
  late TextEditingController _numberController;
  
  /// 店家名稱輸入框
  late TextEditingController _merchantController;
  
  /// 發票金額輸入框（存儲為字串，儲存時會轉為 double）
  late TextEditingController _amountController;
  
  /// 發票日期輸入框（格式：YYYY-MM-DD）
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    // ============ 從傳入的發票實體初始化文字框 ============
    // 使用 late 延遲初始化，因為需要存取 widget.invoice
    _numberController = TextEditingController(text: widget.invoice.invoiceNumber ?? '');
    _merchantController = TextEditingController(text: widget.invoice.merchantName ?? '');
    _amountController = TextEditingController(text: widget.invoice.totalAmount?.toString() ?? '');
    _dateController = TextEditingController(
      // 使用日期工具函數格式化（通常為 YYYY-MM-DD）
      text: widget.invoice.date != null ? DateUtilsHelper.formatDate(widget.invoice.date!) : '',
    );
  }

  @override
  void dispose() {
    // ============ 頁面卸載時釋放文字框資源 ============
    // 避免記憶體洩漏
    _numberController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ============ 建立並監聽該發票的 provider ============
    // NotifierProvider.family 允許根據發票實體建立獨立的狀態容器
    // 這樣可以同時開啟多個發票編輯頁面且各自獨立
    final provider = invoiceDetailProvider(widget.invoice);
    final state = ref.watch(provider);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isNew ? '確認發票內容' : '發票明細',
        actions: [
          // ============ 右上角儲存按鈕 ============
          // 點擊後觸發複雜的儲存流程：驗證→更新→顯示加載彈窗→保存→導航
          IconButton(
            icon: const Icon(Icons.check_circle_rounded),
            tooltip: '儲存',
            onPressed: () async {
              // ============ 步驟 1：驗證與類型轉換 ============
              // 嘗試將字串轉為 double（金額欄位）
              double? amount;
              if (_amountController.text.isNotEmpty) {
                 amount = double.tryParse(_amountController.text);
              }

              // ============ 步驟 2：驗證與類型轉換 ============
              // 嘗試將字串 YYYY-MM-DD 轉為 DateTime
              DateTime? date;
              if (_dateController.text.isNotEmpty) {
                 try {
                   // 手動解析日期字串 (YYYY-MM-DD 格式)
                   final parts = _dateController.text.split('-');
                   if (parts.length == 3) {
                     date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                   }
                 } catch (_) {} // 解析失敗則保持 null
              }

              // ============ 步驟 3：批量更新 provider 狀態 ============
              // 只有變更的欄位才會被更新，其他欄位保持原值
              // (updateField 內部使用 copyWith 實現不可變更新)
              ref.read(provider.notifier).updateField(
                invoiceNumber: _numberController.text,
                merchantName: _merchantController.text,
                totalAmount: amount,
                date: date,
              );

              // ============ 步驟 4：提前獲取 navigator 和 router ============
              // 原因：await 後可能導致 context 失效或 navigator 被鎖定
              // 提前取得參照避免後續邏輯失敗
              final navigator = Navigator.of(context, rootNavigator: true);
              final router = GoRouter.of(context);

              // ============ 步驟 5：顯示加載中的全螢幕對話框 ============
              // 防止使用者在儲存期間離開頁面或重複點擊按鈕
              showDialog(
                context: context,
                barrierDismissible: false,
                useRootNavigator: true,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );

              // 6. 等待寫入本地儲存庫 + 推送後端
              try {
                await ref.read(provider.notifier).save();
              } catch (e) {
                await Future.delayed(Duration.zero);
                if (navigator.canPop()) navigator.pop();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('儲存失敗: $e')),
                );
                return;
              }

              // 7. 等下一個 frame 確保 dialog 完全 push 完才能 pop,避免 _debugLocked
              await Future.delayed(Duration.zero);

              // 8. 關閉等待彈窗,並切換回發票清單頁
              if (navigator.canPop()) navigator.pop();
              router.go('/invoices');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 重複發票警告提示
            if (state.isDuplicate)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[300]!, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '這張發票已經儲存過了',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // 如果此發票附有在本機的照片檔案路徑，顯示圖片供對照
            if (state.imageLocalPath.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxHeight: 350),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias, // 讓圖片可以完整切齊圓角
                child: Image.file(
                  File(state.imageLocalPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
            
            // 下半部的主要表單區塊
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題列
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('檢視與修正欄位', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 發票號碼輸入框
                  TextField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      labelText: '發票號碼',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 日期輸入框
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: '發票日期 (YYYY-MM-DD)',
                      prefixIcon: Icon(Icons.date_range_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 店家名稱輸入框
                  TextField(
                    controller: _merchantController,
                    decoration: const InputDecoration(
                      labelText: '店家名稱',
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 消費總額輸入框 (限定數字鍵盤)
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '消費金額',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  // 底端附上 OCR 最原始擷取的文字，讓使用者若某些欄位辨識錯誤，可從原始文字中尋找解答
                  const SizedBox(height: 32),
                  const Text('原始 OCR 辨識文字', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50], // 非常淺的灰階底色
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!)
                    ),
                    child: Text(
                      state.rawOcrText.isEmpty ? '無文字' : state.rawOcrText,
                      style: const TextStyle(height: 1.5, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
