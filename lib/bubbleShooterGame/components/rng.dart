import 'dart:math';
import 'bubbleItems.dart';

class GameRng {
  final Random _r;
  GameRng([int seed = 1337]) : _r = Random(seed);
  BubblesItems randomItem(Set<BubblesItems> allowed) {
    final list = allowed.toList();
    return list[_r.nextInt(list.length)];
  }
}