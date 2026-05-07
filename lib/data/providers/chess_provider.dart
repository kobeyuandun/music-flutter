import 'dart:math';
import 'package:get/get.dart';
import '../models/chess_piece.dart';
import '../models/chess_board.dart';
import '../models/chess_move.dart';

class ChessController extends GetxController {
  // 响应式状态
  final Rx<ChessBoard> board = ChessBoard().obs;
  final Rx<PieceColor> currentTurn = PieceColor.red.obs;
  final Rx<ChessPiece?> selectedPiece = Rx<ChessPiece?>(null);
  final RxList<ChessMove> moveHistory = <ChessMove>[].obs;
  final RxList<Point<int>> validMoves = <Point<int>>[].obs;
  final RxBool isCheck = false.obs;
  final Rx<PieceColor?> winner = Rx<PieceColor?>(null);
  final RxBool isGameOver = false.obs;

  /// 选择棋子
  void selectPiece(int row, int col) {
    if (isGameOver.value) return;

    final piece = board.value.pieceAt(row, col);
    if (piece == null) return;
    if (piece.color != currentTurn.value) return;

    selectedPiece.value = piece;
    validMoves.value = _getValidMoves(piece);
  }

  /// 移动棋子
  void movePiece(int toRow, int toCol) {
    final piece = selectedPiece.value;
    if (piece == null) return;
    if (isGameOver.value) return;

    final isValid = validMoves.any((p) => p.x == toRow && p.y == toCol);
    if (!isValid) return;

    // 记录被吃的棋子
    final capturedPiece = board.value.pieceAt(toRow, toCol);

    // 记录走棋历史
    moveHistory.add(ChessMove(
      fromRow: piece.row,
      fromCol: piece.col,
      toRow: toRow,
      toCol: toCol,
      capturedPiece: capturedPiece,
    ));

    // 执行移动
    board.value.grid[piece.row][piece.col] = null;
    board.value.grid[toRow][toCol] = piece;
    piece.row = toRow;
    piece.col = toCol;

    // 清除选择状态
    selectedPiece.value = null;
    validMoves.clear();

    // 切换回合
    currentTurn.value = currentTurn.value == PieceColor.red
        ? PieceColor.black
        : PieceColor.red;

    // 检查将军和将死
    isCheck.value = _isKingInCheck(currentTurn.value);
    if (_isCheckmate(currentTurn.value)) {
      isGameOver.value = true;
      winner.value = currentTurn.value == PieceColor.red
          ? PieceColor.black
          : PieceColor.red;
    }

    board.refresh();
  }

  /// 悔棋
  void undoMove() {
    if (moveHistory.isEmpty) return;
    if (isGameOver.value) {
      isGameOver.value = false;
      winner.value = null;
    }

    final lastMove = moveHistory.removeLast();

    // 还原棋子位置
    final piece = board.value.pieceAt(lastMove.toRow, lastMove.toCol)!;
    board.value.grid[lastMove.toRow][lastMove.toCol] = null;
    board.value.grid[lastMove.fromRow][lastMove.fromCol] = piece;
    piece.row = lastMove.fromRow;
    piece.col = lastMove.fromCol;

    // 恢复被吃的棋子
    if (lastMove.capturedPiece != null) {
      board.value.grid[lastMove.toRow][lastMove.toCol] = lastMove.capturedPiece;
    }

    // 切换回合
    currentTurn.value = currentTurn.value == PieceColor.red
        ? PieceColor.black
        : PieceColor.red;

    // 清除选择
    selectedPiece.value = null;
    validMoves.clear();

    // 重新计算将军状态
    isCheck.value = _isKingInCheck(currentTurn.value);
    board.refresh();
  }

  /// 新游戏
  void newGame() {
    board.value = ChessBoard();
    currentTurn.value = PieceColor.red;
    selectedPiece.value = null;
    moveHistory.clear();
    validMoves.clear();
    isCheck.value = false;
    winner.value = null;
    isGameOver.value = false;
  }

  // ========== 走法计算 ==========

  /// 获取棋子的所有合法走法（过滤掉会导致己方被将军的走法）
  List<Point<int>> _getValidMoves(ChessPiece piece) {
    final rawMoves = _getRawMoves(piece);
    return rawMoves.where((move) {
      return !_wouldResultInCheck(piece, move.x, move.y);
    }).toList();
  }

  /// 获取棋子的原始走法（不考虑将军约束）
  List<Point<int>> _getRawMoves(ChessPiece piece) {
    switch (piece.type) {
      case PieceType.king:
        return _getKingMoves(piece);
      case PieceType.advisor:
        return _getAdvisorMoves(piece);
      case PieceType.elephant:
        return _getElephantMoves(piece);
      case PieceType.horse:
        return _getHorseMoves(piece);
      case PieceType.chariot:
        return _getChariotMoves(piece);
      case PieceType.cannon:
        return _getCannonMoves(piece);
      case PieceType.pawn:
        return _getPawnMoves(piece);
    }
  }

