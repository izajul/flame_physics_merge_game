import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_physics/mergeCcomponents/body_with_data_component.dart';
import 'package:flame_physics/merge_game.dart';

enum FruitItem {
  item_1(itemSize: 2.0, fruitNumber: 1),
  item_2(itemSize: 2.5, fruitNumber: 2),
  item_3(itemSize: 3.0, fruitNumber: 3),
  item_4(itemSize: 3.5, fruitNumber: 4),
  item_5(itemSize: 4.0, fruitNumber: 5),
  item_6(itemSize: 4.5, fruitNumber: 6),
  item_7(itemSize: 5.0, fruitNumber: 7),
  item_8(itemSize: 5.5, fruitNumber: 8),
  item_9(itemSize: 6.0, fruitNumber: 9),
  item_10(itemSize: 6.5, fruitNumber: 10),
  item_11(itemSize: 7.0, fruitNumber: 11),
  item_12(itemSize: 7.5, fruitNumber: 12),
  item_13(itemSize: 8.0, fruitNumber: 13),
  item_14(itemSize: 8.5, fruitNumber: 14),
  item_15(itemSize: 9.0, fruitNumber: 15),
  item_16(itemSize: 9.5, fruitNumber: 16);

  final double itemSize;
  final int fruitNumber;

  const FruitItem({required this.itemSize, required this.fruitNumber});

  String get fileName => "$name.png";

  String fileNameByNumber(int number) => "item_$number.png";

  static FruitItem getByNumber(int number) {
    if (number > 16) return item_16;
    for (var item in FruitItem.values) {
      if (item.fruitNumber == number) {
        return item;
      }
    }
    return item_1;
  }

  // get random item, the random max item will be first 6 item only
  static FruitItem get randomItem => FruitItem.values[Random().nextInt(6)];
}

class DropperItem extends BodyWithDataComponent<MergeGame>
    with ContactCallbacks {
  DropperItem(Vector2 position, Sprite sprite, {required FruitItem fruit})
    : super(
        renderBody: false,
        extraData: fruit,
        bodyDef: BodyDef()
          ..position = position
          ..type = BodyType.dynamic
          ..angularDamping = 0.9
          ..linearDamping = 0.9
          ..gravityOverride = Vector2(0, 150),
        fixtureDefs: [
          FixtureDef(CircleShape()..radius = fruit.itemSize / 2)
            ..restitution = 0.8
            ..density = 0.85
            ..friction = 0.9,
        ],
        children: [
          SpriteComponent(
            anchor: Anchor.center,
            sprite: sprite,
            size: Vector2.all(fruit.itemSize),
            position: Vector2(0, 0),
          ),
        ],
      );

  // final Sprite _sprite;

  @override
  void update(double dt) {
    super.update(dt);

    if (!body.isAwake) {
      // removeFromParent();
    }

    if (position.x > camera.visibleWorldRect.right + 10 ||
        position.x < camera.visibleWorldRect.left - 10) {
      // removeFromParent();
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    final bodyA = contact.bodyA;
    final bodyB = contact.bodyB;
    final bodyAUserData = bodyA.userData;
    final bodyBUserData = bodyB.userData;

    if (bodyAUserData is DropperItem && bodyBUserData is DropperItem) {
      final item1 = bodyAUserData as BodyWithDataComponent;
      final item2 = bodyBUserData as BodyWithDataComponent;

      final fruit1 = item1.extraData as FruitItem;
      final fruit2 = item2.extraData as FruitItem;

      if (fruit1 == fruit2) {
        final collisionPosition = (bodyA.position + bodyB.position) / 2;
        game.mergeToNewOne(collisionPosition, fruit1.fruitNumber);
        removeFromParent();
      }
    }

    super.beginContact(other, contact);
  }
}
