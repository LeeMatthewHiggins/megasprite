import 'dart:math';
import 'dart:ui' as ui;

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
  late AnimationController _controller;
  final List<_AnimatedSprite> _sprites = [];
  final _random = Random();

  static const int _spriteCount = 50;
  static const double _spriteSize = 32;

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
        _initializeSprites();
      });
    }
  }

  void _initializeSprites() {
    final size = MediaQuery.of(context).size;
    _sprites.clear();

    for (var i = 0; i < _spriteCount; i++) {
      _sprites.add(
        _AnimatedSprite(
          x: _random.nextDouble() * (size.width - _spriteSize),
          y: _random.nextDouble() * (size.height - _spriteSize),
          dx: (_random.nextDouble() - 0.5) * 4,
          dy: (_random.nextDouble() - 0.5) * 4,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _atlas?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Megasprite Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _atlas == null
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _atlas != null ? _initializeSprites : null,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _updateSprites(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxY = size.height - _spriteSize - kToolbarHeight;
    final maxX = size.width - _spriteSize;

    for (final sprite in _sprites) {
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
    final srcRect = ui.Rect.fromLTWH(
      0,
      0,
      atlasImage.width.toDouble(),
      atlasImage.height.toDouble(),
    );

    return _sprites.map((s) {
      return Sprite(
        rect: ui.Rect.fromLTWH(s.x, s.y, _spriteSize, _spriteSize),
        sourceRect: srcRect,
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
  });

  double x;
  double y;
  double dx;
  double dy;
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
