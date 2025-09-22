import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart'; // For Curves

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

ParticleSystemComponent makeBlinkingMovingParticles({
  required Vector2 position,
  required Sprite sprite,
  required double itemSize,      // your spread area factor
  int count =5,
  double systemLifespan = 2.0,   // seconds (cloud lifetime)
  double perLifespanMin = 0.8,   // seconds (each sprite's lifetime)
  double perLifespanMax = 1.5,
  double baseSize = 2.0,         // sprite base size in px
  double minScale = 0.1,
  double maxScale = 1,
  int scaleCycles = 4,           // how many in/out pulses during one life
  required Vector2 to // move the whole cloud upward
}) {
  final rnd = Random();

  // Move the WHOLE particle system from (0,0) to systemDrift over systemLifespan.
  final particle = MovingParticle(
    to: to,
    lifespan: systemLifespan,
    child: Particle.generate(
      count: count,
      lifespan: systemLifespan,
      generator: (i) {
        // Random per-sprite properties
        final life = lerpDouble(
          perLifespanMin,
          perLifespanMax,
          rnd.nextDouble(),
        )!;
        final offset = Vector2(
          rnd.nextDouble() * itemSize * 1.5 - itemSize,
          rnd.nextDouble() * itemSize * 1.1 - itemSize,
        );

        // Draw + scale the sprite over time (blink effect) at its local offset.
        return ComputedParticle(
          lifespan: life,
          renderer: (canvas, progress) {
            // progress in [0,1]; make a smooth ping-pong scale curve
            final s = minScale +
                (maxScale - minScale) *
                    0.5 *
                    (1 - cos(2 * pi * scaleCycles * progress.progress));

            final sizeNow = baseSize * s;

            canvas.save();
            // translate to the particle’s local offset; center the sprite
            canvas.translate(offset.x, offset.y);
            canvas.translate(-sizeNow / 2, -sizeNow / 2);

            sprite.render(
              canvas,
              size: Vector2.all(sizeNow),
              overridePaint: Paint()..color = Colors.blue
            );
            canvas.restore();
          },
        );
      },
    ),
  );

  final comp = ParticleSystemComponent(
    position: position,
    particle: particle,
    // removingOnFinish: true, // optional
  );

  return comp;
}