  // 四个正方向: [行偏移, 列偏移]
  static const List<List<int>> _orthogonal = [
    [0, 1],
    [0, -1],
    [1, 0],
    [-1, 0],
  ];

  // 四个斜方向: [行偏移, 列偏移]
  static const List<List<int>> _diagonal = [
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1],
  ];

  /// 将/帅：九宫格内一步直行
  List<Point<int>> _getKingMoves(ChessPiece piece) {
    final moves = <Point<int>>[];

    for (final dir in _orthogonal) {
      final nr = piece.row + dir[0];
      final nc = piece.col + dir[1];

      // 九宫格范围限制
      if (piece.color == PieceColor.red) {
        if (nr < 7 || nr > 9 || nc < 3 || nc > 5) continue;
      } else {
        if (nr < 0 || nr > 2 || nc < 3 || nc > 5) continue;
      }

      final target = board.value.pieceAt(nr, nc);
      if (target == null || target.color != piece.color) {
        moves.add(Point(nr, nc));
      }
    }

    return moves;
  }

  /// 士/仕：九宫格内一步斜行
  List<Point<int>> _getAdvisorMoves(ChessPiece piece) {
    final moves = <Point<int>>[];

    for (final dir in _diagonal) {
      final nr = piece.row + dir[0];
      final nc = piece.col + dir[1];

      // 九宫格范围限制
      if (piece.color == PieceColor.red) {
        if (nr < 7 || nr > 9 || nc < 3 || nc > 5) continue;
      } else {
        if (nr < 0 || nr > 2 || nc < 3 || nc > 5) continue;
      }

      final target = board.value.pieceAt(nr, nc);
      if (target == null || target.color != piece.color) {
        moves.add(Point(nr, nc));
      }
    }

    return moves;
  }

  /// 象/相：田字斜走，不能过河，蹩象眼
  List<Point<int>> _getElephantMoves(ChessPiece piece) {
    final moves = <Point<int>>[];
    // [行偏移, 列偏移]
    const elephantDirs = [
      [2, 2],
      [2, -2],
      [-2, 2],
      [-2, -2],
    ];

    for (final dir in elephantDirs) {
      final dr = dir[0];
      final dc = dir[1];
      final nr = piece.row + dr;
      final nc = piece.col + dc;

      // 边界检查
      if (nr < 0 || nr > 9 || nc < 0 || nc > 8) continue;

      // 不能过河
      if (piece.color == PieceColor.red && nr < 5) continue;
      if (piece.color == PieceColor.black && nr > 4) continue;

      // 蹩象眼检测：象眼位置在(row + dr/2, col + dc/2)
      final eyeRow = piece.row + dr ~/ 2;
      final eyeCol = piece.col + dc ~/ 2;
      if (board.value.pieceAt(eyeRow, eyeCol) != null) continue;

      final target = board.value.pieceAt(nr, nc);
      if (target == null || target.color != piece.color) {
        moves.add(Point(nr, nc));
      }
    }

    return moves;
  }

  /// 马：日字走法，蹩马腿
  List<Point<int>> _getHorseMoves(ChessPiece piece) {
    final moves = <Point<int>>[];

    // [蹩马腿行偏移, 蹩马腿列偏移, 目标行偏移, 目标列偏移]
    const legAndMoves = [
      [1, 0, 2, 1],
      [1, 0, 2, -1],
      [-1, 0, -2, 1],
      [-1, 0, -2, -1],
      [0, 1, 1, 2],
      [0, 1, -1, 2],
      [0, -1, 1, -2],
      [0, -1, -1, -2],
    ];

    for (final item in legAndMoves) {
      final legDr = item[0];
      final legDc = item[1];
      final moveDr = item[2];
      final moveDc = item[3];

      final nr = piece.row + moveDr;
      final nc = piece.col + moveDc;

      if (nr < 0 || nr > 9 || nc < 0 || nc > 8) continue;

      // 蹩马腿检测
      final legRow = piece.row + legDr;
      final legCol = piece.col + legDc;
      if (board.value.pieceAt(legRow, legCol) != null) continue;

      final target = board.value.pieceAt(nr, nc);
      if (target == null || target.color != piece.color) {
        moves.add(Point(nr, nc));
      }
    }

    return moves;
  }

  /// 车：直线任意格，路径无阻挡
  List<Point<int>> _getChariotMoves(ChessPiece piece) {
    final moves = <Point<int>>[];

    for (final dir in _orthogonal) {
      final dr = dir[0];
      final dc = dir[1];
      int nr = piece.row + dr;
      int nc = piece.col + dc;

      while (nr >= 0 && nr <= 9 && nc >= 0 && nc <= 8) {
        final target = board.value.pieceAt(nr, nc);
        if (target == null) {
          moves.add(Point(nr, nc));
        } else {
          if (target.color != piece.color) {
            moves.add(Point(nr, nc)); // 吃子
          }
          break; // 遇到棋子停止
        }
        nr += dr;
        nc += dc;
      }
    }

    return moves;
  }

  /// 炮：移动同车，吃子需隔一子（炮架）
  List<Point<int>> _getCannonMoves(ChessPiece piece) {
    final moves = <Point<int>>[];

    for (final dir in _orthogonal) {
      final dr = dir[0];
      final dc = dir[1];
      int nr = piece.row + dr;
      int nc = piece.col + dc;
      bool jumpedOver = false;

      while (nr >= 0 && nr <= 9 && nc >= 0 && nc <= 8) {
        final target = board.value.pieceAt(nr, nc);
        if (!jumpedOver) {
          if (target == null) {
            moves.add(Point(nr, nc)); // 空位可移动
          } else {
            jumpedOver = true; // 找到炮架
          }
        } else {
          if (target != null) {
            if (target.color != piece.color) {
              moves.add(Point(nr, nc)); // 隔一子吃子
            }
            break; // 遇到第二个棋子停止
          }
        }
        nr += dr;
        nc += dc;
      }
    }

    return moves;
  }

  /// 兵/卒：过河前只进，过河后可左右
  List<Point<int>> _getPawnMoves(ChessPiece piece) {
    final moves = <Point<int>>[];
    final forward = piece.color == PieceColor.red ? -1 : 1;
    final hasCrossedRiver = piece.color == PieceColor.red
        ? piece.row <= 4
        : piece.row >= 5;

    // 前进
    final nr = piece.row + forward;
    if (nr >= 0 && nr <= 9) {
      final target = board.value.pieceAt(nr, piece.col);
      if (target == null || target.color != piece.color) {
        moves.add(Point(nr, piece.col));
      }
    }

    // 过河后可以左右移动
    if (hasCrossedRiver) {
      for (final dc in [-1, 1]) {
        final nc = piece.col + dc;
        if (nc >= 0 && nc <= 8) {
          final target = board.value.pieceAt(piece.row, nc);
          if (target == null || target.color != piece.color) {
            moves.add(Point(piece.row, nc));
          }
        }
      }
    }

    return moves;
  }

  // ========== 将军检测 ==========

  /// 检测指定颜色是否被将军
  bool _isKingInCheck(PieceColor color) {
    final king = board.value.findKing(color);
    if (king == null) return false;

    final opponentColor =
        color == PieceColor.red ? PieceColor.black : PieceColor.red;
    final opponentPieces = board.value.piecesOfColor(opponentColor);

    for (final piece in opponentPieces) {
      final moves = _getRawMoves(piece);
      if (moves.any((m) => m.x == king.row && m.y == king.col)) {
        return true;
      }
    }

    // 飞将检测：将帅不可面对面
    final opponentKing = board.value.findKing(opponentColor);
    if (opponentKing != null && opponentKing.col == king.col) {
      final minRow =
          king.row < opponentKing.row ? king.row : opponentKing.row;
      final maxRow =
          king.row > opponentKing.row ? king.row : opponentKing.row;
      bool blocked = false;
      for (int r = minRow + 1; r < maxRow; r++) {
        if (board.value.pieceAt(r, king.col) != null) {
          blocked = true;
          break;
        }
      }
      if (!blocked) return true;
    }

    return false;
  }

  /// 检测指定颜色是否被将死（无合法走法）
  bool _isCheckmate(PieceColor color) {
    final pieces = board.value.piecesOfColor(color);
    for (final piece in pieces) {
      final moves = _getValidMoves(piece);
      if (moves.isNotEmpty) return false;
    }
    return true;
  }

  /// 模拟走棋后检测是否会导致己方被将军
  bool _wouldResultInCheck(ChessPiece piece, int toRow, int toCol) {
    // 保存原始状态
    final originalFromPiece = board.value.grid[piece.row][piece.col];
    final originalToPiece = board.value.grid[toRow][toCol];

    // 模拟走棋
    board.value.grid[piece.row][piece.col] = null;
    board.value.grid[toRow][toCol] = piece;
    final originalRow = piece.row;
    final originalCol = piece.col;
    piece.row = toRow;
    piece.col = toCol;

    // 检测是否被将军
    final inCheck = _isKingInCheck(piece.color);

    // 恢复原始状态
    piece.row = originalRow;
    piece.col = originalCol;
    board.value.grid[originalRow][originalCol] = originalFromPiece;
    board.value.grid[toRow][toCol] = originalToPiece;

    return inCheck;
  }
}
