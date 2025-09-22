
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import 'dropper_item.dart';

/// Horizontal sensor line that ends the game when touched by a fruit.
class GameOverLine extends PositionComponent with ContactCallbacks {
  final double width;        // same as bucket width
  final double y;            // world Y position (a bit below the rim at y=0)
  final double thickness;    // very thin
  final Paint linePaint;

  GameOverLine({
    required this.width,
    required this.y,
    this.thickness = 0.1,
    Color color = const Color(0x28ffffff),
  }) : linePaint = Paint()
    ..color = color
    ..strokeWidth = 0.5;


  @override
  FutureOr<void> onLoad() {
    position = position = Vector2(0, y);
    super.onLoad();
  }

  // @override
  // Body createBody() {
  //   final def = BodyDef()
  //     ..type = BodyType.static
  //     ..position = Vector2(0, y)   // place in world space
  //     ..userData = this;
  //
  //   final body = world.createBody(def);
  //
  //   // Thin sensor “bar” spanning full width.
  //   final shape = PolygonShape()
  //     ..setAsBox((width / 2), thickness / 2, Vector2.zero(), 0);
  //
  //   body.createFixture(
  //     FixtureDef(shape)
  //       ..isSensor = true             // IMPORTANT: sensor, not solid
  //       ..density = 0
  //       ..friction = 0
  //       ..restitution = 0,
  //   );
  //
  //   return body;
  // }

  @override
  void render(Canvas canvas) {
    // Simple visual: a red line across the screen
    // (body is at (0, y); we draw a line centered there).
    final halfW = (width / 2)-1;
    final p1 = Offset(-halfW, 0);
    final p2 = Offset( halfW, 0);
    // canvas.drawLine(p1, p2, linePaint);



    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(-halfW, 0, halfW*2, thickness),
      Radius.circular(5),
    ), linePaint);


  }

  @override
  void beginContact(Object other, Contact contact) {
    // End game only for dynamic fruits.
    if (other is DropperItem && other.body.bodyType == BodyType.dynamic) {
      // game.onGameOver(); // call back into the game
    }
    super.beginContact(other, contact);
  }
}
