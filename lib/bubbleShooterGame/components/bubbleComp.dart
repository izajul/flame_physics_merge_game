import 'package:flame/components.dart';


import 'bubbleItems.dart';
import 'imageCache.dart';

class Bubble extends SpriteComponent {
  Bubble({required this.item, required double radius})
      : super(
    size: Vector2.all(radius * 2),
    anchor: Anchor.center,
    sprite: ImagesCache.instance.of(item),
  );

  BubblesItems item;
  bool settled = false;
  int row = -1, col = -1;   // grid position (valid when settled)

  void reset(BubblesItems newItem) {
    item = newItem;
    sprite = ImagesCache.instance.of(newItem);
    settled = false;
    row = col = -1;
    // also reset visibility, alpha, etc. if needed
  }
}