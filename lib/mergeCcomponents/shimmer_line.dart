
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ShimmerLine extends PositionComponent {
  final double shimmerSpeed;
  final double lineThickness;
  final Color baseColor;
  final Color shimmerColor;
  final double shimmerHeight;

  // Internal state for animation
  double _animationProgress = 0.0;

  ShimmerLine({
    super.key,
    required Vector2 position,
    required double height,
    this.lineThickness = 2.0,
    this.shimmerSpeed = 150.0, // Pixels per second
    this.baseColor = Colors.cyan,
    this.shimmerColor = Colors.white,
    this.shimmerHeight = 50.0,
  }) : super(
    priority: -1,
    position: position,
    size: Vector2(lineThickness, height), // Width is thickness, height is length
  );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // The CustomPainter does all the rendering work
    final painter = _ShimmerLinePainter(
      progress: _animationProgress,
      baseColor: baseColor,
      shimmerColor: shimmerColor,
      lineThickness: lineThickness,
      shimmerHeight: shimmerHeight,
    );
    // We use size (the component's dimensions) to paint onto the canvas
    painter.paint(canvas, size.toSize());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update the animation progress based on delta time and speed
    // The progress will be a value representing the top position of the shimmer
    _animationProgress += shimmerSpeed * dt;

    // If the shimmer has moved past the line's height plus its own height,
    // reset it to the top to create a loop.
    if (_animationProgress > height + shimmerHeight) {
      _animationProgress = 0;
    }
  }

  void moveHorizontallyTo(double x) {
    position = Vector2(x, position.y);
    // final p = body.position;
    // body.setTransform(Vector2(x, p.y), 0);
  }
}

class _ShimmerLinePainter extends CustomPainter {
  final double progress; // The current vertical position of the shimmer
  final Color baseColor;
  final Color shimmerColor;
  final double lineThickness;
  final double shimmerHeight;

  _ShimmerLinePainter({
    required this.progress,
    required this.baseColor,
    required this.shimmerColor,
    required this.lineThickness,
    required this.shimmerHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // 1. Paint the base line
    // This is the static, semi-transparent line in the background.
    final basePaint = Paint()
      // ..color = baseColor.withOpacity(0.3)
      ..color = baseColor.withOpacity(0.08)
      ..strokeWidth = lineThickness
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(width / 2, 0),
      Offset(width / 2, height),
      basePaint,
    );

    // 2. Paint the shimmering glow
    // This is the gradient that moves.
    final shimmerPaint = Paint()
      ..strokeWidth = lineThickness
      ..style = PaintingStyle.stroke;

    // Define the vertical position for the gradient
    final shimmerTop = progress - shimmerHeight;
    final shimmerBottom = progress;

    // Create a linear gradient for the glow effect
    shimmerPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent, // Fades out at the top
        shimmerColor,       // Brightest in the middle
        Colors.transparent, // Fades out at the bottom
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(
      Rect.fromPoints(
        Offset(0, shimmerTop),
        Offset(width, shimmerBottom),
      ),
    );

    // Draw the shimmering line on top of the base line
    canvas.drawLine(
      Offset(width / 2, 0),
      Offset(width / 2, height),
      shimmerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // We must return true to repaint on every frame for the animation to work
    return true;
  }
}