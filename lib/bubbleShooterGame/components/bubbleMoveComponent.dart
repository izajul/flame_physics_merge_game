

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../bubbleShooter.dart';

class MovingBubble extends PositionComponent with HasGameReference<BubbleShooterGame> ,CollisionCallbacks {
  late final CircleHitbox hitbox;
  Vector2 velocity = Vector2.zero();

  @override
  Future<void> onLoad() async {
    add(hitbox = CircleHitbox.relative(1.0, parentSize: size));
  }

  @override
  void update(double dt) {
    position += velocity * dt;
    // walls
    if (x - width/2 < 0 || x + width/2 > game.size.x) {
      velocity.x = -velocity.x;
      position.x = position.x.clamp(width/2, game.size.x - width/2);
    }
  }
}