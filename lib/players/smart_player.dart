import 'dart:math';

import '../../game_controller.dart';

/// Player 2: heuristic player that
/// (1) uses a checkerboard pattern to cover the board,
/// (2) focuses on neighbors around near-miss guesses.
class HeuristicGopherPlayer extends GopherPlayer {
  final List<Point<int>> _available = [];
  final List<Point<int>> _targets = [];

  HeuristicGopherPlayer({
    required super.name,
    super.rows = 8,
    super.cols = 8,
  }) {
    _resetLists();
  }

  void _resetLists() {
    _available.clear();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        _available.add(Point(r, c));
      }
    }
    _targets.clear();
  }

  @override
  Future<Point<int>> makeMove() async {
    // Slightly longer thinking time to suggest "smarter" logic.
    await Future.delayed(const Duration(milliseconds: 300));

    Point<int>? move;

    // First, try target cells (those near past near-misses).
    while (_targets.isNotEmpty && move == null) {
      final candidate = _targets.removeAt(0);
      final idx = _available.indexOf(candidate);
      if (idx != -1) {
        move = _available.removeAt(idx);
      }
    }

    // If we don't have any (valid) target cells, choose using a pattern.
    if (move == null) {
      // Checkerboard: prefer cells where row + col is even.
      int idx =
      _available.indexWhere((p) => (p.x + p.y) % 2 == 0);
      if (idx == -1) {
        idx = 0; // fallback
      }
      move = _available.removeAt(idx);
    }

    return move;
  }

  @override
  Future<void> resetAsync() async {
    _resetLists();
  }

  @override
  void handleFeedback(GuessResult result, Point<int> position) {
    if (result == GuessResult.nearMiss) {
      // Add neighbors as potential targets.
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = position.x + dr;
          final nc = position.y + dc;
          if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
            final neighbor = Point(nr, nc);
            _addTarget(neighbor);
          }
        }
      }
    }
  }

  void _addTarget(Point<int> point) {
    if (_available.contains(point) && !_targets.contains(point)) {
      _targets.add(point);
    }
  }
}
