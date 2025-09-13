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

class MergeGame extends Forge2DGame with DragCallbacks {
  MergeGame()
    : super(
        gravity: Vector2(0, 30),
        camera: CameraComponent.withFixedResolution(width: 300, height: 400),
      );

  @override
  Color backgroundColor() => Colors.blueGrey;

  late final List<FruitItem> fruitQueue = [];

  DropperItem? itemReadyToDrop;

  ComponentKey? lastFruitKey;

  @override
  FutureOr<void> onLoad() async {
    // Add initial fruits to the queue
    for (int i = 0; i < 4; i++) {
      fruitQueue.add(FruitItem.randomItem);
    }

    // debugMode = true;
    await _addBoundary();

    await showNextFruit();

    return super.onLoad();
  }

  Future<void> _addBoundary() async {
    await world.add(Bucket());
  }

  double? _dragPreviewX; // world-space X we control during a drag

  @override
  void _onDragStart(DragStartEvent event) async {
    itemReadyToDrop = await getCurrentDropperItem();

    if (itemReadyToDrop == null) return;

    final worldPosition = camera.globalToLocal(event.localPosition);
    print("Drag start: $worldPosition");

    // Clamp to bucket:
    final r = (itemReadyToDrop!.extraData as FruitItem).itemSize / 2;
    final clampedX = _clampX(worldPosition.x, r);
    itemReadyToDrop!.moveHorizontallyTo(clampedX);
    super.onDragStart(event);
  }

  @override
  void onDragStart(DragStartEvent event) async {
    itemReadyToDrop = await getCurrentDropperItem();
    if (itemReadyToDrop == null) return;

    // Start from the current body X; we’ll add deltas in update.
    _dragPreviewX = itemReadyToDrop!.body.position.x;

    // Optional: immediately align to the start pointer X if you want
    // (only if localPosition exists on DragStart, which it does):
    final r = (itemReadyToDrop!.extraData as FruitItem).itemSize * 0.5;
    final startX = _clampX(camera.globalToLocal(event.localPosition).x, r);
    _dragPreviewX = startX;
    itemReadyToDrop!.moveHorizontallyTo(startX);

    super.onDragStart(event);
  }

  @override
  void _onDragUpdate(DragUpdateEvent event) {
    /// update itemReadyToDrop position horizontally
    if (itemReadyToDrop != null &&
        itemReadyToDrop!.body.bodyType != BodyType.dynamic) {
      // final lastItemPosi = itemReadyToDrop!.position.clone();
      // final worldPos = camera.globalToLocal(event.localDelta);
      final worldPos = event.localDelta.x+itemReadyToDrop!.position.x;
      final r = (itemReadyToDrop!.extraData as FruitItem).itemSize / 2;
      final clampedX = _clampX(worldPos * 0.07, r);
      print("clampedX: $clampedX, worldPos: $worldPos, r: $r");
      itemReadyToDrop!.moveHorizontallyTo(clampedX);
      // itemReadyToDrop?.body.setTransform(
      //   lastItemPosi..x += event.localDelta.x * 0.07,
      //   0,
      // );
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (itemReadyToDrop == null) return;
    if (itemReadyToDrop!.body.bodyType == BodyType.dynamic) return; // already dropped

    // `localDelta.x` is already in game coords; accumulate it.
    _dragPreviewX ??= itemReadyToDrop!.body.position.x;
    _dragPreviewX = _dragPreviewX! + event.localDelta.x  * 0.07;

    // Clamp inside the bucket, considering fruit radius and wall thickness.
    final r = (itemReadyToDrop!.extraData as FruitItem).itemSize * 0.5;
    final clampedX = _clampX(_dragPreviewX!, r);

    itemReadyToDrop!.moveHorizontallyTo(clampedX);
  }

  @override
  void onDragEnd(DragEndEvent event) async {
    if (itemReadyToDrop != null &&
        itemReadyToDrop!.body.bodyType != BodyType.dynamic) {
      // Either flip preview to dynamic…
      await itemReadyToDrop!.toDynamic();
      await _advanceQueueAndShowNext();
    }
    _dragPreviewX = null; // reset
    super.onDragEnd(event);
  }

  Future<void> _advanceQueueAndShowNext() async {
    if (fruitQueue.isNotEmpty) {
      fruitQueue.removeAt(0);
      fruitQueue.add(FruitItem.randomItem);
    }
    itemReadyToDrop = null;
    lastFruitKey = null;
    await Future.delayed(const Duration(milliseconds: 150));
    await showNextFruit();
  }

  double __clampX(double x, double radius) {
    // Keep inside walls, add a small margin for wall thickness.
    final half = Bucket.bucketWidth / 2;
    final margin = Bucket.wallWidth + 0.1;
    return x.clamp(-half + radius + margin, half - radius - margin);
  }

  double _clampX(double x, double radius) {
    // Inner horizontal span of the bucket where the fruit’s center can be,
    // leaving space for walls and the fruit radius.
    final half = Bucket.bucketWidth * 0.5;
    final margin = Bucket.wallWidth + 0.1; // small safety margin
    final minX = -half + margin + radius;
    final maxX =  half - margin - radius;

    // If radius is too big for the bucket, minX may exceed maxX; guard it:
    if (minX > maxX) {
      // Debug once to verify your units; if this happens, scale fruit/bucket.
      // print('Fruit too large for bucket: minX=$minX maxX=$maxX radius=$radius');
      return (minX + maxX) * 0.5; // park at center to avoid snapping
    }
    return x.clamp(minX, maxX);
  }


  Future<DropperItem?> getCurrentDropperItem() async {
    return world.children.whereType<DropperItem>().firstWhereOrNull(
      (e) => e.key == lastFruitKey,
    );
  }

  Future<void> showNextFruit() async {
    if (fruitQueue.isEmpty) return;

    final nextFruit = fruitQueue.first; // Get first item from queue
    await addFruitToTopCenter(nextFruit);
  }

  Future<void> addFruitToTopCenter(FruitItem item) async {
    final sprite = await _getFruitSprite(item);
    final position = Vector2(0, -Bucket.bucketHeight / 2);

    final fruit = DropperItem(
      position,
      sprite,
      fruit: item,
      key: lastFruitKey = ComponentKey.unique(),
    );

    await world.add(fruit);
  }

  Future<void> dropItem() async {
    await itemReadyToDrop?.toDynamic();

    // Update queue: remove the used fruit and add a new one
    if (fruitQueue.isNotEmpty) {
      fruitQueue.removeAt(0); // Remove from front
      fruitQueue.add(FruitItem.randomItem); // Add to end
    }

    itemReadyToDrop = null;
    lastFruitKey = null;

    // Show next fruit after a short delay
    await Future.delayed(const Duration(milliseconds: 300));
    await showNextFruit();
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
    await world.add(
      DropperItem(
        collisionPosition,
        _sprite,
        fruit: _fruit,
        bodyType: BodyType.dynamic,
      ),
    );
    isAdding = false;
  }

  Future<Sprite> _getFruitSprite(FruitItem item) async {
    // final _fruit = FruitItem.randomItem;
    return await Sprite.load(item.fileName);
  }
}

extension ListExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T e) param0) {
    for (var element in this) {
      if (param0(element)) {
        return element;
      }
    }
    return null;
  }
}
