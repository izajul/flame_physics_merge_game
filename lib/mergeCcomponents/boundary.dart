import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Bucket extends BodyComponent {
  static const double wallWidth = 0.3;
  static const double bucketHeight = 30;
  static const double bucketWidth = 25;

  final Paint wallPaint = Paint()..color = Colors.orange.shade400;

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = Vector2(0, -bucketHeight/2)
      ..userData = this;

    final body = world.createBody(bodyDef);

    // Create the left wall
    final leftWallShape = PolygonShape()
      ..setAsBox(wallWidth, bucketHeight/2, Vector2(-bucketWidth / 2, bucketHeight / 2), 0);
    body.createFixture(FixtureDef(leftWallShape)..density = 100);

    // Create the bottom wall
    final bottomWallShape = PolygonShape()
      ..setAsBox(bucketWidth / 2 , wallWidth, Vector2(0, bucketHeight), 0);
    body.createFixture(FixtureDef(bottomWallShape)
      ..density = 100
        ..friction=1
    );

    // Create the right wall
    final rightWallShape = PolygonShape()
      ..setAsBox(wallWidth, bucketHeight/2, Vector2(bucketWidth / 2, bucketHeight / 2), 0);
    body.createFixture(FixtureDef(rightWallShape)..density = 100);

    return body;
  }

  @override
  void render(Canvas canvas) {
    // Render the three walls of the bucket
    final leftWall = body.fixtures.first;
    final bottomWall = body.fixtures[1];
    final rightWall = body.fixtures.last;

    // Draw the left wall
    if (leftWall.shape is PolygonShape) {
      final vertices = (leftWall.shape as PolygonShape).vertices;
      final path = Path()..addPolygon(vertices.map((v) => Offset(v.x, v.y)).toList(), true);
      canvas.drawPath(path, wallPaint);
    }

    // Draw the bottom wall
    if (bottomWall.shape is PolygonShape) {
      final vertices = (bottomWall.shape as PolygonShape).vertices;
      final path = Path()..addPolygon(vertices.map((v) => Offset(v.x, v.y)).toList(), true);
      canvas.drawPath(path, wallPaint);
    }

    // Draw the right wall
    if (rightWall.shape is PolygonShape) {
      final vertices = (rightWall.shape as PolygonShape).vertices;
      final path = Path()..addPolygon(vertices.map((v) => Offset(v.x, v.y)).toList(), true);
      canvas.drawPath(path, wallPaint);
    }

    // Render the two rounded corners

    canvas.drawCircle(Offset(-bucketWidth / 2, bucketHeight),wallWidth, wallPaint);
    canvas.drawCircle(Offset(bucketWidth / 2, bucketHeight),wallWidth, wallPaint);

    final _paint = Paint()..color = Colors.green;
    canvas.drawCircle(Offset(-bucketWidth / 2, 0),wallWidth, wallPaint);
    canvas.drawCircle(Offset(bucketWidth / 2, 0),wallWidth, wallPaint);
  }
}
