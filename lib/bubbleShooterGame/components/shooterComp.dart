// In your shooter.dart file
import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

// NOTE: We removed DragCallbacks and TapCallbacks from here
import 'package:flame_physics/bubbleShooterGame/components/pool.dart';

import '../bubbleShooter.dart';
import 'bubbleComp.dart';
import 'gridComponent.dart';

class Shooter extends PositionComponent
    with HasGameReference<BubbleShooterGame> {
  Shooter({
    required this.grid,
    required this.pool,
    this.muzzleOffset = 58,
    this.minAngleDeg = 10,
    this.maxAngleDeg = 170,
    this.speed = 520,
    this.previewDots = 18,
    this.previewStep = 14,
  }) : super(priority: 50, anchor: Anchor.center);

  final Grid grid;
  final BubblePool pool;

  // Config
  final double muzzleOffset;
  final double minAngleDeg;
  final double maxAngleDeg;
  final double speed;
  final int previewDots;
  final double previewStep;

  // State
  double _angleRad = math.pi / 2; // Point straight up by default
  Bubble? _projectile, _nextProjectile;
  TrajectoryDots? _dots;

  @override
  Future<void> onLoad() async {
    // Set position relative to the game size
    position = Vector2(game.size.x / 2, game.size.y - 56);

    _dots = TrajectoryDots(dotCount: previewDots);
    add(_dots!);

    _ensureProjectileReady();
    _updatePreview(); // Show the initial aiming line
  }

  // Helper to get a direction vector from an angle
  Vector2 _dirFromAngle(double angleRadians) =>
      Vector2(math.cos(angleRadians), -math.sin(angleRadians));

  // --- Public Methods (called by the game class) ---

  void aimToward(Vector2 globalTouchPosition) {
    // Prevent aiming below the shooter's horizontal line
    final clampedY = math.min(globalTouchPosition.y, position.y - muzzleOffset);
    final target = Vector2(globalTouchPosition.x, clampedY);

    // Calculate the angle based on the vector from the shooter's
    // world position to the user's touch position.
    final dx = target.x - position.x;
    final dy = -(target.y - position.y); // Y is inverted for math angle

    final rawAngleRad = math.atan2(dy, dx);
    final rawAngleDeg = rawAngleRad * (180 / math.pi);
    final clampedAngleDeg = rawAngleDeg.clamp(minAngleDeg, maxAngleDeg);
    _angleRad = clampedAngleDeg * (math.pi / 180.0);

    _placeProjectileAtMuzzle();
    _updatePreview();
  }

  void fire() {
    if (_projectile == null) return;

    final dir = _dirFromAngle(_angleRad);
    final v = dir * speed;

    final b = _projectile!;
    _projectile = null;

    final mover = _MovingBubble(bubble: b, grid: grid, pool: pool, speed: v);
    game.add(mover);

    grid.removeProjectile();
    _nextProjectile?.removeFromParent();

    _ensureProjectileReady();
    _dots?.updatePoints([]); // Hide preview after firing
  }

  // --- Internal Logic ---

  void _placeProjectileAtMuzzle() {
    if (_projectile == null) return;
    // Projectile's position is absolute (in the game world)
    _projectile!.position = position + _dirFromAngle(_angleRad) * muzzleOffset;
  }

  void _ensureProjectileReady() {
    if (_projectile != null) return;
    final items = grid.nextSpawnColor();
    final b = pool.get(items[0])
      ..settled = false
      ..priority = 40;
    game.add(b); // Add bubble to the main game
    _projectile = b;

    final b2 = pool.get(items[1])
      ..position = position
      ..settled = false
      ..priority = 40;
    game.add(b2); // Add upcoming bubble to the main game
    _nextProjectile = b2;

    _placeProjectileAtMuzzle();
  }

  void _updatePreview() {
    final dots = _dots;
    if (dots == null) return;

    final samples = <Vector2>[];
    // Start the preview from the muzzle, in the shooter's local coordinates
    var p = _dirFromAngle(_angleRad) * muzzleOffset;
    var dir = _dirFromAngle(_angleRad);

    final worldLeft = grid.cellRadius;
    final worldRight = game.size.x - grid.cellRadius;
    final worldTop = grid.topY + grid.cellRadius;

    for (int i = 0; i < 200; i++) {
      // Increased loop limit for safety
      p += dir * previewStep;
      final worldP = p + position; // Convert local point to world for checks

      if (worldP.x <= worldLeft || worldP.x >= worldRight) {
        dir.x = -dir.x;
        p.x = (worldP.x.clamp(worldLeft, worldRight)) - position.x;
      }

      if (worldP.y <= worldTop ||
          grid.isNearSettledCenter(worldP, grid.cellRadius * 1.05)) {
        samples.add(p);
        break;
      }

      if (samples.length < previewDots) {
        samples.add(p);
      } else {
        break;
      }
    }
    dots.updatePoints(samples);
  }

  Future<void> destroy() async {
    _dots?.removeFromParent();
    _projectile?.removeFromParent();
    _nextProjectile?.removeFromParent();
    _projectile = null;
    _nextProjectile = null;

    // Remove the shooter from the game
    removeFromParent();
  }
}

/// Renders small dots along the computed trajectory.
class TrajectoryDots extends PositionComponent {
  TrajectoryDots({required this.dotCount, super.position})
    : _points = const [],
      super(priority: 55, anchor: Anchor.center);

  final int dotCount;
  List<Vector2> _points;

  void updatePoints(List<Vector2> pts) async {
    if (isMounted) {
      _points = pts.take(dotCount).toList(growable: false);
    }
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

// ... (The _MovingBubble class remains the same)
/// Wraps a Bubble with simple movement, wall bounces, and settle logic.
/// When it touches a settled bubble (or ceiling), it snaps to grid and triggers match checks.
class _MovingBubble extends Component with HasGameReference<BubbleShooterGame> {
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

    game.oneShotFired();
    // This mover is done
    removeFromParent();
  }
}
