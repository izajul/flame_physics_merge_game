import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_physics/bubbleShooterGame/components/pool.dart';

import '../bubbleShooter.dart';
import 'bubbleComp.dart';
import 'gridComponent.dart';

class Shooter extends PositionComponent
    with HasGameReference<BubbleShooterGame>, DragCallbacks, TapCallbacks {
  Shooter({
    required this.grid,
    required this.pool,
    this.muzzleOffset = 28,
    this.minAngleDeg = 10,
    this.maxAngleDeg = 170,
    this.speed = 520,
    this.previewDots = 18,
    this.previewStep = 14,
  }) : super(priority: 50, anchor: Anchor.center);

  final Grid grid;
  final BubblePool pool;

  // config
  final double muzzleOffset; // distance from center to spawn projectile
  final double minAngleDeg;
  final double maxAngleDeg;
  final double speed;
  final int previewDots; // how many dots to render
  final double previewStep; // px between preview samples
  late Vector2 muzzleCenter;

  // state
  double _angleRad = math.pi / 2; // pointing straight up by default
  Bubble? _projectile;
  late TrajectoryDots? _dots;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    // position = Vector2.zero();
    position = Vector2(game.size.x / 2, game.size.y - 56);
    size = game.size;

    _recalcMuzzle();

    _dots = TrajectoryDots(dotCount: previewDots, position: position);
    add(_dots!);

    _ensureProjectileReady();
    _updatePreview();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    size = canvasSize;
    _recalcMuzzle();
    _placeProjectileAtMuzzle();
    _updatePreview();
  }

  void _recalcMuzzle() => muzzleCenter = Vector2(size.x / 2, size.y );

  // region — Input
  @override
  void onDragUpdate(DragUpdateEvent event) {
    _aimToward(event.localEndPosition);
    print("onDragUpdate:${event.localEndPosition}");
  }

  @override
  void onTapDown(TapDownEvent event) {
    print("onTapDown:${event.localPosition}");
    _aimToward(event.localPosition);
    _fire();
  }

  // 1) Add a helper once in Shooter
  Vector2 _dirFromAngle(double a) =>
      Vector2(math.cos(a), -math.sin(a)); // note the minus

  // region — Core
  void _aimToward(Vector2 p) {
    final d = (p - muzzleCenter);
    // final d = p - position;
    if (d.y > -4) d.y = -4; // never aim downward
    final raw = math.atan2(-d.y, d.x); // <- invert y here
    final deg = raw * 180 / math.pi;
    final clampedDeg = deg.clamp(minAngleDeg, maxAngleDeg).toDouble();
    _angleRad = clampedDeg * math.pi / 180.0;

    print("_aimToward - diff: $d, raw: $raw, deg: $deg, clampedDeg: $clampedDeg, _angleRad: $_angleRad");
    _placeProjectileAtMuzzle();
    _updatePreview();
  }

  // 3) Use the helper for muzzle placement:
  void _placeProjectileAtMuzzle() {
    if (_projectile == null) return;
    final p = muzzleCenter + _dirFromAngle(_angleRad) * muzzleOffset;
    _projectile!.position = p;
  }

  void __placeProjectileAtMuzzle() {
    final p = Vector2(
      position.x + muzzleOffset * math.cos(_angleRad),
      position.y + muzzleOffset * math.sin(_angleRad),
    );
    _projectile?.position = p;
  }

  // 4) Use the helper when firing:
  void _fire() {
    if (_projectile == null) return;
    final dir = _dirFromAngle(_angleRad); // <- y inverted
    final v = dir * speed;

    final b = _projectile!;
    _projectile = null;

    final mover = _MovingBubble(bubble: b, grid: grid, pool: pool, speed: v);
    game.add(mover);

    _ensureProjectileReady();
    _updatePreview();
  }

  void _ensureProjectileReady() {
    if (_projectile != null) return;
    final item = grid.nextSpawnColor(); // implement bias toward board colors
    final b = pool.get(item);
    b.settled = false;
    b.priority = 40;
    b.angle = 0;
    b.scale = Vector2.all(1);
    game.add(b);
    _projectile = b;
    _placeProjectileAtMuzzle();
  }

  // 5) And in _updatePreview() for both the start point and the marching dir:
  void _updatePreview() {
    final dots = _dots;
    if (dots == null) return;

    final samples = <Vector2>[];
    var p = muzzleCenter + _dirFromAngle(_angleRad) * muzzleOffset; // start
    var dir = _dirFromAngle(_angleRad); // step

    final left = grid.cellRadius;
    final right = game.size.x - grid.cellRadius;
    final top = grid.topY + grid.cellRadius;
    final bottom = muzzleCenter.y - 8;

    for (int i = 0; i < previewDots * 4; i++) {
      p += dir * previewStep;

      if (p.x <= left || p.x >= right) {
        dir.x = -dir.x; // reflect on side walls
        p.x = p.x.clamp(left, right);
      }

      if (p.y <= top || grid.isNearSettledCenter(p, grid.cellRadius * 1.05)) {
        samples.add(p);
        break;
      }
      if (p.y < bottom) samples.add(p);

      if (samples.length >= previewDots) break;
      if (i % 3 == 0) samples.add(p);
    }
    dots.updatePoints(samples);
  }

  // endregion
}

