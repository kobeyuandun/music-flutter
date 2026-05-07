import 'chess_piece.dart';

/// 中国象棋棋盘状态
class ChessBoard {
  /// 10行9列的棋盘，null表示空位
  List<List<ChessPiece?>> grid;

  ChessBoard() : grid = List.generate(10, (_) => List<ChessPiece?>.filled(9, null)) {
    _setupInitialPosition();
  }

  void _setupInitialPosition() {
    // 黑方棋子（顶部，第0-4行）
    // 第0行：车马象士将士象马车
    grid[0][0] = ChessPiece(type: PieceType.chariot, color: PieceColor.black, row: 0, col: 0);
    grid[0][1] = ChessPiece(type: PieceType.horse, color: PieceColor.black, row: 0, col: 1);
    grid[0][2] = ChessPiece(type: PieceType.elephant, color: PieceColor.black, row: 0, col: 2);
    grid[0][3] = ChessPiece(type: PieceType.advisor, color: PieceColor.black, row: 0, col: 3);
    grid[0][4] = ChessPiece(type: PieceType.king, color: PieceColor.black, row: 0, col: 4);
    grid[0][5] = ChessPiece(type: PieceType.advisor, color: PieceColor.black, row: 0, col: 5);
    grid[0][6] = ChessPiece(type: PieceType.elephant, color: PieceColor.black, row: 0, col: 6);
    grid[0][7] = ChessPiece(type: PieceType.horse, color: PieceColor.black, row: 0, col: 7);
    grid[0][8] = ChessPiece(type: PieceType.chariot, color: PieceColor.black, row: 0, col: 8);

    // 第2行：炮在第1列和第7列
    grid[2][1] = ChessPiece(type: PieceType.cannon, color: PieceColor.black, row: 2, col: 1);
    grid[2][7] = ChessPiece(type: PieceType.cannon, color: PieceColor.black, row: 2, col: 7);

    // 第3行：卒在第0,2,4,6,8列
    for (int c = 0; c <= 8; c += 2) {
      grid[3][c] = ChessPiece(type: PieceType.pawn, color: PieceColor.black, row: 3, col: c);
    }

    // 红方棋子（底部，第5-9行）
    // 第9行：车马相仕帅仕相马车
    grid[9][0] = ChessPiece(type: PieceType.chariot, color: PieceColor.red, row: 9, col: 0);
    grid[9][1] = ChessPiece(type: PieceType.horse, color: PieceColor.red, row: 9, col: 1);
    grid[9][2] = ChessPiece(type: PieceType.elephant, color: PieceColor.red, row: 9, col: 2);
    grid[9][3] = ChessPiece(type: PieceType.advisor, color: PieceColor.red, row: 9, col: 3);
    grid[9][4] = ChessPiece(type: PieceType.king, color: PieceColor.red, row: 9, col: 4);
    grid[9][5] = ChessPiece(type: PieceType.advisor, color: PieceColor.red, row: 9, col: 5);
    grid[9][6] = ChessPiece(type: PieceType.elephant, color: PieceColor.red, row: 9, col: 6);
    grid[9][7] = ChessPiece(type: PieceType.horse, color: PieceColor.red, row: 9, col: 7);
    grid[9][8] = ChessPiece(type: PieceType.chariot, color: PieceColor.red, row: 9, col: 8);

    // 第7行：炮在第1列和第7列
    grid[7][1] = ChessPiece(type: PieceType.cannon, color: PieceColor.red, row: 7, col: 1);
    grid[7][7] = ChessPiece(type: PieceType.cannon, color: PieceColor.red, row: 7, col: 7);

    // 第6行：兵在第0,2,4,6,8列
    for (int c = 0; c <= 8; c += 2) {
      grid[6][c] = ChessPiece(type: PieceType.pawn, color: PieceColor.red, row: 6, col: c);
    }
  }

  /// 获取指定位置的棋子
  ChessPiece? pieceAt(int row, int col) {
    if (row < 0 || row > 9 || col < 0 || col > 8) return null;
    return grid[row][col];
  }

  /// 获取指定颜色的所有棋子
  List<ChessPiece> piecesOfColor(PieceColor color) {
    final pieces = <ChessPiece>[];
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        final piece = grid[r][c];
        if (piece != null && piece.color == color) {
          pieces.add(piece);
        }
      }
    }
    return pieces;
  }

  /// 查找指定颜色的将/帅
  ChessPiece? findKing(PieceColor color) {
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        final piece = grid[r][c];
        if (piece != null && piece.type == PieceType.king && piece.color == color) {
          return piece;
        }
      }
    }
    return null;
  }
}
