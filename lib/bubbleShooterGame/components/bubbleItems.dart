
import 'dart:math';

import 'package:flutter/material.dart';

enum BubblesItems {
  ball1(1, Colors.orange),
  ball2(2, Colors.purple),
  ball3(3, Colors.green),
  ball4(4, Colors.blue),
  ball5(5, Colors.red),
  ball6(6, Colors.yellowAccent);

  final int ballNumber;
  final Color ballColor;

  const BubblesItems(this.ballNumber, this.ballColor);

  String get fileName => 'ball_$ballNumber.png';

  String get fileFullPath => "assets/images/$fileName";

  static BubblesItems get next => values[Random().nextInt(values.length)];

  static List<BubblesItems> getRandomList(int length, {int set = 5}) {
    final random = Random();
    final minSet = random.nextInt(length - set) + set;

    final List<BubblesItems> list = [];
    var currentItem = random.nextInt(values.length);
    for (var i = 0; i < length; i++) {
      if (i % minSet == 0) {
        currentItem = random.nextInt(values.length);
        list.add(values[currentItem]);
        continue;
      }
      list.add(values[currentItem]);
    }
    // print("list: $list");
    return list;
  }
}