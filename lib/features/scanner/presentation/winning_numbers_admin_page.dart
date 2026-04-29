import 'package:flutter/material.dart';

import '../../../services/api_service.dart';

class WinningNumbersAdminPage extends StatefulWidget {
  const WinningNumbersAdminPage({super.key});

  @override
  State<WinningNumbersAdminPage> createState() => _WinningNumbersAdminPageState();
}

class _WinningNumbersAdminPageState extends State<WinningNumbersAdminPage> {
  final TextEditingController _periodFilterController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _periodFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final period = _periodFilterController.text.trim();
      final result = await ApiService.fetchWinningNumbersAll(
        period: period.isEmpty ? null : period,
      );
      if (!mounted) return;
      setState(() {
        _items = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('讀取中獎號碼失敗: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditDialog({Map<String, dynamic>? item}) async {
    final periodController = TextEditingController(
      text: item == null ? '' : (item['period']?.toString() ?? ''),
    );
    final prizeTypeController = TextEditingController(
      text: item == null ? '' : (item['prize_type']?.toString() ?? ''),
    );
    final numberController = TextEditingController(
      text: item == null ? '' : (item['number']?.toString() ?? ''),
    );
    final amountController = TextEditingController(
      text: item == null ? '' : (item['prize_amount']?.toString() ?? ''),
    );

    final isEdit = item != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? '編輯中獎號碼' : '新增中獎號碼'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: periodController,
                  decoration: const InputDecoration(
                    labelText: '期別',
                    hintText: '例如 11502',
                  ),
                ),
                TextField(
                  controller: prizeTypeController,
                  decoration: const InputDecoration(
                    labelText: '獎別',
                    hintText: '例如 特別獎',
                  ),
                ),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: '號碼',
                    hintText: '例如 AB-12345678',
                  ),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '獎金',
                    hintText: '例如 2000000',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final period = periodController.text.trim();
                final prizeType = prizeTypeController.text.trim();
                final number = numberController.text.trim().toUpperCase();
                final prizeAmount = int.tryParse(amountController.text.trim());

                if (period.isEmpty ||
                    prizeType.isEmpty ||
                    number.isEmpty ||
                    prizeAmount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('請完整填寫欄位，且獎金需為數字')),
                  );
                  return;
                }

                try {
                  if (isEdit) {
                    await ApiService.updateWinningNumber(
                      id: item['id'] as int,
                      period: period,
                      prizeType: prizeType,
                      number: number,
                      prizeAmount: prizeAmount,
                    );
                  } else {
                    await ApiService.createWinningNumber(
                      period: period,
                      prizeType: prizeType,
                      number: number,
                      prizeAmount: prizeAmount,
                    );
                  }

                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  await _loadData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('儲存失敗: $e')),
                  );
                }
              },
              child: const Text('儲存'),
            ),
          ],
        );
      },
    );

    periodController.dispose();
    prizeTypeController.dispose();
    numberController.dispose();
    amountController.dispose();
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('要刪除 ${item['number']} (${item['prize_type']}) 嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteWinningNumber(item['id'] as int);
      if (!mounted) return;
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刪除失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('中獎號碼管理'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '重新整理',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _periodFilterController,
                    decoration: const InputDecoration(
                      labelText: '篩選期別',
                      hintText: '輸入例如 11502',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loadData,
                  child: const Text('查詢'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('目前沒有中獎號碼資料'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text(
                          '${item['number']}  (${item['prize_type']})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '期別: ${item['period']}   獎金: ${item['prize_amount']}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded),
                              tooltip: '編輯',
                              onPressed: () => _showEditDialog(item: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              tooltip: '刪除',
                              onPressed: () => _deleteItem(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
