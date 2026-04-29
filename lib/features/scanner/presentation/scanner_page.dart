/// 相機掃描頁面 (Camera Scanner Page)
///
/// 負責掃描發票的頁面，包含以下功能：
/// 1. 即時相機預覽 - 提供 CameraPreview Widget 顯示相機實況
/// 2. 對焦框指引 - 顯示虛擬掃描框引導使用者對準發票
/// 3. 拍照功能 - 觸發拍照並送入 OCR 處理
/// 4. 圖庫選圖 - 允許從相簿中選擇既有圖片進行掃描
/// 5. 相機權限管理 - 請求並檢查相機使用權限
///
/// 核心流程：
/// - 初始化: initState() → _initializeCamera()
/// - 使用者操作: 點擊拍照或選圖
/// - 圖片處理: ref.read(scannerProvider.notifier).processCapturedImage()
/// - 導航: 成功後自動跳轉至明細頁
///
/// 狀態管理：
/// - 使用 Riverpod 的 ref.watch(scannerProvider) 監聽掃描結果
/// - 使用 ref.listen() 在結果更新時自動導航 (已改用 post-frame callback 避免 assertion 錯誤)
library scanner_page;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';

import 'scanner_provider.dart';

/// 掃描頁面主體 Widget
/// 
/// 因為需要管控相機的生命週期（initState/dispose），所以使用 ConsumerStatefulWidget
/// ConsumerStatefulWidget = StatefulWidget + Riverpod 集成
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

/// 掃描頁面的狀態類別
/// 
/// 職責：
/// - 管理相機控制器的生命週期
/// - 監聽掃描結果並處理導航邏輯
/// - 構建 UI（相機預覽、按鈕、對焦框）
class _ScannerPageState extends ConsumerState<ScannerPage> {
  // ============ 相機相關變數 ============
  /// 用於操作原生相機（拍照、聚焦等）
  CameraController? _cameraController;
  
  /// 目前使用的相機裝置（前置或後置）
  CameraDescription? _currentCamera;
  
  /// 相機是否已初始化完成（用於檢查 CameraPreview 是否可以渲染）
  bool _isCameraInitialized = false;
  
  // bool _isFlashOn = false; // 閃光燈狀態（未來可用）
  
  /// 相機是否開啟中（使用者可以手動關閉相機以節省電力）
  bool _isCameraEnabled = false;

  @override
  void initState() {
    super.initState();
    // 進入頁面時不立即初始化相機，預設為關閉狀態
    // 使用者點擊鏡頭按鈕時再啟動
    // _initializeCamera(); // 移除自動初始化
  }

