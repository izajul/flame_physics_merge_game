
import 'dart:ui';
import 'package:flame/game.dart';
import 'components/gridComponent.dart';
import 'components/imageCache.dart';
import 'components/pool.dart';
import 'components/shooterComp.dart';

class BubbleShooterGame extends FlameGame with HasCollisionDetection {
  @override
  Color backgroundColor() => const Color(0xff191e23);

  late final Grid grid; // hex grid manager
  late final Shooter shooter; // handles aim + fired bubble
  late final BubblePool pool; // object pooling

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
}
