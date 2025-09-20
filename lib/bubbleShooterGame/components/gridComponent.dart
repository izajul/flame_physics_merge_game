import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'dart:math' as math;
import 'dart:math' show Point;
import 'package:flame_physics/bubbleShooterGame/components/pool.dart';

import '../bubbleShooter.dart';
import 'bubbleComp.dart';
import 'bubbleItems.dart';

/// Hex-like packed grid for Bubble Shooter using odd-r offset rows.
/// Circles are arranged with:
///  - horizontal step = 2 * cellRadius
///  - vertical step   = sqrt(3) * cellRadius
/// Odd rows are shifted +cellRadius in X.
class Grid extends Component with HasGameReference<BubbleShooterGame> {
  Grid({
    required this.cellRadius,
    this.topY = 0.0,
    this.clusterMin = 3,
    int? rngSeed,
  }) : _rng = math.Random(rngSeed ?? 1337),
       w = cellRadius * 2,
       v =
           cellRadius * math.sqrt1_2 * 0 +
           cellRadius * math.sqrt(3); // = r*sqrt(3)

  /// Bubble radius (px)
  final double cellRadius;

  /// Y of the top “ceiling” line for the first row of bubbles.
  final double topY;

  /// Minimum same-color group size to pop.
  final int clusterMin;

  /// Horizontal spacing (diameter).
  final double w;

  /// Vertical spacing between row centers (r * sqrt(3)).
  final double v;

  /// Occupancy map: (col,row) -> Bubble
  final Map<Point<int>, Bubble> _cells = {};

  /// Cached RNG for spawn biasing/fallback.
  final math.Random _rng;

  // ---------------------------
  // Coordinates
  // ---------------------------

  /// Convert (col,row) to world center position.
  Vector2 toWorld(int col, int row) {
    final double baseX = cellRadius + (row.isOdd ? cellRadius : 0.0);
    final double x = baseX + col * w;
    final double y = topY + cellRadius + row * v;
    return Vector2(x, y);
  }

  /// Nearest grid cell for a world position (best-effort snapping).
  Point<int> snapToCell(Vector2 worldPos) {
    // Initial row guess
    final double ry = (worldPos.y - (topY + cellRadius)) / v;
    int row = ry.round().clamp(0, 1000000);

    // Initial col guess with row parity offset
    double baseX = cellRadius + (row.isOdd ? cellRadius : 0.0);
    final double cx = (worldPos.x - baseX) / w;
    int col = cx.round();

    // Refine by checking the closest among candidate neighbors
    final candidates = <Point<int>>{
      Point(col, row),
      Point(col - 1, row),
      Point(col + 1, row),
      Point(col, row - 1),
      Point(col, row + 1),
      if (row.isOdd) Point(col + 1, row - 1) else Point(col - 1, row - 1),
      if (row.isOdd) Point(col + 1, row + 1) else Point(col - 1, row + 1),
    };

    double bestD2 = double.infinity;
    Point<int> best = Point(col, row);
    for (final c in candidates) {
      if (c.y < 0) continue; // no negative rows
      final wc = toWorld(c.x, c.y);
      final d2 = (wc - worldPos).length2;
      if (d2 < bestD2) {
        bestD2 = d2;
        best = c;
      }
    }
    return best;
  }

  /// Returns whether any settled bubble center is within (cellRadius + threshold)
  /// of point [p]. The caller typically passes ~1.02 * cellRadius.
  bool isNearSettledCenter(Vector2 p, double threshold) {
    final double limit = cellRadius + threshold;
    final double limit2 = limit * limit;

    // Compute row range to inspect
    final double ry = (p.y - (topY + cellRadius)) / v;
    final int r0 = math.max(0, ry.floor() - 2);
    final int r1 = math.max(0, ry.ceil() + 2);

    for (int row = r0; row <= r1; row++) {
      final double baseX = cellRadius + (row.isOdd ? cellRadius : 0.0);
      final double cx = (p.x - baseX) / w;
      final int c0 = cx.floor() - 2;
      final int c1 = cx.ceil() + 2;

      for (int col = c0; col <= c1; col++) {
        final bubble = _cells[Point(col, row)];
        if (bubble == null) continue;
        final wc = toWorld(col, row);
        if ((wc - p).length2 <= limit2) return true;
      }
    }
    return false;
  }

  // ---------------------------
  // Occupancy & neighbors
  // ---------------------------

  bool isOccupied(Point<int> cell) => _cells.containsKey(cell);

  Bubble? bubbleAt(Point<int> cell) => _cells[cell];

  BubblesItems? itemAt(Point<int> cell) => _cells[cell]?.item;

  Iterable<Point<int>> get occupiedCells => _cells.keys;

  /// Odd-r neighbors (6) for (col,row).
  Iterable<Point<int>> neighbors(Point<int> c) sync* {
    final int col = c.x;
    final int row = c.y;
    if (row.isOdd) {
      yield Point(col - 1, row);
      yield Point(col + 1, row);
      yield Point(col, row - 1);
      yield Point(col + 1, row - 1);
      yield Point(col, row + 1);
      yield Point(col + 1, row + 1);
    } else {
      yield Point(col - 1, row);
      yield Point(col + 1, row);
      yield Point(col - 1, row - 1);
      yield Point(col, row - 1);
      yield Point(col - 1, row + 1);
      yield Point(col, row + 1);
    }
  }

