import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/chess_piece.dart';
import '../../../data/providers/chess_provider.dart';
import '../../widgets/chess/chess_board_widget.dart';

class ChessPage extends StatefulWidget {
  const ChessPage({super.key});

  @override
  State<ChessPage> createState() => _ChessPageState();
}

class _ChessPageState extends State<ChessPage> {
  final ChessController _controller = Get.put(ChessController());

  @override
  void dispose() {
    Get.delete<ChessController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('中国象棋'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 回合指示器
            _buildTurnIndicator(),
            // 棋盘
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: ChessBoardWidget(controller: _controller),
                ),
              ),
            ),
            // 控制按钮
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnIndicator() {
    return Obx(() {
      final isRed = _controller.currentTurn.value == PieceColor.red;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRed ? Colors.red : Colors.black87,
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isRed ? '红方' : '黑方'}走棋',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_controller.isCheck.value && !_controller.isGameOver.value) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '将军!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildControls() {
    return Obx(() {
      if (_controller.isGameOver.value) {
        return _buildGameOverPanel();
      }
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _controller.newGame,
              icon: const Icon(Icons.refresh),
              label: const Text('新游戏'),
            ),
            ElevatedButton.icon(
              onPressed: _controller.moveHistory.isNotEmpty
                  ? _controller.undoMove
                  : null,
              icon: const Icon(Icons.undo),
              label: const Text('悔棋'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGameOverPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final winnerText = _controller.winner.value == PieceColor.red
                ? '红方获胜!'
                : '黑方获胜!';
            final winnerColor = _controller.winner.value == PieceColor.red
                ? Colors.red
                : Colors.black87;
            return Text(
              winnerText,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: winnerColor,
                    fontWeight: FontWeight.bold,
                  ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _controller.newGame,
            icon: const Icon(Icons.refresh),
            label: const Text('再来一局'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
