/// 棋子类型
enum PieceType {
  king, // 将/帅
  advisor, // 士/仕
  elephant, // 象/相
  horse, // 马
  chariot, // 车
  cannon, // 炮
  pawn, // 兵/卒
}

/// 棋子颜色
enum PieceColor { red, black }

/// 中国象棋棋子
class ChessPiece {
  final PieceType type;
  final PieceColor color;
  int row; // 0-9, 0为黑方顶部, 9为红方底部
  int col; // 0-8

  ChessPiece({
    required this.type,
    required this.color,
    required this.row,
    required this.col,
  });

  /// 棋子上显示的中文字符
  String get character {
    const redChars = {
      PieceType.king: '帅',
      PieceType.advisor: '仕',
      PieceType.elephant: '相',
      PieceType.horse: '馬',
      PieceType.chariot: '車',
      PieceType.cannon: '炮',
      PieceType.pawn: '兵',
    };
    const blackChars = {
      PieceType.king: '将',
      PieceType.advisor: '士',
      PieceType.elephant: '象',
      PieceType.horse: '马',
      PieceType.chariot: '车',
      PieceType.cannon: '砲',
      PieceType.pawn: '卒',
    };
    return color == PieceColor.red
        ? redChars[type]!
        : blackChars[type]!;
  }

  ChessPiece copyWith({int? row, int? col}) {
    return ChessPiece(
      type: type,
      color: color,
      row: row ?? this.row,
      col: col ?? this.col,
    );
  }
}
