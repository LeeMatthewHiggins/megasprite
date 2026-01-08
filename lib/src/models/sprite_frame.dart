import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:megasprite/src/models/trim_rect.dart';
import 'package:megasprite/src/utils/pixel_utils.dart';

class SpriteFrame {
  const SpriteFrame({
    required this.identifier,
    required this.trimmedImage,
    required this.trimRect,
    required this.pixelHash,
  });

  final String identifier;
  final ui.Image trimmedImage;
  final TrimRect trimRect;
  final int pixelHash;

  int get width => trimRect.width;
  int get height => trimRect.height;

  bool get isEmpty => trimRect.isEmpty;

  static int computePixelHash(Uint8List pixels) => PixelUtils.computeHash(pixels);
}
