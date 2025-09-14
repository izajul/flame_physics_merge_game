import 'package:flame/game.dart';
import 'package:flame_physics/mergeCcomponents/dropper_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/controller_merge.dart';
import 'mergeCcomponents/dialogs/game_over.dart';
import 'merge_game.dart';

void main() {
  runApp(MaterialApp(home: GameScreen()));
  // runApp(GameWidget.controlled(gameFactory: MyPhysicsGame.new));
}

class GameScreen extends StatelessWidget {
  GameScreen({super.key});

  final _mergeController = Get.put(ControllerMerge());

  final game = GameWidget<MergeGame>.controlled(
    gameFactory: MergeGame.new,
    overlayBuilderMap: {
      MergeGame.gameOverOverlayID: (context, MergeGame game) =>
          GameOverOverlay(game: game),
    },
  );

  @override
  Widget build(BuildContext context) {
    final _fSize = 10;
    return Scaffold(
      backgroundColor: Color(0xff191e23),
      appBar: AppBar(title: const Text('Fruits Merge Challenges',style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),), backgroundColor: Color(0xff191e23),),
      body: Column(
        children: [
          /// all fruits list
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            margin: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...List.generate(FruitItem.values.length, (idx) {
                  final fruit = FruitItem.values[idx];
                  final size = _fSize + (fruit.fruitNumber * 0.7);
                  return Flexible(
                    child: Image(
                      image: AssetImage(fruit.fileFullPath),
                      width: size,
                      height: size,
                    ),
                  );
                }),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// score
                Obx(() {
                  final score = _mergeController.score.value;
                  return Text(
                    "Score: $score",
                    style: TextStyle(fontSize: 22, color: Colors.white54),
                  );
                }),

                /// Fruit queue
                Container(
                  height: 55,
                  width: 155,
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Obx(() {
                      final fruitInQueue = _mergeController.fruitQueue.reversed
                          .toList();
                      return ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        children: List.generate(fruitInQueue.length - 1, (idx) {
                          // final fruit = FruitItem.values[idx];
                          final fruit = fruitInQueue[idx];
                          final size = 10 * fruit.itemSize;
                          // final size = 24 + (fruit.fruitNumber * 0.7);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2.0,
                            ),
                            child: Image(
                              image: AssetImage(fruit.fileFullPath),
                              width: size,
                              height: size,
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          /// main game screen
          Expanded(child: game),
        ],
      ),
    );
  }
}
