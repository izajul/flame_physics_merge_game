import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flame_physics/components/player.dart';
import 'package:flutter/cupertino.dart';
import 'brick.dart';
import 'ground.dart';
import 'background.dart';

class MyPhysicsGame extends Forge2DGame with TapDetector {
  MyPhysicsGame()
    : super(
        gravity: Vector2(0, 10),
        camera: CameraComponent.withFixedResolution(width: 800, height: 600),
      );

  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;

  @override
  FutureOr<void> onLoad() async {
    final backgroundImage = await images.load('colored_grass.png');
    final spriteSheets = await Future.wait([
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_aliens.png',
        xmlPath: 'spritesheet_aliens.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_elements.png',
        xmlPath: 'spritesheet_elements.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_tiles.png',
        xmlPath: 'spritesheet_tiles.xml',
      ),
    ]);

    aliens = spriteSheets[0];
    elements = spriteSheets[1];
    tiles = spriteSheets[2];

    await world.add(Background(sprite: Sprite(backgroundImage)));

    await addGround();
    unawaited(addBricksRandoms());

    await addPlayer();

    return super.onLoad();
  }

  @override
  void onTapDown(TapDownInfo info) {
    final worldPosition = camera.globalToLocal(info.eventPosition.global);
    print('Tap down at: ${info.eventPosition.global}, ${info.eventPosition.widget}, worldPosition $worldPosition');

    // addBricksByPress(worldPosition);
  }

  Future<void> addGround() {
    // Add from here...
    return world.addAll([
      for (
        var x = camera.visibleWorldRect.left;
        x < camera.visibleWorldRect.right + groundSize;
        x += groundSize
      )
        Ground(
          Vector2(x, (camera.visibleWorldRect.height - groundSize) / 2),
          tiles.getSprite('grass.png'),
        ),
    ]);
  }

  final _random = Random(); // Add from here...

  Future<void> addBricksByPress(Vector2 position) async {
    final type = BrickType.randomType;
    final size = BrickSize.randomSize;

    await world.add(
      Brick(
        type: type,
        size: size,
        damage: BrickDamage.lots,
        position: position,
        /*position: Vector2(
          camera.visibleWorldRect.right / 3 +
              (_random.nextDouble() * 5 - 2.5),
          0,
        ),*/
        sprites: brickFileNames(
          type,
          size,
        ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
      ),
    );
  }

  Future<void> addBricksRandoms() async {
    for (var i = 0; i < 15; i++) {
      final type = BrickType.randomType;
      final size = BrickSize.randomSize;
      await world.add(
        Brick(
          type: type,
          size: size,
          damage: BrickDamage.some,
          position: Vector2(
            camera.visibleWorldRect.right / 3 +
                (_random.nextDouble() * 5 - 2.5),
            0,
          ),
          sprites: brickFileNames(
            type,
            size,
          ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> addPlayer() async => world.add(             // Add from here...
    Player(
      Vector2(camera.visibleWorldRect.left * 2 / 3, 0),
      aliens.getSprite(PlayerColor.randomColor.fileName),
    ),
  );

  @override
  void update(double dt) {
    super.update(dt);
    if (isMounted && world.children.whereType<Player>().isEmpty) {
      addPlayer();
    }
  }
}
