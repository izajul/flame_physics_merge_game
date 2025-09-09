
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Wall extends BodyComponent {
  Wall(Vector2 position,Sprite sprite)
    : super(
        renderBody: false,
        bodyDef: BodyDef()
          ..position = position
          ..type = BodyType.static,
        fixtureDefs: [
          FixtureDef(PolygonShape()..setAsBoxXY(1, 6.44), friction: 0.3),
        ],
        children: [
          SpriteComponent(
            anchor: Anchor.bottomCenter,
            sprite: sprite,
            size: Vector2(2, 6.44),
            position: Vector2(0, 0),
          ),
        ],
      );
}
