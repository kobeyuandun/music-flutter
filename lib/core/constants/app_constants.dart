import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Application constants
class AppConstants {
  // App Info
  static const String appName = 'Music Flutter';
  static const String appVersion = '1.0.0';

  // API Configuration
  // Meting-API 支持多平台音乐API
  // 项目地址：https://github.com/xizeyoupan/Meting-API
  //
  // 部署方式：
  // 1. 本地部署：git clone https://github.com/xizeyoupan/Meting-API.git && cd Meting-API && npm install && npm start
  // 2. Docker部署：docker run -d -p 3000:3000 xizeyoupan/meting-api
  //
  // 支持的平台：netease(网易云), tencent(QQ音乐)
  // netease: 支持所有功能 (搜索, 歌单, 歌曲, 歌手, 歌词, 播放链接)
  // tencent: 只支持部分功能 (歌单, 歌曲, 歌词, 播放链接)
  // 默认使用网易云音乐作为数据源
  // ============================================
  // 选择你的API方案（取消注释你想用的方案）
  // ============================================

  // === 方案1: Cloudflare Workers（国内无法访问，已停用）===
  // static const String apiBaseUrl = 'https://meting-api.y1015669792.workers.dev';

  // === 方案1b: 腾讯云函数（国内可访问，免费额度）===
  static const String apiBaseUrl = 'https://1423524779-2te2bdcdch.ap-guangzhou.tencentscf.com';

  // === 方案1c: Vercel免费部署（需要科学上网）===
  // static const String apiBaseUrl = 'https://meting-api-kobeyuanduns-projects.vercel.app';

  // === 方案2: 本地部署（稳定，需要电脑开机）===
  /*
  static String get apiBaseUrl {
    const String localIp = '192.168.3.15:3000';
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://$localIp';
    return 'http://localhost:3000';
  }
  */

  // === 方案3: 自定义服务器 ===
  // static const String apiBaseUrl = 'https://your-server.com';

  // Meting-API only supports 'netease' and 'tencent'
  // 'netease' supports all features (search, playlist, url, artist)
  // 'tencent' only supports url, lrc, song, playlist
  static const String defaultServer = 'netease';
  // 超时时间设置（Vercel冷启动可能需要较长时间）
  static const int connectTimeout = 30000;  // 30秒连接超时
  static const int receiveTimeout = 30000;  // 30秒接收超时

  // Storage Keys
  static const String keyToken = 'access_token';
  static const String keyUserId = 'user_id';
  static const String keyUserInfo = 'user_info';
  static const String keyPlayHistory = 'play_history';
  static const String keyLikedSongs = 'liked_songs';
  static const String keyDownloadedSongs = 'downloaded_songs';

  // Player Settings
  static const int defaultPlayMode = 0; // 0: loop, 1: shuffle, 2: single
  static const double defaultVolume = 0.8;

  // Image Placeholders
  static const String defaultCoverUrl =
      'https://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg';

  // Image HTTP Headers (bypass CDN anti-hotlink)
  static const Map<String, String> imageHeaders = {
    'Referer': 'https://music.163.com/',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  // Pagination
  static const int pageSize = 20;

  // Animation Durations
  static const int animationDurationMs = 300;
  static const int playerAnimationDurationMs = 400;
}

/// Play Mode Constants
class PlayMode {
  static const int loop = 0;
  static const int shuffle = 1;
  static const int single = 2;

  static String getModeName(int mode) {
    switch (mode) {
      case loop:
        return '列表循环';
      case shuffle:
        return '随机播放';
      case single:
        return '单曲循环';
      default:
        return '列表循环';
    }
  }
}

/// Tab Index Constants
class TabIndex {
  static const int home = 0;
  static const int discovery = 1;
  static const int search = 2;
  static const int library = 3;
  static const int profile = 4;
}
