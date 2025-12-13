import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'piece.dart';

class GameBoard extends ChangeNotifier {
  static const int rows = 20;
  static const int cols = 10;

  // Board state: null means empty, Color means filled
  List<List<Color?>> board = List.generate(
    rows,
    (_) => List.generate(cols, (_) => null),
  );

  Piece? currentPiece;
  Piece? nextPiece;
  int score = 0;
  int level = 1;
  int startLevel = 1;
  int linesCleared = 0;
  bool isGameOver = false;
  bool isPaused = false;
  Timer? _gameTimer;

  final Random _random = Random();

  static const int maxLevel = 10;

  GameBoard() {
    _initGame();
  }

  void _initGame() {
    board = List.generate(
      rows,
      (_) => List.generate(cols, (_) => null),
    );
    score = 0;
    level = startLevel;
    linesCleared = 0;
    isGameOver = false;
    isPaused = false;
    currentPiece = _generateRandomPiece();
    nextPiece = _generateRandomPiece();
  }

  void setStartLevel(int newLevel) {
    if (newLevel >= 1 && newLevel <= maxLevel) {
      startLevel = newLevel;
      notifyListeners();
    }
  }

  void startGame() {
    _initGame();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    int speed = 500 - (level - 1) * 50;
    if (speed < 50) speed = 50;
    _gameTimer = Timer.periodic(Duration(milliseconds: speed), (_) {
      if (!isPaused && !isGameOver) {
        moveDown();
      }
    });
  }

  void pauseGame() {
    isPaused = !isPaused;
    notifyListeners();
  }

  void _restartTimer() {
    _gameTimer?.cancel();
    _startTimer();
  }

  Piece _generateRandomPiece() {
    PieceType type = PieceType.values[_random.nextInt(PieceType.values.length)];
    return Piece(type: type);
  }

  bool _isValidPosition(Piece piece) {
    for (var cell in piece.cells) {
      int row = cell[0];
      int col = cell[1];

      // Check bounds
      if (row < 0 || row >= rows || col < 0 || col >= cols) {
        return false;
      }

      // Check collision with placed pieces
      if (board[row][col] != null) {
        return false;
      }
    }
    return true;
  }

  void moveLeft() {
    if (currentPiece == null || isGameOver || isPaused) return;

    currentPiece!.x--;
    if (!_isValidPosition(currentPiece!)) {
      currentPiece!.x++;
    }
    notifyListeners();
  }

  void moveRight() {
    if (currentPiece == null || isGameOver || isPaused) return;

    currentPiece!.x++;
    if (!_isValidPosition(currentPiece!)) {
      currentPiece!.x--;
    }
    notifyListeners();
  }

  void moveDown() {
    if (currentPiece == null || isGameOver || isPaused) return;

    currentPiece!.y++;
    if (!_isValidPosition(currentPiece!)) {
      currentPiece!.y--;
      _placePiece();
    }
    notifyListeners();
  }

  void hardDrop() {
    if (currentPiece == null || isGameOver || isPaused) return;

    while (_isValidPosition(currentPiece!)) {
      currentPiece!.y++;
    }
    currentPiece!.y--;
    _placePiece();
    notifyListeners();
  }

  void rotate() {
    if (currentPiece == null || isGameOver || isPaused) return;

    currentPiece!.rotate();
    if (!_isValidPosition(currentPiece!)) {
      // Try wall kick
      int originalX = currentPiece!.x;

      // Try moving left
      currentPiece!.x--;
      if (_isValidPosition(currentPiece!)) {
        notifyListeners();
        return;
      }

      // Try moving right
      currentPiece!.x = originalX + 1;
      if (_isValidPosition(currentPiece!)) {
        notifyListeners();
        return;
      }

      // Try moving 2 left (for I piece)
      currentPiece!.x = originalX - 2;
      if (_isValidPosition(currentPiece!)) {
        notifyListeners();
        return;
      }

      // Try moving 2 right (for I piece)
      currentPiece!.x = originalX + 2;
      if (_isValidPosition(currentPiece!)) {
        notifyListeners();
        return;
      }

      // Rotation not possible, revert
      currentPiece!.x = originalX;
      currentPiece!.rotateBack();
    }
    notifyListeners();
  }

  void rotateLeft() {
    if (currentPiece == null || isGameOver || isPaused) return;

    currentPiece!.rotateBack();
    if (!_isValidPosition(currentPiece!)) {
      // Try wall kick
      int originalX = currentPiece!.x;

      // Try moving left
      currentPiece!.x--;
      if (_isValidPosition(currentPiece!)) {
        notifyListeners();
        return;
      }

      // Try moving right
      currentPiece!.x = originalX + 1;
      if (_isValidPosition(currentPiece!)) {
        notifyListeners();
        return;
      }

      // Try moving 2 left (for I piece)
      currentPiece!.x = originalX - 2;
      if (_isValidPosition(currentPiece!)) {
        notifyListeners();
        return;
      }

      // Try moving 2 right (for I piece)
      currentPiece!.x = originalX + 2;
      if (_isValidPosition(currentPiece!)) {
        notifyListeners();
        return;
      }

      // Rotation not possible, revert
      currentPiece!.x = originalX;
      currentPiece!.rotate();
    }
    notifyListeners();
  }

  void _placePiece() {
    if (currentPiece == null) return;

    // Place the piece on the board
    for (var cell in currentPiece!.cells) {
      int row = cell[0];
      int col = cell[1];
      if (row >= 0 && row < rows && col >= 0 && col < cols) {
        board[row][col] = currentPiece!.color;
      }
    }

    // Check for completed lines
    _clearLines();

    // Spawn new piece
    currentPiece = nextPiece;
    nextPiece = _generateRandomPiece();

    // Check game over
    if (!_isValidPosition(currentPiece!)) {
      isGameOver = true;
      _gameTimer?.cancel();
    }

    notifyListeners();
  }

  void _clearLines() {
    int clearedCount = 0;

    for (int row = rows - 1; row >= 0; row--) {
      bool isLineFull = true;
      for (int col = 0; col < cols; col++) {
        if (board[row][col] == null) {
          isLineFull = false;
          break;
        }
      }

      if (isLineFull) {
        clearedCount++;
        // Remove the line and add empty line at top
        board.removeAt(row);
        board.insert(0, List.generate(cols, (_) => null));
        row++; // Check the same row again
      }
    }

    if (clearedCount > 0) {
      linesCleared += clearedCount;

      // Scoring: 1 line = 100, 2 = 300, 3 = 500, 4 = 800
      switch (clearedCount) {
        case 1:
          score += 100 * level;
          break;
        case 2:
          score += 300 * level;
          break;
        case 3:
          score += 500 * level;
          break;
        case 4:
          score += 800 * level;
          break;
      }

      // Level up every 10 lines (from start level)
      int newLevel = startLevel + (linesCleared ~/ 10);
      if (newLevel > level && newLevel <= maxLevel) {
        level = newLevel;
        _restartTimer();
      }
    }
  }

  int getGhostY() {
    if (currentPiece == null) return 0;

    Piece ghost = currentPiece!.copy();
    while (_isValidPosition(ghost)) {
      ghost.y++;
    }
    ghost.y--;
    return ghost.y;
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}
