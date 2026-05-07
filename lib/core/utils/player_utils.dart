import 'dart:math';

/// Player Utilities
class PlayerUtils {
  /// Shuffle a list
  static List<T> shuffleList<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    final random = Random();
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  /// Get next index in loop mode
  static int getNextLoopIndex(int currentIndex, int listLength) {
    return (currentIndex + 1) % listLength;
  }

  /// Get previous index in loop mode
  static int getPreviousLoopIndex(int currentIndex, int listLength) {
    return (currentIndex - 1 + listLength) % listLength;
  }

  /// Get next index in shuffle mode
  static int getNextShuffleIndex(int currentIndex, int listLength) {
    final random = Random();
    int newIndex;
    do {
      newIndex = random.nextInt(listLength);
    } while (newIndex == currentIndex && listLength > 1);
    return newIndex;
  }

  /// Format play count
  static String formatPlayCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    } else if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  /// Format size in bytes to readable string
  static String formatSize(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)}GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)}MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${bytes}B';
  }

  /// Calculate gradient color based on image (simplified)
  static int calculateGradientColor(int primaryColor) {
    return primaryColor;
  }
}
