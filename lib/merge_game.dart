import 'dart:async';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flame_physics/mergeCcomponents/dropper_item.dart';
import 'package:flame_physics/mergeCcomponents/boundary.dart';
import 'package:flutter/material.dart';

import 'components/background.dart';
import 'components/brick.dart';
import 'components/ground.dart';

class MergeGame extends Forge2DGame with TapDetector {
  MergeGame()
    : super(
        gravity: Vector2(0, 30),
        camera: CameraComponent.withFixedResolution(width: 300, height: 400),
      );

  @override
  Color backgroundColor() => Colors.blueGrey;

  @override
  FutureOr<void> onLoad() async {
    // debugMode = true;
    await _addBoundary();
    return super.onLoad();
  }

  Future<void> _addBoundary() async {

    await world.add(Bucket());
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

    await world.add(DropperItem(position, _sprite, fruit: _fruit));
  }

  bool isAdding = false;

  Future<void> mergeToNewOne(Vector2 collisionPosition, int fruitNumber) async {
    if (isAdding) return;
    isAdding = true;
    print("adding at $collisionPosition");
    await Future.delayed(const Duration(microseconds: 100));
    final _fruit = FruitItem.getByNumber(fruitNumber + 1);
    // final _sprite = aliens.getSprite(_fruit.fileName);
    final _sprite = await Sprite.load(_fruit.fileName);
    await world.add(DropperItem(collisionPosition, _sprite, fruit: _fruit));
    isAdding = false;
  }
}
