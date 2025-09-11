import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flame_physics/mergeCcomponents/dropper_item.dart';
import 'package:flame_physics/mergeCcomponents/wall.dart';

import 'components/background.dart';
import 'components/brick.dart';
import 'components/ground.dart';

class MergeGame extends Forge2DGame with TapDetector {
  MergeGame()
    : super(
        gravity: Vector2(0, 16),
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

    /// adding wall
    await _addWalls();

    return super.onLoad();
  }

  @override
  void onTapDown(TapDownInfo info) {
    final worldPosition = camera.globalToLocal(info.eventPosition.global);
    // print(
    //   'Tap down at: ${info.eventPosition.global}, ${info.eventPosition.widget}, worldPosition $worldPosition',
    // );

    addBricksByPress(worldPosition);
  }

  Future<void> addBricksByPress(Vector2 position) async {

    final _fruit = FruitItem.randomItem;
    final _sprite = await Sprite.load(_fruit.fileName);

    await world.add(
        DropperItem(position, _sprite, fruit: _fruit)
    );
  }

  Future _addWalls() async {
    for (var x = 0; x < 6; x++) {
      await world.add(
        Wall(
          Vector2(
            camera.visibleWorldRect.left + 10,
            camera.visibleWorldRect.bottom - (x * (7 - 0.8)) - 7,
          ),
          elements.getSprite('elementWood019.png'),
        ),
      );
    }

    for (var x = 0; x < 6; x++) {
      await world.add(
        Wall(
          Vector2(
            camera.visibleWorldRect.right - 10,
            camera.visibleWorldRect.bottom - (x * (7 - 0.8)) - 7,
          ),
          elements.getSprite('elementWood019.png'),
        ),
      );
    }
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

  bool isAdding = false;
  Future<void> mergeToNewOne(Vector2 collisionPosition, int fruitNumber) async {
    if (isAdding) return;
    isAdding = true;
    print("adding at $collisionPosition");
    await Future.delayed(const Duration(microseconds: 100 ));
    final _fruit = FruitItem.getByNumber(fruitNumber+1);
    // final _sprite = aliens.getSprite(_fruit.fileName);
    final _sprite = await Sprite.load(_fruit.fileName);
    await world.add(
        DropperItem(collisionPosition, _sprite, fruit: _fruit)
    );
    isAdding = false;
  }
}
