
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ShimmerLine extends PositionComponent {
  final double shimmerSpeed;
  final double lineThickness;
  final Color baseColor;
  final Color shimmerColor;
  final double shimmerHeight;
  final int shimmerCount; // New property for multiple shimmers

  // Now a list to track each shimmer's progress
  // final List<double> _shimmerProgress = [];

  // Internal state for animation
  double _animationProgress = 0.0;

  ShimmerLine({
    super.key,
    required Vector2 position,
    required double height,
    this.lineThickness = 2.0,
    this.shimmerSpeed = 4.0, // Pixels per second
    this.baseColor = Colors.cyan,
    this.shimmerColor = Colors.white,
    this.shimmerHeight = 4.0,
    this.shimmerCount = 10, // Default to 3 for backward compatibility
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
      shimmerCount: shimmerCount,
      componentHeight: height,
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

    // The total distance a shimmer travels before looping.
    final totalLoopDistance = height + shimmerHeight;

    // Use modulo to wrap the master progress, ensuring the animation loops forever.
    if (_animationProgress > totalLoopDistance) {
      _animationProgress %= totalLoopDistance;
    }
  }

  void moveHorizontallyTo(double x) {
    position = Vector2(x, position.y);
    // final p = body.position;
    // body.setTransform(Vector2(x, p.y), 0);
  }
}

class _ShimmerLinePainter extends CustomPainter {
  final double progress; // The master progress value
  final Color baseColor;
  final Color shimmerColor;
  final double lineThickness;
  final double shimmerHeight;
  final int shimmerCount;
  final double componentHeight; // The actual height of the line

  _ShimmerLinePainter({
    required this.progress,
    required this.baseColor,
    required this.shimmerColor,
    required this.lineThickness,
    required this.shimmerHeight,
    required this.shimmerCount,
    required this.componentHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;

    // 1. Paint the base line
    final basePaint = Paint()
      ..color = baseColor.withOpacity(0.1)
      ..strokeWidth = lineThickness
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(width / 2, 0),
      Offset(width / 2, componentHeight),
      basePaint,
    );

    // 2. Calculate spacing and draw each shimmer
    final shimmerPaint = Paint()
      ..strokeWidth = lineThickness
      ..style = PaintingStyle.stroke;

    final totalLoopDistance = componentHeight + shimmerHeight;
    // Calculate the space between each shimmer
    final spacing = totalLoopDistance / shimmerCount;

    for (int i = 0; i < shimmerCount; i++) {
      // THE KEY FIX: Calculate each shimmer's position based on the master
      // progress and add the spacing offset. The modulo wraps it around perfectly.
      final currentShimmerProgress = (progress + (i * spacing)) % totalLoopDistance;

      final shimmerTop = currentShimmerProgress - shimmerHeight;
      final shimmerBottom = currentShimmerProgress;

      // Create the gradient for this specific shimmer
      shimmerPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, shimmerColor, Colors.transparent],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromPoints(
          Offset(0, shimmerTop),
          Offset(width, shimmerBottom),
        ),
      );

      // Draw the line with the gradient shader applied
      canvas.drawLine(
        Offset(width / 2, 0),
        Offset(width / 2, componentHeight),
        shimmerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}