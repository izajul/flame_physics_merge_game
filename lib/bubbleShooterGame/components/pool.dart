
import 'bubbleComp.dart';
import 'bubbleItems.dart';
import 'gridComponent.dart';

class BubblePool {
  final Grid grid;
  final _inactive = <Bubble>[];

  BubblePool({required this.grid});

  Bubble get(BubblesItems item) {
    if (_inactive.isNotEmpty) {
      final b = _inactive.removeLast();
      b.reset(item);
      return b;
    }
    return Bubble(item: item, radius: grid.cellRadius);
  }

  void release(Bubble b) {
    b.removeFromParent();
    _inactive.add(b);
  }
}