  // ---------------------------
  // Placement & resolution
  // ---------------------------

  /// Place a bubble into the grid at its current (row,col) and world position.
  /// Assumes you've already set bubble.row, bubble.col, bubble.settled = true.
  void place(Bubble b) {
    final key = Point(b.col, b.row);
    _cells[key] = b;
  }

  /// After placing a bubble: pop clusters and drop unattached bubbles.
  void resolveAfterPlacement(Bubble placed, BubblePool pool) {
    final start = Point(placed.col, placed.row);
    final match = _collectSameColorCluster(start, placed.item);

    if (match.length >= clusterMin) {
      // Pop the cluster
      for (final cell in match) {
        final bub = _cells.remove(cell);
        if (bub != null) {
          // Optionally: play pop effect here.
          pool.release(bub);
          game.showPopEffect(bub);
        }
      }
      // Drop unattached bubbles (not connected to top row)
      _dropUnattached(pool);
    }
  }

  // ---------------------------
  // Spawn bias & seeding
  // ---------------------------

  /// managing queue of bubbles to spawn
  /// max 2 bubbles at a time
  final List<BubblesItems> _spawnQueue = [];

  /// Bias next spawn to colors currently present on the board;
  /// if empty, fall back to any enum value.
  List<BubblesItems> nextSpawnColor() {

    // if(_spawnQueue.length == 2){
    //   _spawnQueue.removeAt(0);
    // }

    if (_cells.isEmpty) {
      final all = BubblesItems.values;
      return [all[_rng.nextInt(all.length)], all[_rng.nextInt(all.length)]];
    }

    final present = _cells.values.map((b) => b.item).toSet().toList();
    // return present[_rng.nextInt(present.length)];
    if(_spawnQueue.isEmpty){
      _spawnQueue.add(present[_rng.nextInt(present.length)]);
      _spawnQueue.add(present[_rng.nextInt(present.length)]);
    }else {
      _spawnQueue.add(present[_rng.nextInt(present.length)]);
    }
    // return _spawnQueue[0];
    return _spawnQueue;
  }

  void removeProjectile(){
    if(_spawnQueue.isNotEmpty){
      _spawnQueue.removeAt(0);
    }
  }

  void swipeQueue() {
    _spawnQueue.reverse();
  }

  /// Quickly fill a few top rows with settled bubbles for testing.
  /// Call from onLoad after adding this Grid to game.
  Future<void> seedInitialRows(BubblePool pool, {int rows = 4}) async {
    if (game.size.x == 0) return;
    for (int row = 0; row < rows; row++) {
      final int cols = _countFittableColsForRow(row);
      for (int col = 0; col < cols; col++) {
        final item = _randomAnyColor();
        final b = pool.get(item);
        b
          ..settled = true
          ..row = row
          ..col = col
          ..priority = 30
          ..position = toWorld(col, row);
        game.add(b);
        _cells[Point(col, row)] = b;
      }
    }
  }

  // ---------------------------
  // Internals
  // ---------------------------

  List<Point<int>> _collectSameColorCluster(
    Point<int> start,
    BubblesItems color,
  ) {
    final visited = <Point<int>>{};
    final stack = <Point<int>>[start];

    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      if (visited.contains(p)) continue;
      final bub = _cells[p];
      if (bub == null || bub.item != color) continue;
      visited.add(p);

      for (final n in neighbors(p)) {
        final nb = _cells[n];
        if (nb != null && nb.item == color && !visited.contains(n)) {
          stack.add(n);
        }
      }
    }
    return visited.toList(growable: false);
  }

  void _dropUnattached(BubblePool pool) {
    if (_cells.isEmpty) return;

    // 1) Mark all bubbles connected to the ceiling (row == 0) as "anchored".
    final anchored = <Point<int>>{};
    final q = <Point<int>>[];

    // Enqueue all occupied cells in row 0
    for (final entry in _cells.entries) {
      if (entry.key.y == 0) q.add(entry.key);
    }

    while (q.isNotEmpty) {
      final p = q.removeLast();
      if (anchored.contains(p)) continue;
      anchored.add(p);

      for (final n in neighbors(p)) {
        if (_cells.containsKey(n) && !anchored.contains(n)) {
          q.add(n);
        }
      }
    }

    // 2) Anything not anchored must fall (remove & recycle)
    final toRemove = <Point<int>>[];
    for (final cell in _cells.keys) {
      if (!anchored.contains(cell)) {
        toRemove.add(cell);
      }
    }

    for (final cell in toRemove) {
      final bub = _cells.remove(cell);
      if (bub != null) {
        // Optional: animate falling; for now, recycle
        pool.release(bub);
      }
    }
  }

  int _countFittableColsForRow(int row) {
    final double width = game.size.x;
    int col = 0;
    while (true) {
      final x = toWorld(col, row).x;
      if (x > width - cellRadius) break;
      col++;
    }
    return col;
  }

  BubblesItems _randomAnyColor() {
    final all = BubblesItems.values;
    return all[_rng.nextInt(all.length)];
  }
}
