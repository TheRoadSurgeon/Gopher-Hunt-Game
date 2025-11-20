import 'dart:math';

import '../../game_controller.dart';

/// Player 1: purely random, but never repeats a cell within a game.
class RandomGopherPlayer extends GopherPlayer {
  final Random _random = Random();
  final List<Point<int>> _remaining = [];

  RandomGopherPlayer({
    required super.name,
    super.rows = 8,
    super.cols = 8,
  }) {
    _resetRemaining();
  }

  void _resetRemaining() {
    _remaining.clear();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        _remaining.add(Point(r, c));
      }
    }
  }

  @override
  Future<Point<int>> makeMove() async {
    // Simulate a tiny "thinking time".
    await Future.delayed(const Duration(milliseconds: 200));

    if (_remaining.isEmpty) {
      _resetRemaining();
    }

    final idx = _random.nextInt(_remaining.length);
    final move = _remaining.removeAt(idx);
    return move;
  }

  @override
  Future<void> resetAsync() async {
    _resetRemaining();
  }

  @override
  void handleFeedback(GuessResult result, Point<int> position) {
    // Random player ignores feedback.
  }
}
