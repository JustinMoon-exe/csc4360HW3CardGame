import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameLogic(),
      child: MaterialApp(
        title: 'Card Matching Game',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const GameScreen(),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late List<AnimationController> controllers;
  late GameLogic gameLogic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameLogic = Provider.of<GameLogic>(context, listen: false);
      controllers = List.generate(
        16,
            (index) => AnimationController(
          duration: const Duration(milliseconds: 400),
          vsync: this,
        ),
      );
      gameLogic.setControllers(controllers);
      gameLogic.initializeGame();
    });
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Matching Game'),
      ),
      body: Consumer<GameLogic>(
        builder: (context, gameLogic, child) {
          if (gameLogic.gameOver) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'You Won!',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      gameLogic.resetGame();
                    },
                    child: const Text('Play Again'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    return CardWidget(index: index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  final int index;

  const CardWidget({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameLogic>(
      builder: (context, gameLogic, child) {
        final card = gameLogic.cards[index];
        return GestureDetector(
          onTap: () => gameLogic.flipCard(index),
          child: AnimatedBuilder(
            animation: gameLogic.controllers[index],
            builder: (context, child) {
              final rotation = gameLogic.controllers[index].value * 3.14159;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotation),
                alignment: Alignment.center,
                child: card.isFaceUp
                    ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.14159),
                  child: Card(
                    color: Colors.white,
                    child: Center(
                      child: Text(
                        card.value,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                )
                    : Card(
                  color: Colors.blue,
                  child: const Center(
                    child: Icon(Icons.question_mark, size: 24),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class GameCard {
  final String value;
  bool isFaceUp = false;
  bool isMatched = false;

  GameCard(this.value);
}

class GameLogic extends ChangeNotifier {
  List<GameCard> cards = [];
  List<AnimationController> controllers = [];
  int? firstCardIndex;
  bool gameOver = false;

  void setControllers(List<AnimationController> newControllers) {
    controllers = newControllers;
  }

  void initializeGame() {
    const cardValues = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    cards = [...cardValues, ...cardValues]
        .map((value) => GameCard(value))
        .toList()
      ..shuffle();

    firstCardIndex = null;
    gameOver = false;
    notifyListeners();
  }

  void flipCard(int index) {
    if (cards[index].isFaceUp || cards[index].isMatched || gameOver) return;

    cards[index].isFaceUp = true;
    controllers[index].forward();

    if (firstCardIndex == null) {
      firstCardIndex = index;
    } else {
      final firstCard = cards[firstCardIndex!];
      final secondCard = cards[index];

      if (firstCard.value == secondCard.value) {
        firstCard.isMatched = true;
        secondCard.isMatched = true;
        checkGameOver();
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          firstCard.isFaceUp = false;
          secondCard.isFaceUp = false;
          controllers[firstCardIndex!].reverse();
          controllers[index].reverse();
          notifyListeners();
        });
      }

      firstCardIndex = null;
    }

    notifyListeners();
  }

  void checkGameOver() {
    if (cards.every((card) => card.isMatched)) {
      gameOver = true;
      notifyListeners();
    }
  }

  void resetGame() {
    initializeGame();
    for (var controller in controllers) {
      controller.reset();
    }
    notifyListeners();
  }
}
