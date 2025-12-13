import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_board.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/next_piece_widget.dart';
import '../widgets/control_button.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameBoard _gameBoard;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _gameBoard = GameBoard();
    _gameBoard.addListener(_onGameUpdate);
    _gameBoard.startGame();
  }

  void _onGameUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    _gameBoard.removeListener(_onGameUpdate);
    _gameBoard.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _gameBoard.moveLeft();
        break;
      case LogicalKeyboardKey.arrowRight:
        _gameBoard.moveRight();
        break;
      case LogicalKeyboardKey.arrowDown:
        _gameBoard.moveDown();
        break;
      case LogicalKeyboardKey.arrowUp:
        _gameBoard.rotate();
        break;
      case LogicalKeyboardKey.space:
        _gameBoard.hardDrop();
        break;
      case LogicalKeyboardKey.keyP:
        _gameBoard.pauseGame();
        break;
      case LogicalKeyboardKey.keyR:
        if (_gameBoard.isGameOver) {
          _gameBoard.startGame();
        }
        break;
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'GAME OVER',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: ${_gameBoard.score}',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Level: ${_gameBoard.level}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Lines: ${_gameBoard.linesCleared}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _gameBoard.startGame();
            },
            child: const Text(
              'PLAY AGAIN',
              style: TextStyle(color: Colors.cyan, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show game over dialog when game ends
    if (_gameBoard.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog();
      });
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'TETRIS',
            style: TextStyle(
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 4,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _gameBoard.isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
              ),
              onPressed: _gameBoard.pauseGame,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Score and info section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoBox('SCORE', _gameBoard.score.toString()),
                    _buildInfoBox('LEVEL', _gameBoard.level.toString()),
                    _buildInfoBox('LINES', _gameBoard.linesCleared.toString()),
                  ],
                ),
              ),
              // Game board and next piece
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Game board
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Stack(
                              children: [
                                GameBoardWidget(gameBoard: _gameBoard),
                                if (_gameBoard.isPaused)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black54,
                                      child: const Center(
                                        child: Text(
                                          'PAUSED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Next piece
                      NextPieceWidget(piece: _gameBoard.nextPiece),
                    ],
                  ),
                ),
              ),
              // Controls
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Left controls
                    Row(
                      children: [
                        HoldControlButton(
                          icon: Icons.arrow_left,
                          onPressed: _gameBoard.moveLeft,
                        ),
                        const SizedBox(width: 8),
                        HoldControlButton(
                          icon: Icons.arrow_right,
                          onPressed: _gameBoard.moveRight,
                        ),
                      ],
                    ),
                    // Rotate
                    ControlButton(
                      icon: Icons.rotate_right,
                      onPressed: _gameBoard.rotate,
                    ),
                    // Down controls
                    Row(
                      children: [
                        HoldControlButton(
                          icon: Icons.arrow_drop_down,
                          onPressed: _gameBoard.moveDown,
                        ),
                        const SizedBox(width: 8),
                        ControlButton(
                          icon: Icons.vertical_align_bottom,
                          onPressed: _gameBoard.hardDrop,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan, width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
