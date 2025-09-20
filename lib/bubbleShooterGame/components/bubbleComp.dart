import 'package:flame/components.dart';
import 'package:flame_physics/bubbleShooterGame/components/pool.dart';

import '../bubbleShooter.dart';
import 'bubbleItems.dart';
import 'gridComponent.dart';
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
  int row = -1, col = -1; // grid position (valid when settled)

  void reset(BubblesItems newItem) {
    item = newItem;
    sprite = ImagesCache.instance.of(newItem);
    settled = false;
    row = col = -1;
    // also reset visibility, alpha, etc. if needed
  }
}

class FallingBubbles extends Component with HasGameReference<BubbleShooterGame> {
  final Bubble bubble;
  final BubblePool pool;
  final double speed;
  final int points;

  FallingBubbles({
    required this.bubble,
    required this.pool,
    required this.speed,
    this.points = 100
  });

  @override
  Future<void> onLoad() async {
    bubble.priority = 10;
    bubble.position += Vector2.random() * 20;
  }

  @override
  void update(double dt) {
    super.update(dt);
    bubble.position += Vector2(0, speed * dt);
    if (bubble.y > game.size.y-bubble.size.x/2) {
      game.showPopEffect(bubble,points: points);
      pool.release(bubble);
      removeFromParent();
    }
  }
}
