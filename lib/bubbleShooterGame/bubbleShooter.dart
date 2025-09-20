import 'dart:ui';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_physics/bubbleShooterGame/components/bubbleComp.dart';
import 'components/gridComponent.dart';
import 'components/imageCache.dart';
import 'components/pool.dart';
import 'components/pop_effect.dart';
import 'components/pop_score.dart';
import 'components/shooterComp.dart';

class BubbleShooterGame extends FlameGame
    with HasCollisionDetection, DragCallbacks, TapCallbacks {
  @override
  Color backgroundColor() => const Color(0xff191e23);

  late final Grid grid; // hex grid manager
  late final Shooter shooter; // handles aim + fired bubble
  late final BubblePool pool; // object pooling

  int scores = 0;
  int _shotsSinceAdvance = 0;
  bool _gameOver = false;

  double get lossLineY => size.y- shooter.muzzleOffset*2; // shooter line

  @override
  Future<void> onLoad() async {
    await ImagesCache.instance.preload();

    grid = Grid(cellRadius: 16, topY: 0); // add a topY field in Grid
    add(grid);

    pool = BubblePool(grid: grid);

    shooter = Shooter(grid: grid, pool: pool);
    add(shooter);

    // (Optional) seed a starter ceiling of settled bubbles)
    grid.seedInitialRows(pool);
  }

  // Handle aiming when the user drags their finger
  @override
  void onDragUpdate(DragUpdateEvent event) {
    shooter.aimToward(event.deviceStartPosition);
  }

  // Handle firing when the user lifts their finger
  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    shooter.fire();
  }

  // Also allow tap-to-aim-and-fire
  @override
  void onTapUp(TapUpEvent event) {
    shooter.aimToward(event.devicePosition);
    shooter.fire();
  }

  Future<void> showPopEffect(Bubble bub, {int points = 20}) async {
    /// Optional: play pop effect here.

    // 2. Add the pop effect at the bubble's position
    add(
      BubblePopEffect(
        position: bub.position,
        color: bub.item.ballColor, // Pass the bubble's color to the effect
      ),
    );

    /// the points = 0 mean all bubbles are popping after game over
    if(points == 0) {
      return;
    }
    // 3. Add the score pop-up at the bubble's position
    add(ScorePopup(points: points, position: bub.position));
    scores += points;
  }

  void oneShotFired() async {
    print("_shotsSinceAdvance: $_shotsSinceAdvance,_gameOver:$_gameOver ");
    if (_gameOver) return;

    _shotsSinceAdvance++;
    if (_shotsSinceAdvance >= 3) {
      _shotsSinceAdvance = 0;
      final lost = grid.advanceRows(1, pool, lossLineY: lossLineY);
      if (lost) {
        gameOver();
      }
    }
  }

  void gameOver() async {
    print("gameOver");
    if (_gameOver) return;
    _gameOver = true;

    // Stop input by removing/pausing Shooter (pick one):
    await shooter.destroy();

    grid.destroyGrids(pool);
    // or: pauseEngine();

    // TODO: show overlay / restart button, sound, etc.
    // overlays.add('GameOverMenu');
  }
}
