import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle;
import 'package:flame_physics/mergeCcomponents/dropper_item.dart';
import 'package:flame_physics/mergeCcomponents/boundary.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/controller_merge.dart';
import 'mergeCcomponents/game_over_line.dart';
import 'mergeCcomponents/particals/repeating_scaling.dart';
import 'mergeCcomponents/shimmer_line.dart';

class MergeGame extends Forge2DGame with DragCallbacks {
  static const double kWorldW = 300;
  static const double kWorldH = 395;
  static const String gameOverOverlayID = 'GameOver';

  MergeGame()
    : super(
        gravity: Vector2(0, 30),
        // camera: CameraComponent.withFixedResolution(width: 300, height: 510),
        camera: CameraComponent.withFixedResolution(
          width: kWorldW,
          height: kWorldH,
        ),
      );

  @override
  // Color backgroundColor() => Color(0xff698eb3);
  Color backgroundColor() => Color(0xff191e23);

  DropperItem? itemReadyToDrop;

  ComponentKey? lastFruitKey;

  ShimmerLine? _shimmerLine;

  final ControllerMerge _controller = Get.find();

  RxList<FruitItem> get fruitQueue => _controller.fruitQueue;

  // --- Game over limit (y measured from top rim ~ 0 going down) ---
  double limitY = 1.0; // 1 world unit below the rim; tweak to taste
  final double topMargin = 0.05; // small slack to avoid flicker

  bool isGameOver = false;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    // Add initial fruits to the queue
    for (int i = 0; i < 4; i++) {
      fruitQueue.add(FruitItem.randomItem);
    }

    // debugMode = true;
    await _addBoundary();

    // Add the game-over line a little BELOW the bucket rim (rim is at y = 0).
    // If you kept static Bucket fields:
    // final limitY =
    limitY =
        (-Bucket.bucketHeight / 2) +
        5; // 1 world unit inside the bucket; tweak as needed
    await world.add(
      GameOverLine(width: Bucket.bucketWidth, y: limitY, thickness: 0.5),
    );

    // await _addShimmerLine();

