import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../domain/scan_settings.dart';

class ImageProcessing {
    static Future<String> preprocessImage(
    String imagePath,
    ScanSettings settings,
    ) async {
    final inputFile = File(imagePath);
    if (!await inputFile.exists()) return imagePath;

    if (!settings.hasAnyProcessing) {
        return imagePath;
    }

    final inputBytes = await inputFile.readAsBytes();
    final original = img.decodeImage(inputBytes);
    if (original == null) return imagePath;

    img.Image processed = original;

    // 1. 灰階轉換
    if (settings.grayscale ||
        settings.binarize ||
        settings.enhancement ||
        settings.deskew ||
        settings.perspective ||
        settings.morphology) {
        processed = _toGrayscaleImage(processed);
    }

    // 2. 降噪
    if (settings.denoise) {
        processed = _denoise(
        processed,
        settings.denoiseMethod,
        settings.denoiseRadius,
    );
    }

    // 3. 倾斜校正
    if (settings.deskew) {
        processed = _deskew(processed);
    }

    // 4. 透視變換 (簡易裁切為內容區域)
    if (settings.perspective) {
        processed = _autoCropDocument(
        processed,
        settings.perspectivePaddingPercent,
    );
    }

    // 5. 影像增強
    if (settings.enhancement) {
        processed = _enhanceContrast(processed);
    }

    // 6. 二值化
    if (settings.binarize) {
        processed = _binarizeImage(
        processed,
        settings.thresholdMethod,
        settings.adaptiveBlockSize,
        settings.adaptiveOffset,
    );
    }

    // 7. 形態學操作
    if (settings.morphology && settings.binarize) {
    processed = _applyMorphology(processed, settings.morphologyRadius);
    }

    final outputFile = await _writeTemporaryImage(processed);
    return outputFile.path;
}

static img.Image _toGrayscaleImage(img.Image input) {
    final image = img.Image.from(input);
    for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
        final pixel = input.getPixel(x, y);
        final gray = _luma(pixel);
        image.setPixelRgba(x, y, gray, gray, gray, 255);
    }
    }
    return image;
}

static int _luma(img.Pixel pixel) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    return ((r * 0.299 + g * 0.587 + b * 0.114).round()).clamp(0, 255);
}

static img.Image _denoise(img.Image input, DenoiseMethod method, int radius) {
    switch (method) {
        case DenoiseMethod.gaussian:
        return img.gaussianBlur(img.Image.from(input), radius: radius);
        case DenoiseMethod.median:
        return _medianFilter(img.Image.from(input), radius);
    }
}

static img.Image _medianFilter(img.Image input, int radius) {
    final output = img.Image.from(input);
    for (var y = 0; y < input.height; y++) {
        for (var x = 0; x < input.width; x++) {
        final values = <int>[];
        for (var j = -radius; j <= radius; j++) {
            for (var i = -radius; i <= radius; i++) {
            final nx = x + i;
            final ny = y + j;
            if (nx < 0 || nx >= input.width || ny < 0 || ny >= input.height) {
                continue;
            }
            values.add(input.getPixel(nx, ny).r.toInt());
        }
        }
        values.sort();
        final median = values[values.length ~/ 2];
        output.setPixelRgba(x, y, median, median, median, 255);
    }
    }
    return output;
}

static img.Image _deskew(img.Image input) {
    final binary = _binarizeImage(img.Image.from(input), ThresholdMethod.otsu);
    final angle = _estimateSkewAngle(binary);
    if (angle.abs() < 0.5) {
        return input;
    }
    return img.copyRotate(input, angle: -angle);
}

static double _estimateSkewAngle(img.Image binary) {
    const maxAngle = 10;
    const step = 1;
    double bestAngle = 0;
    double bestScore = double.negativeInfinity;

    for (var angle = -maxAngle; angle <= maxAngle; angle += step) {
        final rotated = img.copyRotate(binary, angle: angle);
        final scores = <double>[];
        for (var y = 0; y < rotated.height; y++) {
        var rowSum = 0;
        for (var x = 0; x < rotated.width; x++) {
            rowSum += rotated.getPixel(x, y).r.toInt() < 128 ? 1 : 0;
        }
        scores.add(rowSum.toDouble());
    }
    final mean =
        scores.fold(0.0, (sum, value) => sum + value) / scores.length;
    final variance =
        scores.fold(0.0, (sum, value) => sum + pow(value - mean, 2)) /
        scores.length;
    if (variance > bestScore) {
        bestScore = variance;
        bestAngle = angle.toDouble();
    }
    }
    return bestAngle;
}

static img.Image _autoCropDocument(img.Image input, double paddingPercent) {
    final binary = _binarizeImage(img.Image.from(input), ThresholdMethod.otsu);
    var minX = input.width;
    var minY = input.height;
    var maxX = 0;
    var maxY = 0;

    for (var y = 0; y < binary.height; y++) {
    for (var x = 0; x < binary.width; x++) {
        if (binary.getPixel(x, y).r.toInt() < 128) {
        minX = min(minX, x);
        minY = min(minY, y);
        maxX = max(maxX, x);
        maxY = max(maxY, y);
        }
    }
    }

    if (minX >= maxX || minY >= maxY) {
    return input;
    }

    final paddingX = ((maxX - minX) * paddingPercent).round();
    final paddingY = ((maxY - minY) * paddingPercent).round();
    minX = max(0, minX - paddingX);
    minY = max(0, minY - paddingY);
    maxX = min(input.width - 1, maxX + paddingX);
    maxY = min(input.height - 1, maxY + paddingY);

    return img.copyCrop(
    input,
    x: minX,
    y: minY,
    width: maxX - minX,
    height: maxY - minY,
    );
}

