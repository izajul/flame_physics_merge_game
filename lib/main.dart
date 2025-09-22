import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bubbleShooterGame/bubbleShooter.dart';
import 'bubbleShooterGame/bubbleShooterSreen.dart';
import 'mergeFruitsGame/fruits_merge_screen.dart';

void main() {
  runApp(
    GetMaterialApp(
      title: "Flutter Demo",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff191e23),),
        scaffoldBackgroundColor: Color(0xff191e23),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xff191e23),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: GameDashboard(),
    ),
  );
}

class GameDashboard extends StatelessWidget {
  const GameDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: GridView(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FruitsMergeGameScreen(),
                    ),
                  );
                },
                child: Text("Merge Fruits",textAlign: TextAlign.center,),
              ),
            ),
            AspectRatio(
              aspectRatio: 1,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BubbleShooterGameScreen(),
                    ),
                  );
                },
                child: Text("Bubble Shooter",textAlign: TextAlign.center,),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
