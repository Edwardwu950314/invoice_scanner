/// 掃描前處理設定（強化穩定版）
///
/// 重點：
/// 1. 預設適合 OCR
/// 2. 加入參數安全限制
/// 3. 避免過度處理導致辨識失敗

enum DenoiseMethod { median, gaussian }

enum ThresholdMethod { adaptive, otsu }

class ScanSettings {
  final bool grayscale;
  final bool denoise;
  final DenoiseMethod denoiseMethod;
  final int denoiseRadius;
  final bool deskew;
  final bool perspective;
  final double perspectivePaddingPercent;
  final bool enhancement;
  final bool binarize;
  final ThresholdMethod thresholdMethod;
  final int adaptiveBlockSize;
  final int adaptiveOffset;
  final bool morphology;
  final int morphologyRadius;

  const ScanSettings({
    this.grayscale = true,

    // ⭐ 預設關閉降噪（避免模糊文字）
    this.denoise = false,
    this.denoiseMethod = DenoiseMethod.gaussian,
    this.denoiseRadius = 1,

    // ⭐ 先關掉容易出錯的功能
    this.deskew = false,
    this.perspective = false,
    this.perspectivePaddingPercent = 0.03,

    this.enhancement = false,

    // ⭐ OCR 必備
    this.binarize = true,

    // ⭐ 預設用 Otsu（最穩）
    this.thresholdMethod = ThresholdMethod.otsu,

    this.adaptiveBlockSize = 15,
    this.adaptiveOffset = 5,

    this.morphology = false,
    this.morphologyRadius = 1,
  });

  factory ScanSettings.defaults() => const ScanSettings(
        grayscale: true,
        denoise: true,
        denoiseMethod: DenoiseMethod.gaussian,
        denoiseRadius: 1,
        deskew: true,
        enhancement: true,
        binarize: true,
        thresholdMethod: ThresholdMethod.adaptive,
        morphology: true,
        morphologyRadius: 1,
      );

  /// ⭐ 確保所有參數安全（避免 OCR 壞掉）
  ScanSettings get safe {
    return copyWith(
      denoiseRadius: denoiseRadius.clamp(1, 2),

      adaptiveBlockSize: _ensureOdd(adaptiveBlockSize.clamp(3, 51)),

      adaptiveOffset: adaptiveOffset.clamp(1, 10),

      morphologyRadius: morphologyRadius.clamp(1, 2),
    );
  }

  /// 確保 block size 為奇數
  static int _ensureOdd(int value) {
    return value % 2 == 0 ? value + 1 : value;
  }

  bool get hasAnyProcessing {
    return grayscale ||
        denoise ||
        deskew ||
        perspective ||
        enhancement ||
        binarize ||
        morphology;
  }

  ScanSettings copyWith({
    bool? grayscale,
    bool? denoise,
    DenoiseMethod? denoiseMethod,
    int? denoiseRadius,
    bool? deskew,
    bool? perspective,
    double? perspectivePaddingPercent,
    bool? enhancement,
    bool? binarize,
    ThresholdMethod? thresholdMethod,
    int? adaptiveBlockSize,
    int? adaptiveOffset,
    bool? morphology,
    int? morphologyRadius,
  }) {
    return ScanSettings(
      grayscale: grayscale ?? this.grayscale,
      denoise: denoise ?? this.denoise,
      denoiseMethod: denoiseMethod ?? this.denoiseMethod,
      denoiseRadius: denoiseRadius ?? this.denoiseRadius,
      deskew: deskew ?? this.deskew,
      perspective: perspective ?? this.perspective,
      perspectivePaddingPercent:
          perspectivePaddingPercent ?? this.perspectivePaddingPercent,
      enhancement: enhancement ?? this.enhancement,
      binarize: binarize ?? this.binarize,
      thresholdMethod: thresholdMethod ?? this.thresholdMethod,
      adaptiveBlockSize: adaptiveBlockSize ?? this.adaptiveBlockSize,
      adaptiveOffset: adaptiveOffset ?? this.adaptiveOffset,
      morphology: morphology ?? this.morphology,
      morphologyRadius: morphologyRadius ?? this.morphologyRadius,
    );
  }
}

/// ⭐ 推薦：三種預設模式（直接用）
class ScanPresets {
  static const fast = ScanSettings(
    grayscale: true,
    binarize: false,
  );

  static const balanced = ScanSettings(
    grayscale: true,
    denoise: true,
    denoiseMethod: DenoiseMethod.gaussian,
    denoiseRadius: 1,
    binarize: true,
    thresholdMethod: ThresholdMethod.otsu,
  );

  static const ocr = ScanSettings(
    grayscale: true,
    denoise: false,
    binarize: true,
    thresholdMethod: ThresholdMethod.otsu,
    morphology: true,
    morphologyRadius: 1,
  );
}
