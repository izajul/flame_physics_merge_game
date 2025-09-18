import 'package:flame/components.dart';
import 'bubbleItems.dart';

class ImagesCache {
  ImagesCache._();
  static final instance = ImagesCache._();
  final Map<BubblesItems, Sprite> _byItem = {};

  Future<void> preload() async {
    for (final item in BubblesItems.values) {
      _byItem[item] = await Sprite.load(item.fileName);
    }
  }
  Sprite of(BubblesItems item) => _byItem[item]!;
}