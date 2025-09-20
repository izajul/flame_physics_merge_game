
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';

// A component that creates a particle explosion effect.
class BubblePopEffect extends PositionComponent {
  final Color color;
  final _random = Random();

  BubblePopEffect({
    required super.position,
    required this.color,
  }):super(priority: 50);

  @override
  Future<void> onLoad() async {
    // A particle system is a component that renders and manages particles.
    final particleComponent = ParticleSystemComponent(
      particle: TranslatedParticle(
        offset: Vector2.zero(), // Start particles at the center
        // A composed particle allows combining multiple particle behaviors
        child: ComposedParticle(
          children: [
            // Generate 15 particles for the explosion
            for (int i = 0; i < 15; i++)
              AcceleratedParticle(
                speed: Vector2(
                  _random.nextDouble() * 200 - 100, // Random horizontal speed
                  _random.nextDouble() * -300,   // Random upward speed
                ),
                acceleration: Vector2(0, 400),   // Gravity
                lifespan: 0.8, // Particle lifetime
                child: CircleParticle(
                  radius: 2.0 + _random.nextDouble() * 2.0, // Random size
                  paint: Paint()..color = color,
                ),
              ),
          ],
        ),
      ),
    );

    add(particleComponent);

    // After 1 second, the entire effect component will be removed.
    add(TimerComponent(period: 1.0, onTick: removeFromParent, removeOnFinish: true));
  }
}