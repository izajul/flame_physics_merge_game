
import 'package:get/get.dart';

import '../mergeFruitsGame/components/dropper_item.dart';



class ControllerBubbleShooter extends GetxController{
  // late final fruitQueue = <FruitItem>[].obs;
  final scores = 0.obs;
  final isGameOver = false.obs;


  void reset(){
    scores.value = 0;
    isGameOver.value = false;
  }
}