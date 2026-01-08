import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:megasprite/src/models/trim_rect.dart';
import 'package:megasprite/src/utils/pixel_utils.dart';

class TrimResult {
  const TrimResult({
    required this.trimmedPixels,
    required this.trimRect,
    required this.pixelHash,
  });

  final Uint8List trimmedPixels;
  final TrimRect trimRect;
  final int pixelHash;
}

class ImageTrimmer {
  const ImageTrimmer._();

  static const int _defaultAlphaThreshold = 0;

  static Future<TrimResult> trim(
    ui.Image image, {
    int alphaThreshold = _defaultAlphaThreshold,
  }) async {
    final width = image.width;
    final height = image.height;

    final byteData = await image.toByteData();
    if (byteData == null) {
      return TrimResult(
        trimmedPixels: Uint8List(0),
        trimRect: const TrimRect.empty(),
        pixelHash: 0,
      );
    }

    final pixels = byteData.buffer.asUint8List();
    final result = PixelUtils.trim(pixels, width, height, alphaThreshold);

    return TrimResult(
      trimmedPixels: result.trimmedPixels,
      trimRect: result.trimRect,
      pixelHash: result.pixelHash,
    );
  }

  static Future<ui.Image> createImageFromPixels(
    Uint8List pixels,
    int width,
    int height,
  ) async {
    final completer = ui.ImmutableBuffer.fromUint8List(pixels);
    final buffer = await completer;
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<ui.Image> createRotatedImage(
    Uint8List pixels,
    int width,
    int height,
  ) async {
    final rotatedPixels =
        Uint8List(width * height * PixelUtils.bytesPerPixel);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final srcIndex = (y * width + x) * PixelUtils.bytesPerPixel;
        final dstX = height - 1 - y;
        final dstY = x;
        final dstIndex = (dstY * height + dstX) * PixelUtils.bytesPerPixel;

        rotatedPixels[dstIndex] = pixels[srcIndex];
        rotatedPixels[dstIndex + 1] = pixels[srcIndex + 1];
        rotatedPixels[dstIndex + 2] = pixels[srcIndex + 2];
        rotatedPixels[dstIndex + 3] = pixels[srcIndex + 3];
      }
    }

    return createImageFromPixels(rotatedPixels, height, width);
  }
}
