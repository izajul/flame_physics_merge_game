import 'dart:ui';
import 'package:flame_physics/bubbleShooterGame/bubbleShooter.dart';
import 'package:flutter/material.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final BubbleShooterGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dim background
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.45)),
        ),
        // Centered glass card
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(rect),
                        child: const Text(
                          'Game Over',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white, // masked by shader
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle (optional score/hint)
                      Text(
                        'The fruits reached the limit line!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GhostButton(
                            label: 'Exit',
                            onPressed: () async {
                              // Optional: Navigator.pop(context);
                              // or keep it disabled if you don't have a parent route
                              // game.overlays.remove(MergeGame.gameOverOverlayID);
                              // await game.restartGame();
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 12),
                          _PrimaryButton(
                            label: 'Retry',
                            onPressed: () async {
                              await game.restartGame();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style:
          ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: const Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
          ).copyWith(
            overlayColor: WidgetStatePropertyAll(
              Colors.white.withOpacity(0.08),
            ),
          ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}
