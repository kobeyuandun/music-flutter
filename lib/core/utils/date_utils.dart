/// Date Utilities
class DateUtils {
  /// Format duration in seconds to MM:SS
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Format duration in milliseconds to MM:SS
  static String formatDurationMs(int milliseconds) {
    return formatDuration(milliseconds ~/ 1000);
  }

  /// Format timestamp to readable date
  static String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format timestamp to readable time
  static String formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Format timestamp to readable date and time
  static String formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get relative time string (e.g., "2 hours ago")
  static String getRelativeTime(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays ~/ 7}周前';
    } else if (difference.inDays < 365) {
      return '${difference.inDays ~/ 30}个月前';
    } else {
      return '${difference.inDays ~/ 365}年前';
    }
  }

  /// Parse LRC timestamp to milliseconds
  static int parseLrcTime(String timeTag) {
    final parts = timeTag.split(':');
    if (parts.length != 2) return 0;

    final minutes = int.tryParse(parts[0]) ?? 0;
    final secondsParts = parts[1].split('.');
    final seconds = int.tryParse(secondsParts[0]) ?? 0;
    final milliseconds = secondsParts.length > 1
        ? int.tryParse(secondsParts[1].padRight(3, '0')) ?? 0
        : 0;

    return (minutes * 60 + seconds) * 1000 + milliseconds;
  }
}
