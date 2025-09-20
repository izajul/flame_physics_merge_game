import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

// A component that displays a score number that floats up and fades away.
class ScorePopup extends TextComponent {
  ScorePopup({required int points, required super.position})
    : super(
        text: '+$points',
        anchor: Anchor.center,
        priority: 100, // Ensure it renders on top of other components
      );

  @override
  Future<void> onLoad() async {
    // Define the appearance of the text
    textRenderer = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        // Adding a stroke to make the text more readable
        shadows: [
          Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
    );

    // The effect sequence: move, fade, and then remove the component.
    final effect = SequenceEffect([
      // Move the component up by 60 pixels over 1.5 seconds.
      MoveByEffect(
        Vector2(0, -60),
        EffectController(duration: 1.5, curve: Curves.easeOut),
      ),

      // Fade out the component over 0.5 seconds.
      // FIX: Replaced FadeOutEffect with the new OpacityEffect.fadeOut
      // OpacityEffect.fadeOut(EffectController(duration: 0.5)),
      // When the sequence is complete, remove the component from the game.
      RemoveEffect(),
    ]);

    add(effect);
  }
}
