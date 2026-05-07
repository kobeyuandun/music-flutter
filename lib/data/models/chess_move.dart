import 'chess_piece.dart';

/// 走棋记录，用于悔棋功能
class ChessMove {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final ChessPiece? capturedPiece; // 被吃的棋子，null表示未吃子

  ChessMove({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.capturedPiece,
  });
}
