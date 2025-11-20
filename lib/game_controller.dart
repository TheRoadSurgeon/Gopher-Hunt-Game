import 'dart:math';

/// Outcome of a single guess.
enum GuessResult { hit, nearMiss, miss }

/// Which player's turn it currently is.
enum PlayerTurn { player1, player2 }

/// Per-cell state for a player's board.
class CellState {
  final int? guessNumber;
  final GuessResult? result;

  const CellState({this.guessNumber, this.result});
}

/// One entry in the guess log list.
class GuessLogEntry {
  final int guessNumber;
  final String playerName;
  final int row;
  final int col;
  final GuessResult result;

  const GuessLogEntry({
    required this.guessNumber,
    required this.playerName,
    required this.row,
    required this.col,
    required this.result,
  });
}

/// Abstract interface that all players (bots) must implement.
abstract class GopherPlayer {
  final String name;
  final int rows;
  final int cols;

  GopherPlayer({
    required this.name,
    this.rows = 8,
    this.cols = 8,
  });

  /// Called when it is this player's turn. Must pick the next move.
  Future<Point<int>> makeMove();

  /// Called at the beginning of a new game. The main class does not await this.
  Future<void> resetAsync();

  /// Called by the main game after evaluating the player's guess.
  void handleFeedback(GuessResult result, Point<int> position);
}

/// Main game controller class that holds the logic and state of the game.
class GopherGameController {
  final GopherPlayer player1;
  final GopherPlayer player2;
  final int rows;
  final int cols;
  final Random _random = Random();

  late int gopherRow;
  late int gopherCol;
  String? winnerName;
  PlayerTurn currentTurn = PlayerTurn.player1;
  int guessCounter = 0;

  late List<List<CellState>> board1;
  late List<List<CellState>> board2;
  final List<GuessLogEntry> guessLog = [];

  GopherGameController({
    required this.player1,
    required this.player2,
    this.rows = 8,
    this.cols = 8,
  }) {
    resetGame();
  }

  /// Reset core game state: gopher position, boards, guess counter, logs, turn.
  void resetGame() {
    winnerName = null;
    guessCounter = 0;
    currentTurn = PlayerTurn.player1;
    _placeGopherRandomly();

    board1 = List.generate(
      rows,
          (_) => List.generate(cols, (_) => const CellState(), growable: false),
      growable: false,
    );

    board2 = List.generate(
      rows,
          (_) => List.generate(cols, (_) => const CellState(), growable: false),
      growable: false,
    );

    guessLog.clear();
  }

  void _placeGopherRandomly() {
    gopherRow = _random.nextInt(rows);
    gopherCol = _random.nextInt(cols);
  }

  bool isGopherCell(int row, int col) => row == gopherRow && col == gopherCol;

  List<List<CellState>> boardFor(PlayerTurn turn) =>
      turn == PlayerTurn.player1 ? board1 : board2;

  /// Evaluate the given move for the CURRENT player and update boards + log.
  GuessResult registerGuess(Point<int> move) {
    final result = _evaluateGuess(move);
    guessCounter++;

    final row = move.x;
    final col = move.y;
    final cell = CellState(guessNumber: guessCounter, result: result);

    final board = boardFor(currentTurn);
    if (row >= 0 && row < rows && col >= 0 && col < cols) {
      board[row][col] = cell;
    }

    final playerName =
    currentTurn == PlayerTurn.player1 ? player1.name : player2.name;

    guessLog.add(
      GuessLogEntry(
        guessNumber: guessCounter,
        playerName: playerName,
        row: row,
        col: col,
        result: result,
      ),
    );

    if (result == GuessResult.hit) {
      winnerName = playerName;
    }

    return result;
  }

  void toggleTurn() {
    currentTurn = currentTurn == PlayerTurn.player1
        ? PlayerTurn.player2
        : PlayerTurn.player1;
  }

  GuessResult _evaluateGuess(Point<int> move) {
    final row = move.x;
    final col = move.y;

    if (row == gopherRow && col == gopherCol) {
      return GuessResult.hit;
    }

    final dr = (row - gopherRow).abs();
    final dc = (col - gopherCol).abs();
    if (dr <= 1 && dc <= 1) {
      return GuessResult.nearMiss;
    }

    return GuessResult.miss;
  }

  /// For displaying coordinates in the UI.
  static String formatPosition(int row, int col) {
    return '(${row + 1}, ${col + 1})';
  }
}
