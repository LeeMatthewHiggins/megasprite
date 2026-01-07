import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:megasprite/megasprite.dart';

void main() {
  runApp(const MegaSpriteExampleApp());
}

/// Example app demonstrating megasprite sprite atlas rendering.
class MegaSpriteExampleApp extends StatelessWidget {
  /// Creates a new megasprite example app.
  const MegaSpriteExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Megasprite Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SpriteDemo(),
    );
  }
}

/// Demo widget showing animated bouncing sprites.
class SpriteDemo extends StatefulWidget {
  /// Creates a new sprite demo.
  const SpriteDemo({super.key});

  @override
  State<SpriteDemo> createState() => _SpriteDemoState();
}

class _SpriteDemoState extends State<SpriteDemo>
    with SingleTickerProviderStateMixin {
  SpriteAtlas? _atlas;
  List<SpriteLocation> _spriteLocations = [];
  late AnimationController _controller;
  final List<_AnimatedSprite> _sprites = [];
  final _random = Random();
  bool _isDragging = false;

  static const int _spriteCount = 50;
  static const double _defaultSpriteSize = 32;

  static const _imageExtensions = ['.png', '.jpg', '.jpeg', '.webp'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _loadAtlas();
  }

  Future<void> _loadAtlas() async {
    final atlas = await SpriteAtlas.fromAsset('assets/sprites.png');
    if (mounted) {
      setState(() {
        _atlas = atlas;
        _spriteLocations = [];
        _initializeSprites();
      });
    }
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    if (details.files.isEmpty) return;

    final file = details.files.first;
    final name = file.name.toLowerCase();

    if (name.endsWith('.zip')) {
      await _handleZipDrop(await file.readAsBytes());
    } else if (_isImageFile(name)) {
      await _handleImageDrop(await file.readAsBytes());
    }
  }

  bool _isImageFile(String name) {
    return _imageExtensions.any(name.endsWith);
  }

  Future<void> _handleImageDrop(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final newAtlas = SpriteAtlas(image: image);

      if (mounted) {
        setState(() {
          _atlas?.dispose();
          _atlas = newAtlas;
          _spriteLocations = [];
          _initializeSprites();
        });
      }
    } on Exception catch (_) {
      // Failed to load image
    }
  }

  Future<void> _handleZipDrop(Uint8List bytes) async {
    try {
      final loader = ZipAtlasLoader();
      final result = await loader.load(bytes);

      if (mounted) {
        setState(() {
          _atlas?.dispose();
          _atlas = result.atlas;
          _spriteLocations = result.spriteLocations;
          _initializeSprites();
        });
      }
    } on ZipAtlasException catch (_) {
      await _handleZipFallback(bytes);
    } on Exception catch (_) {
      await _handleZipFallback(bytes);
    }
  }

  Future<void> _handleZipFallback(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      final imageFile = archive.files.firstWhere(
        (file) => file.isFile && _isImageFile(file.name.toLowerCase()),
        orElse: () => throw Exception('No image found in zip'),
      );

      final imageBytes = imageFile.content as Uint8List;
      await _handleImageDrop(imageBytes);
    } on Exception catch (_) {
      // Failed to extract zip
    }
  }

  void _initializeSprites() {
    final size = MediaQuery.of(context).size;
    _sprites.clear();

    for (var i = 0; i < _spriteCount; i++) {
      final locationIndex = _spriteLocations.isNotEmpty
          ? _random.nextInt(_spriteLocations.length)
          : -1;
      final spriteSize = _getSpriteSize(locationIndex);

      _sprites.add(
        _AnimatedSprite(
          x: _random.nextDouble() * (size.width - spriteSize),
          y: _random.nextDouble() * (size.height - spriteSize),
          dx: (_random.nextDouble() - 0.5) * 4,
          dy: (_random.nextDouble() - 0.5) * 4,
          locationIndex: locationIndex,
        ),
      );
    }
  }

  double _getSpriteSize(int locationIndex) {
    if (_spriteLocations.isEmpty || locationIndex < 0) {
      return _defaultSpriteSize;
    }
    final location = _spriteLocations[locationIndex];
    return location.originalWidth.toDouble();
  }

  @override
  void dispose() {
    _controller.dispose();
    _atlas?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Megasprite Example'),
        backgroundColor: colorScheme.inversePrimary,
        actions: [
          if (_spriteLocations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '${_spriteLocations.length} sprites loaded',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (details) {
          setState(() => _isDragging = false);
          _handleDrop(details);
        },
        child: Stack(
          children: [
            if (_atlas == null)
              const Center(child: CircularProgressIndicator())
            else
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  _updateSprites(context);
                  return CustomPaint(
                    painter: _DemoSpritePainter(
                      sprites: _buildSprites(),
                      atlas: _atlas!,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            if (_isDragging)
              ColoredBox(
                color: colorScheme.primary.withValues(alpha: 0.2),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Drop image or atlas ZIP',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _atlas != null ? _initializeSprites : null,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _updateSprites(BuildContext context) {
    final size = MediaQuery.of(context).size;

    for (final sprite in _sprites) {
      final spriteSize = _getSpriteSize(sprite.locationIndex);
      final maxY = size.height - spriteSize - kToolbarHeight;
      final maxX = size.width - spriteSize;

      sprite
        ..x += sprite.dx
        ..y += sprite.dy;

      if (sprite.x < 0 || sprite.x > maxX) {
        sprite
          ..dx = -sprite.dx
          ..x = sprite.x.clamp(0, maxX);
      }
      if (sprite.y < 0 || sprite.y > maxY) {
        sprite
          ..dy = -sprite.dy
          ..y = sprite.y.clamp(0, maxY);
      }
    }
  }

  List<Sprite> _buildSprites() {
    final atlasImage = _atlas!.image;

    if (_spriteLocations.isEmpty) {
      final srcRect = ui.Rect.fromLTWH(
        0,
        0,
        atlasImage.width.toDouble(),
        atlasImage.height.toDouble(),
      );

      return _sprites.map((s) {
        return Sprite(
          rect: ui.Rect.fromLTWH(
            s.x,
            s.y,
            _defaultSpriteSize,
            _defaultSpriteSize,
          ),
          sourceRect: srcRect,
        );
      }).toList();
    }

    return _sprites.map((s) {
      final location = _spriteLocations[s.locationIndex];
      final displaySize = location.originalWidth.toDouble();

      return Sprite(
        rect: ui.Rect.fromLTWH(s.x, s.y, displaySize, displaySize),
        sourceRect: location.sprite.sourceRect,
      );
    }).toList();
  }
}

class _AnimatedSprite {
  _AnimatedSprite({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.locationIndex,
  });

  double x;
  double y;
  double dx;
  double dy;
  int locationIndex;
}

class _DemoSpritePainter extends CustomPainter {
  _DemoSpritePainter({
    required this.sprites,
    required this.atlas,
  });

  final List<Sprite> sprites;
  final SpriteAtlas atlas;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final image = atlas.image;

    for (final sprite in sprites) {
      canvas.drawImageRect(
        image,
        sprite.sourceRect,
        sprite.rect,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DemoSpritePainter oldDelegate) => true;
}
