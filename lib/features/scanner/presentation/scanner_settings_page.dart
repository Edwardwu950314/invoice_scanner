import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/scan_settings.dart';
import 'scanner_provider.dart';

class ScannerSettingsPage extends ConsumerWidget {
  const ScannerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(scannerSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('掃描前處理設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '請手動選擇想要的影像前處理步驟。',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: settings.grayscale,
            title: const Text('灰階轉換'),
            subtitle: const Text('將 RGB 轉為灰階，減少 OCR 前的雜訊。'),
            onChanged: (value) => ref
                .read(scannerSettingsProvider.notifier)
                .updateGrayscale(value),
          ),
          SwitchListTile(
            value: settings.denoise,
            title: const Text('降噪'),
            subtitle: const Text('使用中值或高斯濾波去除背景雜訊。'),
            onChanged: (value) =>
                ref.read(scannerSettingsProvider.notifier).updateDenoise(value),
          ),
          if (settings.denoise)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '降噪方法',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  RadioListTile<DenoiseMethod>(
                    value: DenoiseMethod.median,
                    groupValue: settings.denoiseMethod,
                    title: const Text('中值濾波'),
                    onChanged: (value) => value != null
                        ? ref
                              .read(scannerSettingsProvider.notifier)
                              .updateDenoiseMethod(value)
                        : null,
                  ),
                  RadioListTile<DenoiseMethod>(
                    value: DenoiseMethod.gaussian,
                    groupValue: settings.denoiseMethod,
                    title: const Text('高斯濾波'),
                    onChanged: (value) => value != null
                        ? ref
                              .read(scannerSettingsProvider.notifier)
                              .updateDenoiseMethod(value)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '降噪強度：${settings.denoiseRadius}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: settings.denoiseRadius.toDouble(),
                    min: 1,
                    max: 4,
                    divisions: 3,
                    label: settings.denoiseRadius.toString(),
                    onChanged: (value) => ref
                        .read(scannerSettingsProvider.notifier)
                        .updateDenoiseRadius(value.round()),
                  ),
                ],
              ),
            ),
          SwitchListTile(
            value: settings.deskew,
            title: const Text('傾斜校正'),
            subtitle: const Text('偵測文字傾斜角度並自動校正。'),
            onChanged: (value) =>
                ref.read(scannerSettingsProvider.notifier).updateDeskew(value),
          ),
          SwitchListTile(
            value: settings.perspective,
            title: const Text('透視變換'),
            subtitle: const Text('偵測發票邊界並裁切回矩形視角。'),
            onChanged: (value) => ref
                .read(scannerSettingsProvider.notifier)
                .updatePerspective(value),
          ),
          if (settings.perspective)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '裁切保留邊界：${(settings.perspectivePaddingPercent * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    min: 0,
                    max: 10,
                    divisions: 10,
                    value: settings.perspectivePaddingPercent * 100,
                    label:
                        '${(settings.perspectivePaddingPercent * 100).round()}%',
                    onChanged: (value) => ref
                        .read(scannerSettingsProvider.notifier)
                        .updatePerspectivePaddingPercent(value / 100),
                  ),
                ],
              ),
            ),
          SwitchListTile(
            value: settings.enhancement,
            title: const Text('影像增強'),
            subtitle: const Text('使用對比度增強提升文字可讀性。'),
            onChanged: (value) => ref
                .read(scannerSettingsProvider.notifier)
                .updateEnhancement(value),
          ),
          SwitchListTile(
            value: settings.binarize,
            title: const Text('二值化'),
            subtitle: const Text('使用自適應閾值或 Otsu 將影像轉為黑白。'),
            onChanged: (value) => ref
                .read(scannerSettingsProvider.notifier)
                .updateBinarize(value),
          ),
          if (settings.binarize)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '二值化方法',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  RadioListTile<ThresholdMethod>(
                    value: ThresholdMethod.adaptive,
                    groupValue: settings.thresholdMethod,
                    title: const Text('自適應閾值'),
                    subtitle: const Text('更適合光線不均的手機拍攝場景。'),
                    onChanged: (value) => value != null
                        ? ref
                              .read(scannerSettingsProvider.notifier)
                              .updateThresholdMethod(value)
                        : null,
                  ),
                  RadioListTile<ThresholdMethod>(
                    value: ThresholdMethod.otsu,
                    groupValue: settings.thresholdMethod,
                    title: const Text('Otsu 方法'),
                    subtitle: const Text('適合背景與文字對比穩定的影像。'),
                    onChanged: (value) => value != null
                        ? ref
                              .read(scannerSettingsProvider.notifier)
                              .updateThresholdMethod(value)
                        : null,
                  ),
                  if (settings.thresholdMethod == ThresholdMethod.adaptive)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          '區塊大小：${settings.adaptiveBlockSize}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Slider(
                          min: 3,
                          max: 31,
                          divisions: 14,
                          value: settings.adaptiveBlockSize.toDouble(),
                          label: settings.adaptiveBlockSize.toString(),
                          onChanged: (value) => ref
                              .read(scannerSettingsProvider.notifier)
                              .updateAdaptiveBlockSize(value.round()),
                        ),
                        Text(
                          '偏移量：${settings.adaptiveOffset}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Slider(
                          min: 0,
                          max: 20,
                          divisions: 20,
                          value: settings.adaptiveOffset.toDouble(),
                          label: settings.adaptiveOffset.toString(),
                          onChanged: (value) => ref
                              .read(scannerSettingsProvider.notifier)
                              .updateAdaptiveOffset(value.round()),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          SwitchListTile(
            value: settings.morphology,
            title: const Text('形態學操作'),
            subtitle: const Text('建議與二值化搭配使用，否則可能會造成細節喪失。'),
            onChanged: (value) => ref
                .read(scannerSettingsProvider.notifier)
                .updateMorphology(value),
          ),
          if (settings.morphology)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '形態學半徑：${settings.morphologyRadius}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    min: 1,
                    max: 3,
                    divisions: 2,
                    value: settings.morphologyRadius.toDouble(),
                    label: settings.morphologyRadius.toString(),
                    onChanged: (value) => ref
                        .read(scannerSettingsProvider.notifier)
                        .updateMorphologyRadius(value.round()),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.shield_moon_rounded),
            label: const Text('恢復穩定模式'),
            onPressed: () => ref
                .read(scannerSettingsProvider.notifier)
                .restoreSafeDefaults(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.emoji_events_outlined),
            label: const Text('管理中獎號碼'),
            onPressed: () => context.push('/settings/winning-admin'),
          ),
          const SizedBox(height: 16),
          const Text(
            '提示：若辨識結果變差，請先按「恢復穩定模式」。一般情況只需灰階即可，二值化與形態學為進階選項。',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
