import 'dart:math'; // for Point<int>

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_controller.dart';
import 'players/random_player.dart';
import 'players/smart_player.dart';

void main() {
  runApp(const GopherGameApp());
}

class GopherGameApp extends StatelessWidget {
  const GopherGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gopher Hunt Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final RandomGopherPlayer _player1;
  late final HeuristicGopherPlayer _player2;
  late GopherGameController _controller;

  bool _isRunning = false;
  bool _loopActive = false;

  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _player1 = RandomGopherPlayer(name: 'Random Bot');
    _player2 = HeuristicGopherPlayer(name: 'Heuristic Bot');
    _controller = GopherGameController(
      player1: _player1,
      player2: _player2,
    );
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _startGame() {
    // Make sure not to restart the game if it is already running
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _controller.resetGame();
    });

    // Reset players without waiting, as per spec.
    _player1.resetAsync();
    _player2.resetAsync();

    _runGameLoop();
  }

  void _stopGame() {
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _runGameLoop() async {
    if (_loopActive) return;
    _loopActive = true;

    while (mounted && _isRunning && _controller.winnerName == null) {
      final currentTurn = _controller.currentTurn;
      final currentPlayer =
      currentTurn == PlayerTurn.player1 ? _player1 : _player2;

      // Ask player for the next move.
      Point<int> move;
      try {
        move = await currentPlayer.makeMove();
      } catch (_) {
        if (!mounted) break;
        setState(() {
          _isRunning = false;
        });
        break;
      }

      if (!mounted || !_isRunning) break;

      // Register guess and update state.
      final result = _controller.registerGuess(move);
      currentPlayer.handleFeedback(result, move);

      setState(() {
        // Rebuild boards + log.
      });

      // After the frame is drawn, scroll the log to the bottom.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollLogToBottom();
      });

      if (result == GuessResult.hit) {
        if (!mounted) break;
        setState(() {
          _isRunning = false;
        });
        _showWinnerSnackBar();
        break;
      }

      // Pause 2 seconds between moves.
      await Future.delayed(const Duration(seconds: 2));
      if (!_isRunning || !mounted) break;

      _controller.toggleTurn();
      if (!mounted) break;
      setState(() {});
    }

    _loopActive = false;
  }

  void _scrollLogToBottom() {
    if (!_logScrollController.hasClients) return;
    try {
      _logScrollController.jumpTo(
        _logScrollController.position.maxScrollExtent,
      );
    } catch (_) {
      // If the position isn't ready yet, just ignore.
    }
  }

  void _showWinnerSnackBar() {
    final winner = _controller.winnerName;
    if (winner == null) return;
    final guesses = _controller.guessCounter;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$winner found the gopher in $guesses guesses!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _isRunning;
    final gopherPos = GopherGameController.formatPosition(
      _controller.gopherRow,
      _controller.gopherCol,
    );

    final currentPlayerName = !_isRunning
        ? 'None'
        : (_controller.currentTurn == PlayerTurn.player1
        ? _player1.name
        : _player2.name);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gopher Hunt Game'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildControlRow(),
              const SizedBox(height: 8),
              _buildStatusSection(isRunning, currentPlayerName, gopherPos),
              const SizedBox(height: 8),

              // Middle section: two boards + log, sized to fit on screen.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double spacing = 8.0;
                    const double logHeight = 110.0; // reserved for log
                    const double boardExtra =
                    40.0; // per-board overhead for title + padding

                    // Available height for the *square parts* of the boards
                    double availableHeight = constraints.maxHeight -
                        logHeight -
                        2 * spacing -
                        2 * boardExtra;

                    if (availableHeight < 0) availableHeight = 0;

                    // BoardSize is limited by half the available height AND the width,
                    // so the boards stay square and fully visible.
                    final double boardSize = availableHeight <= 0
                        ? 0
                        : min(availableHeight / 2, constraints.maxWidth);

                    return Column(
                      children: [
                        _buildBoardColumn(
                          title: 'Player 1 (${_player1.name})',
                          board: _controller.board1,
                          playerColor: Colors.blue,
                          boardSize: boardSize,
                        ),
                        const SizedBox(height: spacing),
                        _buildBoardColumn(
                          title: 'Player 2 (${_player2.name})',
                          board: _controller.board2,
                          playerColor: Colors.green,
                          boardSize: boardSize,
                        ),
                        const SizedBox(height: spacing),
                        SizedBox(
                          height: logHeight,
                          child: _buildGuessLog(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _isRunning ? null : _startGame,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
        ),
        ElevatedButton.icon(
          onPressed: _isRunning ? _stopGame : null,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
        ),
        ElevatedButton.icon(
          onPressed: () => SystemNavigator.pop(),
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Exit'),
        ),
      ],
    );
  }

  Widget _buildStatusSection(
      bool isRunning,
      String currentPlayerName,
      String gopherPos,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status: ${isRunning ? 'Running' : 'Stopped'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text('Current turn: '),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                currentPlayerName,
                key: ValueKey<String>(currentPlayerName),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Gopher: $gopherPos'),
      ],
    );
  }

  Widget _buildBoardColumn({
    required String title,
    required List<List<CellState>> board,
    required Color playerColor,
    required double boardSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: playerColor,
          ),
        ),
        const SizedBox(height: 4),
        if (boardSize > 0)
          Center(
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: _buildBoard(board),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildBoard(List<List<CellState>> board) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemCount: 64,
      itemBuilder: (context, index) {
        final row = index ~/ 8;
        final col = index % 8;
        final cell = board[row][col];
        final isGopher = _controller.isGopherCell(row, col);

        Color baseColor;
        if (cell.result == null) {
          baseColor = Colors.grey.shade300;
        } else {
          switch (cell.result!) {
            case GuessResult.hit:
              baseColor = Colors.green.shade400;
              break;
            case GuessResult.nearMiss:
              baseColor = Colors.orange.shade300;
              break;
            case GuessResult.miss:
              baseColor = Colors.blueGrey.shade200;
              break;
          }
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: baseColor,
            border: Border.all(color: Colors.black12),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isGopher)
                  const Icon(
                    Icons.pets,
                    size: 18,
                  ),
                if (cell.guessNumber != null)
                  Text(
                    '${cell.guessNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuessLog() {
    final log = _controller.guessLog;

    if (log.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: const Text('No guesses yet.'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        controller: _logScrollController,
        itemCount: log.length,
        itemBuilder: (context, index) {
          final entry = log[index];
          final pos = GopherGameController.formatPosition(
            entry.row,
            entry.col,
          );

          final isPlayer1 = entry.playerName == _player1.name;
          final tileColor =
          isPlayer1 ? Colors.blue.shade50 : Colors.green.shade50;

          String resultText;
          switch (entry.result) {
            case GuessResult.hit:
              resultText = 'Success';
              break;
            case GuessResult.nearMiss:
              resultText = 'Near miss';
              break;
            case GuessResult.miss:
              resultText = 'Complete miss';
              break;
          }

          return Container(
            color: tileColor,
            child: ListTile(
              dense: true,
              leading: Text('#${entry.guessNumber}'),
              title: Text('${entry.playerName} guessed $pos'),
              subtitle: Text('Result: $resultText'),
            ),
          );
        },
      ),
    );
  }
}
