/// 我的發票清單頁面 (Invoice List Page)
/// 
/// 功能說明：
/// 1. 展示所有已儲存的發票紀錄，按最新優先排序
/// 2. 統計並顯示當月/總體花費
/// 3. 支援下拉刷新（RefreshIndicator）
/// 4. 支援刪除發票（同時刪除本地和後端）
/// 5. 支援對獎功能（與中獎號碼進行比對）
/// 6. 支援點擊進入發票編輯頁
///
/// 核心特性：
/// - 使用 AsyncValue 處理非同步資料加載狀態（loading/data/error）
/// - 用 Riverpod 的 refresh() 在刪除後重新加載清單
/// - 設計模式：Card 元件 + 浮動按鈕 FAB
///
/// 導航流程：
/// - 對獎: 呼叫 check.php API，顯示獎項或「未中獎」
/// - 編輯: context.push() 進入 invoice_detail_page，返回時自動重新加載

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../services/api_service.dart';
import '../../scanner/domain/entities/invoice_entity.dart';
import 'invoice_list_provider.dart';
import '../widgets/invoice_card.dart';

/// 發票清單頁面
///
/// 使用 ConsumerWidget（而非 ConsumerStatefulWidget）因為：
/// - 不需要管理本地 Widget 狀態（如 TextEditingController）
/// - 所有狀態都由 Riverpod provider 管理
class InvoiceListPage extends ConsumerWidget {
  const InvoiceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ============ 監聽發票清單的非同步狀態 ============
    // AsyncValue 是 Riverpod 提供的類型，用於表示非同步操作的三種狀態：
    // - AsyncValue.loading: 正在加載中
    // - AsyncValue.data: 加載成功，包含實際資料
    // - AsyncValue.error: 加載失敗，包含異常訊息
    final listState = ref.watch(invoiceListProvider);

    // ============ 空監聽（技巧用途） ============
    // 確保當此頁面存在時，invoiceListProvider 不會被 GC 回收
    // （若列表頁面被卸載，provider 的資料會被清除）
    ref.listen(invoiceListProvider, (previous, next) {});

    return Scaffold(
      appBar: CustomAppBar(
        title: '我的發票',
        actions: [
          // ============ 對獎按鈕 ============
          // 點擊後呼叫後端 check.php，核對本地所有發票是否中獎
          IconButton(
            tooltip: '對獎',
            icon: const Icon(Icons.emoji_events_rounded),
            onPressed: () => _checkWinners(context),
          ),
          
          // ============ 重新加載按鈕 ============
          // 手動觸發發票清單的重新加載（對應 API 重新查詢）
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.refresh(invoiceListProvider);
            },
          )
        ],
      ),
      
      // ============ 核心內容：根據非同步狀態分別渲染 ============
      // AsyncValue.when() 是 Riverpod 提供的便利方法，自動處理三種狀態
      body: listState.when(
        // ============ 成功狀態：資料已加載 ============
        data: (invoices) {
          // 若清單為空，顯示空狀態圖示和提示文字
          if (invoices.isEmpty) {
            return _buildEmptyState(context);
          }
          
          // 有資料時，提供下拉刷新功能
          return RefreshIndicator(
            onRefresh: () async {
              // 使用者下拉時觸發重新加載
              await ref.refresh(invoiceListProvider);
            },
            child: Column(
              children: [
                // ============ 頂部卡片：總花費統計 ============
                // 計算當月或歷史的總支出金額
                _buildTotalExpenseCard(context, invoices),
                
                // ============ 中間區域：發票紀錄列表 ============
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: invoices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final inv = invoices[index];
                      return InvoiceCard(
                        invoice: inv,
                        // ============ 卡片點擊事件 ============
                        // 導航到發票編輯頁，並在返回時自動重新加載清單
                        onTap: () async {
                          await context.push('/invoice/${inv.id}', extra: inv);
                          // 返回後重新加載清單，確保顯示最新的修改
                          ref.refresh(invoiceListProvider);
                        },
                        // ============ 刪除按鈕事件 ============
                        // 觸發確認對話框，使用者確認後刪除發票
                        onDelete: () => _confirmDelete(context, ref, inv),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('載入失敗: $err')),
      ),
      
      // 右下角的快速掃描浮動按鈕，設計為延伸(Extended)格式，帶有文字與圖示
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/scan'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
          label: const Text('掃描發票', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  /// 產生於畫面完全沒有發票紀錄時的空狀態 Placeholder 介面
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 120, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            '目前沒有發票紀錄',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '點擊右下角按鈕開始掃描',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// 顯示所有發票額總計的花費卡片
  Widget _buildTotalExpenseCard(BuildContext context, List<InvoiceEntity> invoices) {
    // 計算所有發票的總金額
    final double total = invoices.fold(0.0, (sum, inv) => sum + (inv.totalAmount ?? 0.0));
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '總花費 (Total Expenses)',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${total.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  /// 呼叫後端 /check 進行對獎,顯示中獎結果
  Future<void> _checkWinners(BuildContext context) async {
    // 先抓 navigator,避免 await 後 context 失效
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ApiService.checkWinners();
      // 等一個 frame 讓 dialog push 動畫完成,避免 _debugLocked
      await Future.delayed(Duration.zero);
      if (navigator.canPop()) navigator.pop(); // 關掉 loading
      if (!context.mounted) return;

      final int count = (result['winning_count'] as int?) ?? (result['count'] as int?) ?? 0;
      final int total = (result['total_prize_amount'] as int?) ?? (result['total_prize'] as int?) ?? 0;
      final List winners = (result['winning_invoices'] as List?) ?? (result['winners'] as List?) ?? [];

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                count > 0 ? Icons.emoji_events_rounded : Icons.sentiment_neutral_rounded,
                color: count > 0 ? Colors.amber : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(count > 0 ? '恭喜中獎!' : '本次未中獎'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('中獎張數:$count 張'),
                Text('總獎金:\$$total'),
                if (winners.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('明細:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...winners.map((w) {
                    final m = Map<String, dynamic>.from(w as Map);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '• ${m['invoice_number']}  ${m['prize_type']}  \$${m['prize_amount']}',
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('關閉'),
            ),
          ],
        ),
      );
    } catch (e) {
      await Future.delayed(Duration.zero);
      if (navigator.canPop()) navigator.pop(); // 關掉 loading
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('對獎失敗'),
          content: Text('無法連線到後端伺服器:\n$e'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('確定')),
          ],
        ),
      );
    }
  }

  /// 顯示刪除確認對話框
  void _confirmDelete(BuildContext context, WidgetRef ref, InvoiceEntity inv) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('確認刪除', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('要刪除這張發票紀錄嗎？此動作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
            onPressed: () {
              // 確認刪除後，呼叫 provider 中的 deleteInvoice
              final period = ApiService.periodFromDate(inv.date ?? inv.scannedAt);
              ref.read(invoiceListProvider.notifier).deleteInvoice(
                inv.id,
                invoiceNumber: inv.invoiceNumber,
                period: period,
              );
              Navigator.pop(c);
            },
            child: Text('刪除', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
