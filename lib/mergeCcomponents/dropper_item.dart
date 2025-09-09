import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_physics/mergeCcomponents/body_with_data_component.dart';
import 'package:flame_physics/merge_game.dart';
import 'package:flutter/material.dart';

const dropperItemSize = 5.0;

enum DropperItemColor {
  pink,
  blue,
  green,
  yellow;

  static DropperItemColor get randomColor =>
      DropperItemColor.values[Random().nextInt(DropperItemColor.values.length)];

  String get fileName =>
      'alien${toString().split('.').last.capitalize}_round.png';
}

extension on String {
  String get capitalize =>
      characters.first.toUpperCase() + characters.skip(1).toLowerCase().join();
}

class DropperItem extends BodyWithDataComponent<MergeGame>
    with ContactCallbacks {
  DropperItem(
    Vector2 position,
    Sprite sprite, {
    required DropperItemColor color,
  }) : super(
         renderBody: false,
         extraData: color,
         bodyDef: BodyDef()
           ..position = position
           ..type = BodyType.dynamic
           ..angularDamping = 0.9
           ..linearDamping = 0.9
           ..gravityOverride = Vector2(0, 150),
         fixtureDefs: [
           FixtureDef(CircleShape()..radius = dropperItemSize / 2)
             ..restitution = 0.8
             ..density = 0.85
             ..friction = 0.9,
         ],
         children: [
           SpriteComponent(
             anchor: Anchor.center,
             sprite: sprite,
             size: Vector2.all(dropperItemSize),
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

    var interceptVelocity =
        (contact.bodyA.linearVelocity - contact.bodyB.linearVelocity).length
            .abs();

    if (bodyAUserData is DropperItem && bodyBUserData is DropperItem) {
      // print(
      //   "interceptVelocity = $interceptVelocity, bodyAUserData = $bodyAUserData, bodyBUserData = $bodyBUserData",
      // );

      final item1 = bodyAUserData as BodyWithDataComponent;
      final item2 = bodyBUserData as BodyWithDataComponent;

      final color1 = item1.extraData as DropperItemColor;
      final color2 = item2.extraData as DropperItemColor;

      if (color1 == color2) {
        // if (item1.hashCode < item2.hashCode) {
        //   // Calculate the midpoint of the collision for the new item's position
        final collisionPosition = (bodyA.position + bodyB.position) / 2;
        //
        //   // Determine the new color (e.g., a function to get the next color in a sequence)
        //   // final newColor = getNextColor(color1);
        //   game.mergeToNewOne(collisionPosition);
        //   // print("color1=$color1, color2 = $color2, position = $collisionPosition");
        // }
        game.mergeToNewOne(collisionPosition);
        removeFromParent();
      }
    }

    super.beginContact(other, contact);
  }
}
