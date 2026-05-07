import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/song.dart';
import '../models/playlist.dart';

/// Music API Service using Meting-API
/// Supports multiple platforms: netease, tencent, kugou, kuwo, baidu
class MusicApiService {
  static final MusicApiService _instance = MusicApiService._internal();
  factory MusicApiService() => _instance;
  MusicApiService._internal() {
    _dioClient = DioClient();
    _dioClient.init();
  }

  late final DioClient _dioClient;
  String _server = AppConstants.defaultServer;

  Dio get dio => _dioClient.dio;

  /// Set the music platform server
  void setServer(String server) {
    _server = server;
  }

  /// Get current server
  String get server => _server;

  // ============ Helper Methods ============

  /// Build query parameters for Meting-API
  Map<String, dynamic> _buildParams({
    required String type,
    required String id,
    String? server,
  }) {
    return {
      'server': server ?? _server,
      'type': type,
      'id': id,
    };
  }

  /// Make API request
  Future<dynamic> _request({
    required String type,
    required String id,
    String? server,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.api,
      queryParameters: _buildParams(type: type, id: id, server: server),
    );
    return response.data;
  }

  // ============ Search APIs ============

  /// Search songs - Only netease supports search
  Future<List<Song>> search({
    required String keywords,
    int limit = 30,
    int offset = 0,
    String? server,
  }) async {
    try {
      // Only netease supports search, ignore server parameter
      final data = await _request(
        type: ApiEndpoints.typeSearch,
        id: keywords,
        server: 'netease',
      );

      if (data is List) {
        return data.map((e) => Song.fromMetingJson(e as Map<dynamic, dynamic>)).toList();
      }
      return [];
    } catch (e, stackTrace) {
      print('Error searching: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // ============ Song APIs ============

  /// Get song detail
  Future<Song?> getSongDetail(String songId, {String? server}) async {
    try {
      final data = await _request(
        type: ApiEndpoints.typeSong,
        id: songId,
        server: server,
      );

      if (data is List && data.isNotEmpty) {
        return Song.fromMetingJson(data.first as Map<dynamic, dynamic>);
      } else if (data is Map) {
        return Song.fromMetingJson(data as Map<dynamic, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting song detail: $e');
      return null;
    }
  }

  /// Get multiple songs detail
  Future<List<Song>> getSongsDetail(List<String> songIds, {String? server}) async {
    List<Song> songs = [];
    for (final id in songIds) {
      final song = await getSongDetail(id, server: server);
      if (song != null) {
        songs.add(song);
      }
    }
    return songs;
  }

  /// Validate whether a URL actually points to an audio stream
  Future<bool> validateAudioUrl(String url) async {
    try {
      // If it's a Meting-API proxy URL, just check if it returns 302
      if (url.contains('/api?') && url.contains('type=url')) {
        final response = await dio.head(
          url,
          options: Options(
            followRedirects: false,
            validateStatus: (status) => status != null && (status == 200 || status == 302),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        return response.statusCode == 302 &&
            response.headers.value('location') != null;
      }

      // For direct audio URLs
      final response = await dio.head(
        url,
        options: Options(
          followRedirects: true,
          validateStatus: (_) => true,
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final contentType = response.headers.value('content-type') ?? '';
      return contentType.contains('audio') ||
          contentType.contains('video') ||
          contentType.contains('application/octet-stream');
    } catch (e) {
      return false;
    }
  }

  /// Internal helper: try type=url then type=song for a single server
  Future<String?> _getSongUrlSingleServer(String songId, String server) async {
    try {
      // Build the Meting-API proxy URL directly
      // SCF returns a 302 redirect to the actual audio stream
      final proxyUrl = '${AppConstants.apiBaseUrl}${ApiEndpoints.api}'
          '?server=$server&type=url&id=$songId';

      // Skip HEAD pre-validation - CDN URLs expire quickly
      // Let ExoPlayer handle the 302 redirect directly
      return proxyUrl;
    } catch (e) {
      print('Error getting song URL from $server: $e');
      return null;
    }
  }

  /// Get song URL with cross-server fallback
  /// Note: Meting-API only supports 'netease' and 'tencent'
  Future<String?> getSongUrl(
    String songId, {
    String? server,
    String? songName,
    String? artistName,
  }) async {
    // Meting-API only supports netease and tencent
    final targetServers = [server ?? _server, 'netease', 'tencent'];
    final uniqueServers = targetServers.toSet().toList();

    // 1. Try each server with the same songId
    for (final s in uniqueServers) {
      final url = await _getSongUrlSingleServer(songId, s);
      if (url != null) return url;
    }

    // 2. If all fail and we have song info, search on netease (only platform that supports search)
    if (songName != null && songName.isNotEmpty) {
      try {
        final keywords = artistName != null && artistName.isNotEmpty
            ? '$songName $artistName'
            : songName;
        final results = await search(keywords: keywords, limit: 10);
        for (final result in results) {
          if (result.name.toLowerCase().contains(songName.toLowerCase())) {
            final url = await _getSongUrlSingleServer(result.id, 'netease');
            if (url != null) return url;
          }
        }
      } catch (e) {
        print('Error searching fallback: $e');
      }
    }

    return null;
  }

  /// Get song lyrics
  Future<String?> getSongLyric(String songId, {String? server}) async {
    try {
      final data = await _request(
        type: ApiEndpoints.typeLrc,
        id: songId,
        server: server,
      );

      if (data is List && data.isNotEmpty) {
        return data.first['lrc']?.toString();
      } else if (data is Map) {
        return data['lrc']?.toString();
      }
      return null;
    } catch (e) {
      print('Error getting song lyric: $e');
      return null;
    }
  }

  // ============ Playlist APIs ============

  /// Get playlist detail and songs
  Future<PlaylistDetail?> getPlaylistDetail(String playlistId, {String? server}) async {
    try {
      final data = await _request(
        type: ApiEndpoints.typePlaylist,
        id: playlistId,
        server: server,
      );

      if (data is List) {
        final songs = data.map((e) => Song.fromMetingJson(e as Map<dynamic, dynamic>)).toList();

        // Create a playlist object from the first song's info or use defaults
        final playlist = Playlist(
          id: playlistId,
          name: '歌单 $playlistId',
          coverUrl: songs.isNotEmpty ? songs.first.coverUrl : null,
          trackCount: songs.length,
          playCount: 0,
          createTime: DateTime.now().millisecondsSinceEpoch,
        );

        print('DEBUG: Playlist $playlistId loaded, ${songs.length} songs');

        return PlaylistDetail(
          playlist: playlist,
          songs: songs,
        );
      }
      print('DEBUG: Playlist $playlistId returned non-list data: ${data.runtimeType}');
      return null;
    } catch (e) {
      print('DEBUG ERROR: getPlaylistDetail($playlistId): $e');
      return null;
    }
  }

  /// Get playlist songs (alias for getPlaylistDetail in Meting-API)
  Future<List<Song>> getPlaylistTracks(String playlistId, {String? server}) async {
    final detail = await getPlaylistDetail(playlistId, server: server);
    return detail?.songs ?? [];
  }

  /// Get recommended playlists (search for popular playlists)
  Future<List<Playlist>> getRecommendPlaylists({String? server}) async {
    // Meting-API doesn't have a direct recommendation endpoint
    // Using search for popular playlists as fallback
    try {
      // Note: Meting-API search returns songs, not playlists
      // For playlists, we return some default playlist IDs
      // Updated with more active playlists for fresher content
      // Only use verified NetEase official playlist IDs
      final defaultPlaylistIds = [
        '3779629',     // 云音乐新歌榜 - 最新歌曲
        '3778678',     // 云音乐飙升榜 - 近期热门
        '19723756',    // 云音乐热歌榜 - 当前最火
        '2884035',     // 云音乐原创榜
        '2006508653',  // 抖音排行榜
        '10520166',    // 云音乐电音榜
        '745956260',   // 云音乐ACG音乐榜
        '180106',      // 华语金曲榜
        '60198',       // 美国Billboard榜
        '60131',       // 日本Oricon榜
        '11641012',    // iTunes榜
      ];

      // Load playlists in batches to avoid overwhelming the server
      List<Playlist> playlists = [];
      const batchSize = 5;
      for (int i = 0; i < defaultPlaylistIds.length; i += batchSize) {
        final batch = defaultPlaylistIds.sublist(
          i,
          i + batchSize > defaultPlaylistIds.length
              ? defaultPlaylistIds.length
              : i + batchSize,
        );
        print('DEBUG: Loading batch: $batch');
        final futures = batch.map((id) =>
          getPlaylistDetail(id, server: server).catchError((_) => null)
        );
        final results = await Future.wait(futures);
        for (final detail in results) {
          if (detail != null) {
            playlists.add(detail.playlist);
          }
        }
      }
      print('DEBUG: getRecommendPlaylists returning ${playlists.length} playlists');
      return playlists;
    } catch (e) {
      print('DEBUG ERROR: getRecommendPlaylists: $e');
      return [];
    }
  }

  /// Get high quality playlists
  Future<List<Playlist>> getHighQualityPlaylists({
    String cat = '全部',
    int limit = 50,
    int offset = 0,
    String? server,
  }) async {
    // Meting-API doesn't have this endpoint, use default playlists
    return getRecommendPlaylists(server: server);
  }

  /// Get hot playlists
  Future<List<Playlist>> getHotPlaylists({
    String order = 'hot',
    String cat = '全部',
    int limit = 50,
    int offset = 0,
    String? server,
  }) async {
    return getRecommendPlaylists(server: server);
  }

  // ============ Album APIs ============

  /// Get album detail
  Future<Album?> getAlbumDetail(String albumId, {String? server}) async {
    try {
      final data = await _request(
        type: ApiEndpoints.typeAlbum,
        id: albumId,
        server: server,
      );

      if (data is List && data.isNotEmpty) {
        final song = Song.fromMetingJson(data.first as Map<dynamic, dynamic>);
        return Album(
          id: albumId,
          name: song.album?.name ?? '未知专辑',
          picUrl: song.coverUrl,
          artists: song.artists,
        );
      }
      return null;
    } catch (e) {
      print('Error getting album detail: $e');
      return null;
    }
  }

  /// Get album songs
  Future<List<Song>> getAlbumSongs(String albumId, {String? server}) async {
    try {
      final data = await _request(
        type: ApiEndpoints.typeAlbum,
        id: albumId,
        server: server,
      );

      if (data is List) {
        return data.map((e) => Song.fromMetingJson(e as Map<dynamic, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting album songs: $e');
      return [];
    }
  }

  // ============ Artist APIs ============

  /// Get artist detail
  Future<Map<String, dynamic>?> getArtistDetail(String artistId, {String? server}) async {
    try {
      final data = await _request(
        type: ApiEndpoints.typeArtist,
        id: artistId,
        server: server,
      );

      if (data is List && data.isNotEmpty) {
        return {
          'artist': data.first,
          'songs': data,
        };
      }
      return null;
    } catch (e) {
      print('Error getting artist detail: $e');
      return null;
    }
  }

  /// Get artist songs - Only netease supports artist
  Future<List<Song>> getArtistSongs(
    String artistId, {
    int limit = 50,
    int offset = 0,
    String? server,
  }) async {
    try {
      // Only netease supports artist, ignore server parameter
      final data = await _request(
        type: ApiEndpoints.typeArtist,
        id: artistId,
        server: 'netease',
      );

      if (data is List) {
        var songs = data.map((e) => Song.fromMetingJson(e as Map<dynamic, dynamic>)).toList();
        // Apply limit and offset
        if (offset < songs.length) {
          songs = songs.sublist(offset);
        } else {
          songs = [];
        }
        if (songs.length > limit) {
          songs = songs.sublist(0, limit);
        }
        return songs;
      }
      return [];
    } catch (e) {
      print('Error getting artist songs: $e');
      return [];
    }
  }

  // ============ Ranking APIs ============

  /// Get top list / ranking - more categories for fresher content
  Future<List<Playlist>> getTopList({String? server}) async {
    // Return default ranking playlists - only verified official IDs
    final rankingIds = [
      '3779629',     // 新歌榜 - newest
      '3778678',     // 飙升榜 - trending
      '19723756',    // 热歌榜 - most played
      '2884035',     // 原创榜
      '2006508653',  // 抖音排行榜 - viral
      '10520166',    // 电音榜
      '745956260',   // ACG音乐榜
      '180106',      // 华语金曲榜
      '60198',       // Billboard榜
      '60131',       // 日本Oricon榜
      '11641012',    // iTunes榜
    ];

    // Load rankings in batches
    List<Playlist> playlists = [];
    const batchSize = 5;
    for (int i = 0; i < rankingIds.length; i += batchSize) {
      final batch = rankingIds.sublist(
        i,
        i + batchSize > rankingIds.length ? rankingIds.length : i + batchSize,
      );
      final futures = batch.map((id) =>
        getPlaylistDetail(id, server: server).catchError((_) => null)
      );
      final results = await Future.wait(futures);
      for (final detail in results) {
        if (detail != null) {
          playlists.add(detail.playlist);
        }
      }
    }
    return playlists;
  }

  // ============ User APIs (Not supported by Meting-API) ============

  /// Login - Not supported by Meting-API
  Future<LoginResponse> loginWithPhone({
    required String phone,
    required String password,
    String countrycode = '86',
  }) async {
    return LoginResponse(
      success: false,
      errorMessage: '登录功能需要部署带用户系统的后端',
    );
  }

  /// Login with email - Not supported by Meting-API
  Future<LoginResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return LoginResponse(
      success: false,
      errorMessage: '登录功能需要部署带用户系统的后端',
    );
  }

  /// Get user detail - Not supported by Meting-API
  Future<User?> getUserDetail(String userId) async {
    return null;
  }

  /// Get user playlists - Not supported by Meting-API
  Future<UserPlaylist?> getUserPlaylists(String userId) async {
    return null;
  }

  /// Logout - Not supported by Meting-API
  Future<bool> logout() async {
    return true;
  }

  // ============ Deprecated APIs ============

  /// Get new songs - Search for recent trending songs
  Future<List<Song>> getNewSongs({String type = '7', String? server}) async {
    // Try multiple keywords to get the newest trending songs
    final keywords = [
      '2025',
      '2024',
      '新歌',
      '抖音',
    ];
    for (final kw in keywords) {
      final results = await search(keywords: kw, limit: 30);
      if (results.isNotEmpty) return results;
    }
    return [];
  }

  /// Get recommend songs - Prioritize new songs for fresher content
  Future<List<Song>> getRecommendSongs({String? server}) async {
    // Priority: new songs first, then trending, then popular
    final freshPlaylistIds = [
      '3779629',     // 新歌榜 - newest songs
      '3778678',     // 飙升榜 - trending now
      '19723756',    // 热歌榜 - currently popular
      '2006508653',  // 抖音榜 - viral hits
    ];

    for (final id in freshPlaylistIds) {
      final playlist = await getPlaylistDetail(id, server: server);
      if (playlist != null && playlist.songs.isNotEmpty) {
        return playlist.songs.take(20).toList();
      }
    }

    // Fallback: search for recent popular songs
    final recentSearches = [
      '2024',
      '2025',
      '抖音',
      '热门',
    ];
    for (final keyword in recentSearches) {
      final results = await search(keywords: keyword, limit: 20, server: server);
      if (results.isNotEmpty) return results;
    }
    return [];
  }

  /// Get hot search keywords - Not supported by Meting-API, return defaults
  Future<List<String>> getHotSearch() async {
    return [
      '周杰伦',
      '林俊杰',
      '薛之谦',
      '邓紫棋',
      '陈奕迅',
      '热门歌曲',
      '经典老歌',
    ];
  }
}

/// Login Response Model
class LoginResponse {
  final bool success;
  final String? errorMessage;
  final User? user;
  final String? token;
  final String? cookie;

  LoginResponse({
    required this.success,
    this.errorMessage,
    this.user,
    this.token,
    this.cookie,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['code'] == 200,
      user: json['profile'] != null ? User.fromJson(json['profile']) : null,
      token: json['token'],
      cookie: json['cookie'],
    );
  }
}

/// User Model (simplified for Meting-API)
class User {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String? signature;
  final bool isVip;
  final int? followCount;
  final int? followedCount;
  final int? playlistCount;

  User({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.signature,
    this.isVip = false,
    this.followCount,
    this.followedCount,
    this.playlistCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatarUrl'],
      signature: json['signature'],
      isVip: json['vipType'] != null && json['vipType'] > 0,
      followCount: json['followeds'] ?? json['followCount'],
      followedCount: json['follows'] ?? json['followedCount'],
      playlistCount: json['playlistCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'signature': signature,
      'vipType': isVip ? 1 : 0,
      'followeds': followCount,
      'follows': followedCount,
      'playlistCount': playlistCount,
    };
  }

  User copyWith({
    String? id,
    String? nickname,
    String? avatarUrl,
    String? signature,
    bool? isVip,
    int? followCount,
    int? followedCount,
    int? playlistCount,
  }) {
    return User(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      signature: signature ?? this.signature,
      isVip: isVip ?? this.isVip,
      followCount: followCount ?? this.followCount,
      followedCount: followedCount ?? this.followedCount,
      playlistCount: playlistCount ?? this.playlistCount,
    );
  }
}

/// User Playlist Model
class UserPlaylist {
  final List<Playlist> playlists;
  final bool more;

  UserPlaylist({
    required this.playlists,
    required this.more,
  });

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    return UserPlaylist(
      playlists: (json['playlist'] as List?)
              ?.map((e) => Playlist.fromJson(e))
              .toList() ??
          [],
      more: json['more'] ?? false,
    );
  }
}