/// Renders small dots along the computed trajectory.
class TrajectoryDots extends PositionComponent {
  TrajectoryDots({required this.dotCount, super.position})
    : _points = const [],
      super(priority: 55, anchor: Anchor.center);

  final int dotCount;
  List<Vector2> _points;

  void updatePoints(List<Vector2> pts) {
    _points = pts.take(dotCount).toList(growable: false);
  }

  static const _r = 2.5;

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0x66FFFFFF);
    for (final p in _points) {
      canvas.drawCircle(Offset(p.x, p.y), _r, paint);
    }
  }
}

/// Wraps a Bubble with simple movement, wall bounces, and settle logic.
/// When it touches a settled bubble (or ceiling), it snaps to grid and triggers match checks.
class _MovingBubble extends Component with HasGameReference {
  _MovingBubble({
    required this.bubble,
    required this.grid,
    required this.pool,
    required Vector2 speed,
  }) : _v = speed;

  final Bubble bubble;
  final Grid grid;
  final BubblePool pool;

  Vector2 _v;

  @override
  Future<void> onLoad() async {
    // Bubble already added to game by Shooter; just ensure draw order
    bubble.priority = 60;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final sz = game.size;

    // Integrate
    bubble.position += _v * dt;

    // Reflect on walls
    final r = bubble.width / 2;
    if (bubble.x - r <= 0) {
      bubble.x = r;
      _v.x = -_v.x;
    } else if (bubble.x + r >= sz.x) {
      bubble.x = sz.x - r;
      _v.x = -_v.x;
    }

    // Hit ceiling? snap & settle
    final ceiling = grid.topY + grid.cellRadius;
    if (bubble.y - r <= ceiling) {
      _settleHere();
      return;
    }

    // Touching any settled bubble? snap & settle
    if (grid.isNearSettledCenter(bubble.position, grid.cellRadius * 1.02)) {
      _settleHere();
      return;
    }

    // Safety: out of bounds
    if (bubble.y < -r || bubble.y > sz.y + 200) {
      // should not happen; recycle
      pool.release(bubble);
      removeFromParent();
    }
  }

  void _settleHere() {
    final gridCell = grid.snapToCell(bubble.position);
    final world = grid.toWorld(gridCell.x, gridCell.y);
    bubble
      ..position = world
      ..settled = true
      ..row = gridCell.y
      ..col = gridCell.x
      ..priority = 30;

    // Update grid occupancy and resolve matches
    grid.place(bubble);
    grid.resolveAfterPlacement(bubble, pool); // implement: cluster pop + drops

    // This mover is done
    removeFromParent();
  }
}
