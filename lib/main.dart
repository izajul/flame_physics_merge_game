import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'merge_game.dart';

void main() {
  runApp(GameWidget<MergeGame>.controlled(gameFactory: MergeGame.new));
  // runApp(GameWidget.controlled(gameFactory: MyPhysicsGame.new));

}