    await showNextFruit();
  }

  Future<void> _addShimmerLine() async {
    // Example 1: A blueish shimmer line on the left
    _shimmerLine = ShimmerLine(
      position: Vector2(-0.0, -Bucket.bucketHeight / 2),
      // Position on the screen
      height: Bucket.bucketHeight,
      // Length of the line
      baseColor: Color(0xffffff),
      shimmerColor: Colors.blue.shade100,
      lineThickness: 0.1,
      // shimmerSpeed: 50.0,
    );

    // Add the components to your game world
    world.add(_shimmerLine!);
  }

  Future<void> _addBoundary() async {
    final visibleW = camera.viewport.virtualSize.x / camera.viewfinder.zoom;
    print("visibleW: $visibleW");
    Bucket.bucketWidth = (visibleW - Bucket.wallWidth * 2);
    await world.add(Bucket());
  }

  double? _dragPreviewX; // world-space X we control during a drag

  bool _isDropping = false;

  @override
  void onDragStart(DragStartEvent event) async {
    itemReadyToDrop = await getCurrentDropperItem();
    if (itemReadyToDrop == null) return;

    _isDropping = true;

    // Start from the current body X; we’ll add deltas in update.
    _dragPreviewX = itemReadyToDrop!.body.position.x;

    // Optional: immediately align to the start pointer X if you want
    // (only if localPosition exists on DragStart, which it does):
    final r = (itemReadyToDrop!.extraData as FruitItem).itemSize * 0.5;
    final startX = _clampX(camera.globalToLocal(event.localPosition).x, r);
    _dragPreviewX = startX;
    itemReadyToDrop!.moveHorizontallyTo(startX);
    _shimmerLine?.moveHorizontallyTo(startX);

    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (itemReadyToDrop == null) return;
    if (itemReadyToDrop!.body.bodyType == BodyType.dynamic)
      return; // already dropped

    // `localDelta.x` is already in game coords; accumulate it.
    _dragPreviewX ??= itemReadyToDrop!.body.position.x;
    _dragPreviewX = _dragPreviewX! + event.localDelta.x * 0.07;

    // Clamp inside the bucket, considering fruit radius and wall thickness.
    final r = (itemReadyToDrop!.extraData as FruitItem).itemSize * 0.5;
    final clampedX = _clampX(_dragPreviewX!, r);

    itemReadyToDrop!.moveHorizontallyTo(clampedX);
    _shimmerLine?.moveHorizontallyTo(clampedX);
  }

  @override
  void onDragEnd(DragEndEvent event) async {
    if (itemReadyToDrop != null &&
        itemReadyToDrop!.body.bodyType != BodyType.dynamic) {
      world.remove(_shimmerLine!);
      _shimmerLine = null;
      // Either flip preview to dynamic…
      await itemReadyToDrop!.toDynamic();
      await _advanceQueueAndShowNext();
      _isDropping = false;
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

  double _clampX(double x, double radius) {
    // Inner horizontal span of the bucket where the fruit’s center can be,
    // leaving space for walls and the fruit radius.
    final half = Bucket.bucketWidth * 0.5;
    final margin = Bucket.wallWidth + 0.1; // small safety margin
    final minX = -half + margin + radius;
    final maxX = half - margin - radius;

    // If radius is too big for the bucket, minX may exceed maxX; guard it:
    if (minX > maxX) {
      // Debug once to verify your units; if this happens, scale fruit/bucket.
      // print('Fruit too large for bucket: minX=$minX maxX=$maxX radius=$radius');
      return (minX + maxX) * 0.5; // park at center to avoid snapping
    }
    return x.clamp(minX, maxX);
  }

  Future<DropperItem?> getCurrentDropperItem() async {
    if (lastFruitKey == null || _isDropping) return null;
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
    await _addShimmerLine();
  }

  bool isAdding = false;

  Future<void> mergeToNewOne(Vector2 collisionPosition, int fruitNumber) async {
    if (isAdding) return;
    isAdding = true;
    print("adding at $collisionPosition");
    _controller.score(_controller.score.value + fruitNumber * 2);

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
    await showEffectAt(collisionPosition, _fruit.itemSize);
    isAdding = false;
  }

  Future<Sprite> _getFruitSprite(FruitItem item) async {
    return await Sprite.load(item.fileName);
  }

  // Poll the pile height each frame
  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    // Find the highest (closest to rim) settled fruit top.
    // y increases downward, so "higher" means smaller y.
    double? highestTopY;

    for (final d in world.children.whereType<DropperItem>()) {
      if (d.body.bodyType != BodyType.dynamic) continue;
      if (!d.isSettled) continue;

      final topY = d.body.position.y - d.radius; // top point of the circle
      if (highestTopY == null || topY < highestTopY!) {
        highestTopY = topY;
      }
    }

    if (highestTopY != null && highestTopY! <= (limitY + topMargin)) {
      onGameOver();
    }
  }

  void onGameOver() {
    if (isGameOver) return;
    isGameOver = true;
    pauseEngine();
    overlays.add(gameOverOverlayID);
  }

  Future<void> restartGame() async {
    // remove overlays immediately to show the game again
    overlays.remove(gameOverOverlayID);

    // clear world bodies (fruits, bucket, etc.)
    for (final c in world.children.toList()) {
      if (c is DropperItem) c.removeFromParent();
    }
    // clear non-world UI components (limit line)
    // await limitLine?.removeFromParent();

    // reset state
    isGameOver = false;
    isAdding = false;
    itemReadyToDrop = null;
    lastFruitKey = null;
    fruitQueue
      ..clear()
      ..addAll(List.generate(4, (_) => FruitItem.randomItem));

    // rebuild bucket and limit
    // bucket = Bucket(width: kWorldW, height: 30, wallWidth: 0.3);
    // await world.add(bucket);
    // limitLine = LimitLine(width: kWorldW, y: limitY, color: Colors.redAccent);
    // await add(limitLine!);

    // spawn the next fruit
    await showNextFruit();

    // resume
    resumeEngine();
  }

  Future<void> showEffectAt(Vector2 position, double itemSize) async {
    final sprite = await Sprite.load('stat_0.png');

    final p1 = ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 5,
        generator: (i) {
          return AcceleratedParticle(
            acceleration: Vector2.zero(),
            speed: Vector2.random(),
            // lifespan: Random().nextDouble() + 0.5,
            position: Vector2(
              (Random().nextDouble() * itemSize * 1.5 - itemSize),
              Random().nextDouble() * itemSize * 1.1 - itemSize,
            ),
            child: SpriteParticle(sprite: sprite, size: Vector2.all(1)),
          );
        },
      ),
    );
    /*
    final p2 = makeBlinkingMovingParticles(
      position: position,
      sprite: sprite,
      itemSize: itemSize,
      to: Vector2(0, -5),
    );*/

    await world.add(p1);
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
