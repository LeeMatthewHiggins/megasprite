import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:megasprite/src/models/packed_sprite.dart';

abstract final class AtlasCompositor {
  static const double _rotationAngle = math.pi / 2;

  static Future<ui.Image> composite(
    List<PackedSprite> packed,
    int width,
    int height,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    for (final sprite in packed) {
      if (sprite.frame.isEmpty) continue;

      final image = sprite.frame.trimmedImage;

      if (sprite.rotated) {
        canvas
          ..save()
          ..translate(
            sprite.x.toDouble() + sprite.packedWidth,
            sprite.y.toDouble(),
          )
          ..rotate(_rotationAngle)
          ..drawImage(image, ui.Offset.zero, ui.Paint())
          ..restore();
      } else {
        canvas.drawImage(
          image,
          ui.Offset(sprite.x.toDouble(), sprite.y.toDouble()),
          ui.Paint(),
        );
      }
    }

    final picture = recorder.endRecording();
    final atlasImage = await picture.toImage(width, height);
    picture.dispose();

    return atlasImage;
  }
}
