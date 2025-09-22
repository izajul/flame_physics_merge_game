import 'package:flame/game.dart';
import 'package:flame_physics/bubbleShooterGame/bubbleShooter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/controller_bubbleShooter.dart';
import 'components/dialogs/game_over.dart';

class BubbleShooterGameScreen extends StatelessWidget {
  BubbleShooterGameScreen({super.key});

  final _controller = Get.put(ControllerBubbleShooter())..reset();

  final game = GameWidget<BubbleShooterGame>.controlled(
    gameFactory: BubbleShooterGame.new,
    overlayBuilderMap: { "GameOverMenu": (context, BubbleShooterGame game) =>
          GameOverOverlay(game: game),
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// score
            Obx(() {
              final score = _controller.scores.value;
              return Text(
                "Score: $score",
                style: TextStyle(fontSize: 22, color: Colors.white54),
              );
            }),
            /// main game screen
            Expanded(child: game),
          ],
        ),
      ),
    );
  }
}