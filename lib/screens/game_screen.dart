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

  void _showLevelSelectDialog() {
    _gameBoard.pauseGame();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'SELECT START LEVEL',
          style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level ${_gameBoard.startLevel}',
                style: const TextStyle(color: Colors.white, fontSize: 32),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.cyan, size: 40),
                    onPressed: _gameBoard.startLevel > 1
                        ? () {
                            _gameBoard.setStartLevel(_gameBoard.startLevel - 1);
                            setDialogState(() {});
                          }
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: _gameBoard.startLevel.toDouble(),
                      min: 1,
                      max: GameBoard.maxLevel.toDouble(),
                      divisions: GameBoard.maxLevel - 1,
                      activeColor: Colors.cyan,
                      inactiveColor: Colors.grey,
                      onChanged: (value) {
                        _gameBoard.setStartLevel(value.toInt());
                        setDialogState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.cyan, size: 40),
                    onPressed: _gameBoard.startLevel < GameBoard.maxLevel
                        ? () {
                            _gameBoard.setStartLevel(_gameBoard.startLevel + 1);
                            setDialogState(() {});
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Speed: ${500 - (_gameBoard.startLevel - 1) * 50}ms',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _gameBoard.pauseGame();
            },
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _gameBoard.startGame();
            },
            child: const Text(
              'START GAME',
              style: TextStyle(color: Colors.cyan, fontSize: 16),
            ),
          ),
        ],
      ),
    );
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
        body: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return _buildLandscapeLayout();
              } else {
                return _buildPortraitLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // App bar replacement
        _buildAppBar(),
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
                      child: _buildGameBoardWithPause(),
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
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final buttonSize = (constraints.maxWidth - 24) / 4;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  HoldControlButton(
                    icon: Icons.arrow_left,
                    onPressed: _gameBoard.moveLeft,
                    size: buttonSize,
                  ),
                  ControlButton(
                    icon: Icons.rotate_left,
                    onPressed: _gameBoard.rotateLeft,
                    size: buttonSize,
                  ),
                  ControlButton(
                    icon: Icons.vertical_align_bottom,
                    onPressed: _gameBoard.hardDrop,
                    size: buttonSize,
                  ),
                  HoldControlButton(
                    icon: Icons.arrow_right,
                    onPressed: _gameBoard.moveRight,
                    size: buttonSize,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left controls
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0, right: 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonSize = (constraints.maxWidth / 3.8).clamp(45.0, 70.0);
                return Column(
                  children: [
                    // Title on left side
                    const Text(
                      'TETRIS',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Score on first row (full width)
                    Row(
                      children: [
                        Expanded(child: _buildCompactInfoBox('SCORE', _gameBoard.score.toString())),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Level and Lines on second row
                    Row(
                      children: [
                        Expanded(child: _buildCompactInfoBox('LV', _gameBoard.level.toString())),
                        const SizedBox(width: 4),
                        Expanded(child: _buildCompactInfoBox('LINE', _gameBoard.linesCleared.toString())),
                      ],
                    ),
                    const Spacer(),
                    // Left control buttons (horizontal)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        HoldControlButton(
                          icon: Icons.arrow_left,
                          onPressed: _gameBoard.moveLeft,
                          size: buttonSize,
                        ),
                        SizedBox(width: buttonSize * 0.15),
                        ControlButton(
                          icon: Icons.rotate_left,
                          onPressed: _gameBoard.rotateLeft,
                          size: buttonSize,
                        ),
                        SizedBox(width: buttonSize * 0.15),
                        ControlButton(
                          icon: Icons.vertical_align_bottom,
                          onPressed: _gameBoard.hardDrop,
                          size: buttonSize,
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ),
        // Center - Game board (fills full height)
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Center(
              child: _buildGameBoardWithPause(),
            ),
          ),
        ),
        // Right controls
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(left: 0, top: 8.0, bottom: 8.0, right: 8.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonSize = (constraints.maxWidth / 3.8).clamp(45.0, 70.0);
                return Column(
                  children: [
                    // Settings and pause buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                          onPressed: _showLevelSelectDialog,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _gameBoard.isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _gameBoard.pauseGame,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Next piece on right side
                    NextPieceWidget(piece: _gameBoard.nextPiece),
                    const Spacer(),
                    // Right control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        HoldControlButton(
                          icon: Icons.arrow_drop_down,
                          onPressed: _gameBoard.moveDown,
                          size: buttonSize,
                        ),
                        SizedBox(width: buttonSize * 0.15),
                        ControlButton(
                          icon: Icons.rotate_right,
                          onPressed: _gameBoard.rotate,
                          size: buttonSize,
                        ),
                        SizedBox(width: buttonSize * 0.15),
                        HoldControlButton(
                          icon: Icons.arrow_right,
                          onPressed: _gameBoard.moveRight,
                          size: buttonSize,
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          const Text(
            'TETRIS',
            style: TextStyle(
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 4,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: _showLevelSelectDialog,
              ),
              IconButton(
                icon: Icon(
                  _gameBoard.isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                ),
                onPressed: _gameBoard.pauseGame,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoardWithPause() {
    return Stack(
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
    );
  }

  Widget _buildCompactInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
