import 'dart:typed_data';

import 'package:megasprite/src/models/trim_rect.dart';

class PixelBounds {
  const PixelBounds({
    required this.minX,
    required this.minY,
    required this.width,
    required this.height,
  });

  final int minX;
  final int minY;
  final int width;
  final int height;
}

class PixelTrimResult {
  const PixelTrimResult({
    required this.trimmedPixels,
    required this.trimRect,
    required this.pixelHash,
  });

  final Uint8List trimmedPixels;
  final TrimRect trimRect;
  final int pixelHash;
}

abstract final class PixelUtils {
  static const int bytesPerPixel = 4;
  static const int alphaOffset = 3;

  static int computeHash(Uint8List pixels) {
    var hash = 0;
    for (var i = 0; i < pixels.length; i++) {
      hash = (hash * 31 + pixels[i]) & 0x7FFFFFFF;
    }
    return hash;
  }

  static PixelBounds? findBounds(
    Uint8List pixels,
    int width,
    int height,
    int alphaThreshold,
  ) {
    var minX = width;
    var maxX = -1;
    var minY = height;
    var maxY = -1;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = (y * width + x) * bytesPerPixel + alphaOffset;
        if (pixels[index] > alphaThreshold) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      return null;
    }

    return PixelBounds(
      minX: minX,
      minY: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    );
  }

  static Uint8List extractPixels(
    Uint8List sourcePixels,
    int sourceWidth,
    int trimX,
    int trimY,
    int trimWidth,
    int trimHeight,
  ) {
    final trimmedPixels = Uint8List(trimWidth * trimHeight * bytesPerPixel);

    for (var y = 0; y < trimHeight; y++) {
      final srcRowStart =
          ((trimY + y) * sourceWidth + trimX) * bytesPerPixel;
      final dstRowStart = y * trimWidth * bytesPerPixel;
      final rowBytes = trimWidth * bytesPerPixel;

      trimmedPixels.setRange(
        dstRowStart,
        dstRowStart + rowBytes,
        sourcePixels,
        srcRowStart,
      );
    }

    return trimmedPixels;
  }

  static PixelTrimResult trim(
    Uint8List pixels,
    int width,
    int height,
    int alphaThreshold,
  ) {
    final bounds = findBounds(pixels, width, height, alphaThreshold);

    if (bounds == null) {
      return PixelTrimResult(
        trimmedPixels: Uint8List(0),
        trimRect: TrimRect(
          originalWidth: width,
          originalHeight: height,
          x: 0,
          y: 0,
          width: 0,
          height: 0,
        ),
        pixelHash: 0,
      );
    }

    final trimmedPixels = extractPixels(
      pixels,
      width,
      bounds.minX,
      bounds.minY,
      bounds.width,
      bounds.height,
    );

    final pixelHash = computeHash(trimmedPixels);

    return PixelTrimResult(
      trimmedPixels: trimmedPixels,
      trimRect: TrimRect(
        originalWidth: width,
        originalHeight: height,
        x: bounds.minX,
        y: bounds.minY,
        width: bounds.width,
        height: bounds.height,
      ),
      pixelHash: pixelHash,
    );
  }
}