  /// 初始化後置相機
  ///
  /// 流程：
  /// 1. 列舉可用相機
  /// 2. 優先選擇後置相機（CameraLensDirection.back）
  /// 3. 建立 CameraController 並初始化
  /// 4. 狀態更新後會觸發 UI 重構，顯示相機預覽
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // ============ 選擇相機：優先後置，次選第一個 ============
      final selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      await _setupCamera(selectedCamera);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _currentCamera = camera;
    _isCameraInitialized = false;

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_isCameraEnabled) {
      if (_cameraController != null) {
        await _cameraController!.dispose();
      }
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraEnabled = false;
        });
      }
      return;
    }

    if (_currentCamera != null) {
      await _setupCamera(_currentCamera!);
    } else {
      await _initializeCamera();
    }

    if (mounted) {
      setState(() {
        _isCameraEnabled = true;
      });
    }
  }

  @override
  void dispose() {
    // ============ 頁面卸載時釋放相機資源 ============
    // 不釋放會造成相機資源洩漏，導致後續無法再使用相機
    _cameraController?.dispose();
    super.dispose();
  }

  /// 執行拍照動作
  ///
  /// 流程：
  /// 1. 檢查相機是否已初始化及未在拍照中
  /// 2. 呼叫 _cameraController.takePicture() 捕捉影像
  /// 3. 取得暫存的圖片檔案路徑
  /// 4. 將路徑傳給 Riverpod provider 進行 OCR 處理
  /// 5. provider 會更新狀態，觸發頁面導航至明細頁
  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    // ============ 防止連續重複點擊 ============
    // isTakingPicture 在拍照期間為 true，避免多個並發拍照請求
    if (_cameraController!.value.isTakingPicture) return;

    try {
      // 捕捉畫面的暫存檔案
      final XFile picture = await _cameraController!.takePicture();
      if (!mounted) return;
      // 呼叫 Provider 進行照片處理 (包含 OCR 與解析)
      ref
          .read(scannerProvider.notifier)
          .processCapturedImage(picture.path);
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 監聽 scannerProvider 的狀態，供 UI 更新使用
    final state = ref.watch(scannerProvider);
    // 監聽掃描前處理設定，以便把設定傳給相機及相簿掃描流程
    final scanSettings = ref.watch(scannerSettingsProvider);

    // 監聽 ScannerState 是否有變更，用來處理頁面跳轉或錯誤提示
    // 注意：導航與顯示 SnackBar 會改變 widget tree，直接在 listener 中同步執行
    // 可能在 build 期間導致 framework 的依賴關係未正確清理，產生
    // Failed assertion: '_dependencies.isEmpty' 的錯誤。
    // 因此改為在 frame 後執行 (post-frame) 以避免在 build 階段修改 tree。
    ref.listen<ScannerState>(scannerProvider, (previous, next) {
      if (next.result != null) {
        final res = next.result;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.push('/invoice/new', extra: res);
          ref.read(scannerProvider.notifier).reset();
        });
      } else if (next.error != null) {
        final err = next.error;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err!)));
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // 淺藍色背景，更現代的感覺
      body: state.isLoading
          ? _buildLoadingState(context)
          : Stack(
              children: [
                // 底層 1：相機即時預覽畫面
                if (_isCameraInitialized && _isCameraEnabled)
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CameraPreview(_cameraController!),
                  )
                else
                  Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: Text(
                      _isCameraEnabled ? '啟動相機中…' : '相機已關閉，請點按鏡頭按鈕重新開啟',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // 上層 2：底部的操作區塊 (包含拍照按鈕與對焦提示框)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(top: 16, bottom: 4),
                    decoration: BoxDecoration(
                      // 半透明的淺色背景，讓相機畫面若隱若現
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 依據內部元件自動調整高度
                        children: [
                          const Text(
                            '請將鏡頭對準發票文字或 QrCode',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 繪製虛擬的掃描對焦框
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 3,
                                        color: Colors.black87,
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 28,
                                        height: 3,
                                        color: Colors.black87,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            color: Colors.blue.shade400,
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 16,
                                            height: 16,
                                            color: Colors.blue.shade400,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '適度調整掃描距離以便相機對焦',
                            style: TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          // 功能按鈕區列 (相簿、快門、閃光燈)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 4.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.photo_library_rounded,
                                        color: Colors.black87,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(scannerProvider.notifier)
                                            .scanFromGallery();
                                      },
                                    ),
                                  ),
                                ),
                                // 大大的拍照快門鍵
                                InkWell(
                                  onTap: _takePicture,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.purple.shade400,
                                        width: 3,
                                      ),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 開關鏡頭按鈕
                                        IconButton(
                                          icon: Icon(
                                            _isCameraEnabled
                                                ? Icons.videocam
                                                : Icons.videocam_off,
                                            color: Colors.black87,
                                            size: 28,
                                          ),
                                          onPressed: () async {
                                            await _toggleCamera();
                                          },
                                          tooltip: _isCameraEnabled
                                              ? '關閉鏡頭'
                                              : '開啟鏡頭',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 上層 3：頂部的模擬 App Bar，放在相機上方 (透明)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '掃描對獎',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.help_outline,
                                  color: Colors.black87,
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.black87,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// 影像辨識載入時的等待動畫
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
          const SizedBox(height: 24),
          const Text(
            '影像辨識中...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('請稍候，這可能需要幾秒鐘', style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
