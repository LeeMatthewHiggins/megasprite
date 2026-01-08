# MegaSprite

High-performance sprite atlas building and rendering for Flutter.

## Features

- **Texture atlas building**: MaxRects packing algorithm with automatic sprite trimming
- **Sprite deduplication**: Detects and eliminates duplicate sprites to optimize atlas size
- **Rotation support**: Pack sprites rotated for better atlas utilization
- **Isolate-based processing**: Non-blocking atlas building using Dart isolates
- **ZIP serialization**: Export and load atlases as compressed archives
- **Two rendering modes**: Production-ready Canvas.drawAtlas and experimental GPU shader rendering

## Installation

```yaml
dependencies:
  megasprite: ^0.1.0
```

## Usage

### Rendering Sprites

MegaSprite provides two rendering approaches:

#### Atlas Painter (Production Ready)

Uses Flutter's `Canvas.drawAtlas` for reliable, well-tested sprite rendering:

```dart
import 'package:megasprite/megasprite.dart';

class MySpriteWidget extends StatefulWidget {
  @override
  State<MySpriteWidget> createState() => _MySpriteWidgetState();
}

class _MySpriteWidgetState extends State<MySpriteWidget> {
  late SpriteAtlas atlas;
  List<Sprite> sprites = [];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MegaSpriteAtlasPainter(
        sprites: sprites,
        atlas: atlas,
      ),
    );
  }
}
```

#### Shader Painter (Experimental)

Uses fragment shaders with spatial binning for GPU-accelerated rendering. This approach can handle large numbers of sprites but is experimental:

```dart
import 'package:megasprite/megasprite.dart';

class MySpriteWidget extends StatefulWidget {
  @override
  State<MySpriteWidget> createState() => _MySpriteWidgetState();
}

class _MySpriteWidgetState extends State<MySpriteWidget> {
  late SpriteAtlas atlas;
  late ui.FragmentShader shader;
  List<Sprite> sprites = [];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MegaSpriteShaderPainter(
        sprites: sprites,
        atlas: atlas,
        shader: shader,
        cellSize: 64,
      ),
    );
  }
}
```

### Building a Texture Atlas

```dart
import 'package:megasprite/megasprite.dart';

final builder = AtlasBuilder(
  sizePreset: AtlasSizePreset.size2048,
  padding: 2,
  allowRotation: true,
);

final sprites = [
  SourceSprite(identifier: 'player', imageBytes: playerBytes),
  SourceSprite(identifier: 'enemy', imageBytes: enemyBytes),
];

final result = await builder.build(sprites);
```

### Using IsolateAtlasBuilder

For non-blocking atlas building:

```dart
final builder = IsolateAtlasBuilder(
  sizePreset: AtlasSizePreset.size2048,
  padding: 2,
);

final progressStream = builder.build(sprites);

await for (final progress in progressStream) {
  print('Progress: ${progress.progressPercent}%');
  if (progress.result != null) {
    final atlas = progress.result!;
  }
}
```

### Exporting and Loading Atlases

```dart
final exporter = ZipAtlasExporter();
final zipBytes = await exporter.export(atlasResult);

final loader = ZipAtlasLoader();
final loadedAtlas = await loader.load(zipBytes);
```

## API Reference

### Rendering

- `MegaSpriteAtlasPainter` - Production-ready painter using Canvas.drawAtlas
- `MegaSpriteShaderPainter` - Experimental GPU shader painter with spatial binning
- `Sprite` - Represents a sprite with position, source rect, and optional transforms
- `SpriteAtlas` - Wrapper for a texture atlas image

### Atlas Building

- `AtlasBuilder` - Builds texture atlases from source sprites
- `IsolateAtlasBuilder` - Non-blocking atlas builder using isolates
- `AtlasBuilderConfig` - Configuration presets for atlas building
- `AtlasResult` - Result containing packed pages and statistics
- `AtlasPage` - Single page of a multi-page atlas

### Serialization

- `AtlasSerializer` - Serializes atlas data to JSON
- `AtlasDeserializer` - Deserializes atlas data from JSON
- `ZipAtlasExporter` - Exports atlases as ZIP archives
- `ZipAtlasLoader` - Loads atlases from ZIP archives

## Requirements

- Flutter 3.24.0 or higher
- Dart SDK 3.5.0 or higher

## License

MIT License - see [LICENSE](LICENSE) for details.