static img.Image _enhanceContrast(img.Image input) {
    final image = img.Image.from(input);
    final histogram = List<int>.filled(256, 0);
    for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
        histogram[image.getPixel(x, y).r.toInt()]++;
    }
    }
    final total = image.width * image.height;
    var cumulative = 0;
    final lut = List<int>.filled(256, 0);
    for (var i = 0; i < histogram.length; i++) {
    cumulative += histogram[i];
      lut[i] = ((cumulative * 255) / total).round();
    }
    for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
        final gray = image.getPixel(x, y).r.toInt();
        final mapped = lut[gray].clamp(0, 255);
        image.setPixelRgba(x, y, mapped, mapped, mapped, 255);
    }
    }
    return image;
}

static img.Image _binarizeImage(
    img.Image input,
    ThresholdMethod method, [
    int blockSize = 15,
    int offset = 8,
  ]) {
    final image = img.Image.from(input);
    if (method == ThresholdMethod.adaptive) {
      return _adaptiveThreshold(image, blockSize, offset);
    }
    final threshold = _otsuThreshold(image);
    return _globalThreshold(image, threshold);
  }

  static img.Image _globalThreshold(img.Image image, int threshold) {
    final output = img.Image.from(image);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final gray = image.getPixel(x, y).r.toInt();
        final value = gray < threshold ? 0 : 255;
        output.setPixelRgba(x, y, value, value, value, 255);
      }
    }
    return output;
  }

  static int _otsuThreshold(img.Image image) {
    final histogram = List<int>.filled(256, 0);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        histogram[image.getPixel(x, y).r.toInt()]++;
      }
    }
    final total = image.width * image.height;
    var sum = 0;
    for (var t = 0; t < 256; t++) {
      sum += t * histogram[t];
    }
    var sumB = 0;
    var wB = 0;
    var maximum = 0.0;
    var threshold = 0;
    for (var t = 0; t < 256; t++) {
      wB += histogram[t];
      if (wB == 0) continue;
      final wF = total - wB;
      if (wF == 0) break;
      sumB += t * histogram[t];
      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;
      final between = (wB * wF * pow(mB - mF, 2)).toDouble();
      if (between > maximum) {
        maximum = between;
        threshold = t;
      }
    }
    return threshold;
  }

  static img.Image _adaptiveThreshold(
    img.Image image,
    int blockSize,
    int offset,
  ) {
    final width = image.width;
    final height = image.height;
    final integral = List<int>.filled((width + 1) * (height + 1), 0);
    for (var y = 0; y < height; y++) {
      var rowSum = 0;
      for (var x = 0; x < width; x++) {
        rowSum += image.getPixel(x, y).r.toInt();
        integral[(y + 1) * (width + 1) + x + 1] =
            integral[y * (width + 1) + x + 1] + rowSum;
      }
    }

    final output = img.Image(width: width, height: height);
    final half = blockSize ~/ 2;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final x1 = max(0, x - half);
        final x2 = min(width - 1, x + half);
        final y1 = max(0, y - half);
        final y2 = min(height - 1, y + half);
        final count = (x2 - x1 + 1) * (y2 - y1 + 1);
        final sum =
            integral[(y2 + 1) * (width + 1) + x2 + 1] -
            integral[(y1) * (width + 1) + x2 + 1] -
            integral[(y2 + 1) * (width + 1) + x1] +
            integral[y1 * (width + 1) + x1];
        final mean = sum ~/ count;
        final gray = image.getPixel(x, y).r.toInt();
        final value = gray * count < mean * (count - offset) ? 0 : 255;
        output.setPixelRgba(x, y, value, value, value, 255);
      }
    }
    return output;
  }

  static img.Image _applyMorphology(img.Image input, int radius) {
    final eroded = _erode(input, radius);
    final opened = _dilate(eroded, radius);
    final dilated = _dilate(opened, radius);
    return _erode(dilated, radius);
  }

  static img.Image _erode(img.Image input, int radius) {
    final output = img.Image.from(input);
    for (var y = 0; y < input.height; y++) {
      for (var x = 0; x < input.width; x++) {
        var minVal = 255;
        for (var j = -radius; j <= radius; j++) {
          for (var i = -radius; i <= radius; i++) {
            final nx = x + i;
            final ny = y + j;
            if (nx < 0 || nx >= input.width || ny < 0 || ny >= input.height) {
              continue;
            }
            minVal = min(minVal, input.getPixel(nx, ny).r.toInt());
          }
        }
        output.setPixelRgba(x, y, minVal, minVal, minVal, 255);
      }
    }
    return output;
  }

  static img.Image _dilate(img.Image input, int radius) {
    final output = img.Image.from(input);
    for (var y = 0; y < input.height; y++) {
      for (var x = 0; x < input.width; x++) {
        var maxVal = 0;
        for (var j = -radius; j <= radius; j++) {
          for (var i = -radius; i <= radius; i++) {
            final nx = x + i;
            final ny = y + j;
            if (nx < 0 || nx >= input.width || ny < 0 || ny >= input.height) {
              continue;
            }
            maxVal = max(maxVal, input.getPixel(nx, ny).r.toInt());
          }
        }
        output.setPixelRgba(x, y, maxVal, maxVal, maxVal, 255);
      }
    }
    return output;
  }

  static Future<File> _writeTemporaryImage(img.Image image) async {
    final tempDir = await getTemporaryDirectory();
    final outputFile = File(
      '${tempDir.path}/preprocessed_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await outputFile.writeAsBytes(img.encodePng(image));
    return outputFile;
  }
}
