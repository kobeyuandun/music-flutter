import 'dart:math';
import 'package:flutter/material.dart';
import '../../../data/models/chess_piece.dart';
import '../../../data/models/chess_board.dart';

/// 中国象棋棋盘绘制器
class ChessBoardPainter extends CustomPainter {
  final ChessBoard board;
  final ChessPiece? selectedPiece;
  final List<Point<int>> validMoves;
  final double cellSize;

  ChessBoardPainter({
    required this.board,
    this.selectedPiece,
    this.validMoves = const [],
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGrid(canvas);
    _drawPalaceDiagonals(canvas);
    _drawPositionMarkers(canvas);
    _drawRiverText(canvas);
    _drawValidMoveHints(canvas);
    _drawPieces(canvas);
    _drawSelectionHighlight(canvas);
  }

  /// 绘制棋盘背景
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDEB887) // 木质底色
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 外边框
    final borderPaint = Paint()
      ..color = const Color(0xFF5D3A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final padding = cellSize * 0.1;
    canvas.drawRect(
      Rect.fromLTWH(
        cellSize / 2 - padding,
        cellSize / 2 - padding,
        cellSize * 8 + padding * 2,
        cellSize * 9 + padding * 2,
      ),
      borderPaint,
    );
  }

  /// 绘制网格线
  void _drawGrid(Canvas canvas) {
    final linePaint = Paint()
      ..color = const Color(0xFF5D3A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 横线（10条）
    for (int row = 0; row < 10; row++) {
      final y = cellSize / 2 + row * cellSize;
      canvas.drawLine(
        Offset(cellSize / 2, y),
        Offset(cellSize / 2 + 8 * cellSize, y),
        linePaint,
      );
    }

    // 竖线
    for (int col = 0; col < 9; col++) {
      if (col == 0 || col == 8) {
        // 左右两条竖线贯穿整个棋盘
        final x = cellSize / 2 + col * cellSize;
        canvas.drawLine(
          Offset(x, cellSize / 2),
          Offset(x, cellSize / 2 + 9 * cellSize),
          linePaint,
        );
      } else {
        // 中间竖线在楚河汉界处断开
        final x = cellSize / 2 + col * cellSize;
        // 上半部分
        canvas.drawLine(
          Offset(x, cellSize / 2),
          Offset(x, cellSize / 2 + 4 * cellSize),
          linePaint,
        );
        // 下半部分
        canvas.drawLine(
          Offset(x, cellSize / 2 + 5 * cellSize),
          Offset(x, cellSize / 2 + 9 * cellSize),
          linePaint,
        );
      }
    }
  }

  /// 绘制九宫格对角线
  void _drawPalaceDiagonals(Canvas canvas) {
    final linePaint = Paint()
      ..color = const Color(0xFF5D3A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 上方九宫格（第0-2行，第3-5列）
    canvas.drawLine(
      Offset(cellSize / 2 + 3 * cellSize, cellSize / 2),
      Offset(cellSize / 2 + 5 * cellSize, cellSize / 2 + 2 * cellSize),
      linePaint,
    );
    canvas.drawLine(
      Offset(cellSize / 2 + 5 * cellSize, cellSize / 2),
      Offset(cellSize / 2 + 3 * cellSize, cellSize / 2 + 2 * cellSize),
      linePaint,
    );

    // 下方九宫格（第7-9行，第3-5列）
    canvas.drawLine(
      Offset(cellSize / 2 + 3 * cellSize, cellSize / 2 + 7 * cellSize),
      Offset(cellSize / 2 + 5 * cellSize, cellSize / 2 + 9 * cellSize),
      linePaint,
    );
    canvas.drawLine(
      Offset(cellSize / 2 + 5 * cellSize, cellSize / 2 + 7 * cellSize),
      Offset(cellSize / 2 + 3 * cellSize, cellSize / 2 + 9 * cellSize),
      linePaint,
    );
  }

  /// 绘制炮和兵位的十字标记
  void _drawPositionMarkers(Canvas canvas) {
    final markerPositions = [
      // 炮位
      const Point(2, 1), const Point(2, 7),
      const Point(7, 1), const Point(7, 7),
      // 兵/卒位
      const Point(3, 0), const Point(3, 2), const Point(3, 4), const Point(3, 6), const Point(3, 8),
      const Point(6, 0), const Point(6, 2), const Point(6, 4), const Point(6, 6), const Point(6, 8),
    ];

    for (final pos in markerPositions) {
      _drawCrossMarker(canvas, pos.x, pos.y);
    }
  }

  /// 在指定位置绘制十字标记
  void _drawCrossMarker(Canvas canvas, int row, int col) {
    final cx = cellSize / 2 + col * cellSize;
    final cy = cellSize / 2 + row * cellSize;
    final d = cellSize * 0.1; // 标记到交叉点的距离
    final len = cellSize * 0.12; // 标记线长度

    final paint = Paint()
      ..color = const Color(0xFF5D3A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 根据位置决定画哪些方向的标记（避免画出棋盘边界）
    // 右上
    if (col < 8 && row > 0) {
      canvas.drawLine(Offset(cx + d, cy - d), Offset(cx + d + len, cy - d), paint);
      canvas.drawLine(Offset(cx + d, cy - d), Offset(cx + d, cy - d - len), paint);
    }
    // 左上
    if (col > 0 && row > 0) {
      canvas.drawLine(Offset(cx - d, cy - d), Offset(cx - d - len, cy - d), paint);
      canvas.drawLine(Offset(cx - d, cy - d), Offset(cx - d, cy - d - len), paint);
    }
    // 右下
    if (col < 8 && row < 9) {
      canvas.drawLine(Offset(cx + d, cy + d), Offset(cx + d + len, cy + d), paint);
      canvas.drawLine(Offset(cx + d, cy + d), Offset(cx + d, cy + d + len), paint);
    }
    // 左下
    if (col > 0 && row < 9) {
      canvas.drawLine(Offset(cx - d, cy + d), Offset(cx - d - len, cy + d), paint);
      canvas.drawLine(Offset(cx - d, cy + d), Offset(cx - d, cy + d + len), paint);
    }
  }

  /// 绘制楚河汉界文字
  void _drawRiverText(Canvas canvas) {
    final fontSize = cellSize * 0.38;
    final textStyle = TextStyle(
      color: const Color(0xFF5D3A1A),
      fontSize: fontSize,
      fontFamily: 'serif',
      fontWeight: FontWeight.bold,
    );

    // 楚河（左侧）
    final leftText = TextPainter(
      text: TextSpan(text: '楚  河', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    leftText.paint(
      canvas,
      Offset(
        cellSize / 2 + 1.5 * cellSize - leftText.width / 2,
        cellSize / 2 + 4.5 * cellSize - leftText.height / 2,
      ),
    );

    // 汉界（右侧）
    final rightText = TextPainter(
      text: TextSpan(text: '汉  界', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    rightText.paint(
      canvas,
      Offset(
        cellSize / 2 + 6.5 * cellSize - rightText.width / 2,
        cellSize / 2 + 4.5 * cellSize - rightText.height / 2,
      ),
    );
  }

  /// 绘制合法走法提示
  void _drawValidMoveHints(Canvas canvas) {
    for (final move in validMoves) {
      final cx = cellSize / 2 + move.y * cellSize;
      final cy = cellSize / 2 + move.x * cellSize;

      final target = board.pieceAt(move.x, move.y);
      if (target != null) {
        // 吃子位置：画红色圆圈
        final paint = Paint()
          ..color = Colors.red.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawCircle(Offset(cx, cy), cellSize * 0.42, paint);
      } else {
        // 空位：画半透明圆点
        final paint = Paint()
          ..color = Colors.green.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), cellSize * 0.12, paint);
      }
    }
  }

  /// 绘制所有棋子
  void _drawPieces(Canvas canvas) {
    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 9; col++) {
        final piece = board.pieceAt(row, col);
        if (piece != null) {
          _drawPiece(canvas, piece, row, col);
        }
      }
    }
  }

  /// 绘制单个棋子
  void _drawPiece(Canvas canvas, ChessPiece piece, int row, int col) {
    final cx = cellSize / 2 + col * cellSize;
    final cy = cellSize / 2 + row * cellSize;
    final radius = cellSize * 0.42;

    // 棋子阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + 1.5, cy + 1.5), radius, shadowPaint);

    // 棋子底色
    final fillPaint = Paint()
      ..color = const Color(0xFFF5DEB3) // 小麦色
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    // 棋子边框
    final borderColor = piece.color == PieceColor.red
        ? const Color(0xFFCC0000)
        : const Color(0xFF222222);
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

    // 内圈
    final innerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(cx, cy), radius - 4, innerPaint);

    // 棋子文字
    final textColor = piece.color == PieceColor.red
        ? const Color(0xFFCC0000)
        : const Color(0xFF222222);
    final textPainter = TextPainter(
      text: TextSpan(
        text: piece.character,
        style: TextStyle(
          color: textColor,
          fontSize: cellSize * 0.38,
          fontWeight: FontWeight.bold,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  /// 绘制选中棋子高亮
  void _drawSelectionHighlight(Canvas canvas) {
    if (selectedPiece == null) return;

    final cx = cellSize / 2 + selectedPiece!.col * cellSize;
    final cy = cellSize / 2 + selectedPiece!.row * cellSize;
    final radius = cellSize * 0.46;

    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  @override
  bool shouldRepaint(covariant ChessBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.selectedPiece != selectedPiece ||
        oldDelegate.validMoves != validMoves ||
        oldDelegate.cellSize != cellSize;
  }
}
