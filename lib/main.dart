import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Matching Game',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF282A36),
        primaryColor: const Color(0xFF44475A),
        cardColor: const Color(0xFF44475A),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFF8F8F2)),
        ),
      ),
      home: ChangeNotifierProvider(
        create: (context) => GameLogic(),
        child: const GameScreen(),
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

    // Delay accessing the provider using WidgetsBinding
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
        backgroundColor: const Color(0xFF44475A),
      ),
      body: Column(
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
          onTap: () => gameLogic.flipCard(index, context),
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
                    color: const Color(0xFF6272A4),
                    child: Center(
                      child: Text(
                        card.value,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Color(0xFFF8F8F2),
                        ),
                      ),
                    ),
                  ),
                )
                    : Card(
                  color: const Color(0xFF44475A),
                  child: const Center(
                    child: Icon(
                      Icons.question_mark,
                      size: 24,
                      color: Color(0xFFF8F8F2),
                    ),
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

  void flipCard(int index, BuildContext context) {
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
        checkGameOver(context);
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

  void checkGameOver(BuildContext context) {
    if (cards.every((card) => card.isMatched)) {
      gameOver = true;
      showVictoryDialog(context);
    }
  }

  void showVictoryDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF282A36),
          title: const Text('You Won!', style: TextStyle(color: Color(0xFFF8F8F2))),
          content: const Text('Congratulations! You have matched all the cards.',
              style: TextStyle(color: Color(0xFFF8F8F2))),
          actions: <Widget>[
            TextButton(
              child: const Text('Restart', style: TextStyle(color: Color(0xFF50FA7B))),
              onPressed: () {
                Navigator.of(context).pop();
                initializeGame();
              },
            ),
          ],
        );
      },
    );
  }
}
