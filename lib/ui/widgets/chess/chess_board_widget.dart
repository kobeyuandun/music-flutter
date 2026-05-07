import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/chess_provider.dart';
import 'chess_board_painter.dart';

/// 棋盘交互组件：组合 CustomPaint + GestureDetector
class ChessBoardWidget extends StatelessWidget {
  final ChessController controller;

  const ChessBoardWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final screenWidth = MediaQuery.of(context).size.width;
      final cellSize = (screenWidth - 32) / 8;
      final boardWidth = cellSize * 8 + cellSize;
      final boardHeight = cellSize * 9 + cellSize;

      return GestureDetector(
        onTapUp: (details) {
          _handleTap(details.localPosition, cellSize);
        },
        child: CustomPaint(
          size: Size(boardWidth, boardHeight),
          painter: ChessBoardPainter(
            board: controller.board.value,
            selectedPiece: controller.selectedPiece.value,
            validMoves: controller.validMoves.toList(),
            cellSize: cellSize,
          ),
        ),
      );
    });
  }

  void _handleTap(Offset localPosition, double cellSize) {
    final col = ((localPosition.dx - cellSize / 2) / cellSize).round();
    final row = ((localPosition.dy - cellSize / 2) / cellSize).round();

    if (row < 0 || row > 9 || col < 0 || col > 8) return;

    if (controller.selectedPiece.value == null) {
      // 没有选中棋子，尝试选择
      controller.selectPiece(row, col);
    } else {
      // 已选中棋子
      final isValidMove = controller.validMoves.any((p) => p.x == row && p.y == col);
      if (isValidMove) {
        // 走到合法位置
        controller.movePiece(row, col);
      } else {
        // 点击己方其他棋子：换选；点击其他位置：取消选择
        final piece = controller.board.value.pieceAt(row, col);
        if (piece != null && piece.color == controller.currentTurn.value) {
          controller.selectPiece(row, col);
        } else {
          controller.selectedPiece.value = null;
          controller.validMoves.clear();
        }
      }
    }
  }
}
