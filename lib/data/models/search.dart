import 'song.dart';
import 'playlist.dart';
import 'mv.dart';
import 'user.dart';

/// Search Result Model
class SearchResult {
  final List<Song> songs;
  final List<Playlist> playlists;
  final List<Artist> artists;
  final List<MV> mvs;
  final int? songCount;
  final int? playlistCount;
  final int? artistCount;
  final int? mvCount;
  final int? code;

  SearchResult({
    required this.songs,
    required this.playlists,
    required this.artists,
    required this.mvs,
    this.songCount,
    this.playlistCount,
    this.artistCount,
    this.mvCount,
    this.code,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'] ?? {};

    List<Song> songs = [];
    if (result['songs'] != null) {
      songs = (result['songs'] as List)
          .map((e) => Song.fromJson(e))
          .toList();
    }

    List<Playlist> playlists = [];
    if (result['playlists'] != null) {
      playlists = (result['playlists'] as List)
          .map((e) => Playlist.fromJson(e))
          .toList();
    }

    List<Artist> artists = [];
    if (result['artists'] != null) {
      artists = (result['artists'] as List)
          .map((e) => Artist.fromJson(e))
          .toList();
    }

    List<MV> mvs = [];
    if (result['mvs'] != null) {
      mvs = (result['mvs'] as List).map((e) => MV.fromJson(e)).toList();
    }

    return SearchResult(
      songs: songs,
      playlists: playlists,
      artists: artists,
      mvs: mvs,
      songCount: result['songCount'],
      playlistCount: result['playlistCount'],
      artistCount: result['artistCount'],
      mvCount: result['mvCount'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': {
        'songs': songs.map((e) => e.toJson()).toList(),
        'playlists': playlists.map((e) => e.toJson()).toList(),
        'artists': artists.map((e) => e.toJson()).toList(),
        'mvs': mvs.map((e) => e.toJson()).toList(),
        'songCount': songCount,
        'playlistCount': playlistCount,
        'artistCount': artistCount,
        'mvCount': mvCount,
      },
      'code': code,
    };
  }

  bool get hasResults =>
      songs.isNotEmpty ||
      playlists.isNotEmpty ||
      artists.isNotEmpty ||
      mvs.isNotEmpty;
}

/// Search Suggest Model
class SearchSuggest {
  final List<String>? keywords;
  final List<String>? albums;
  final List<String>? artists;
  final List<String>? songs;
  final List<String>? playlists;

  SearchSuggest({
    this.keywords,
    this.albums,
    this.artists,
    this.songs,
    this.playlists,
  });

  factory SearchSuggest.fromJson(Map<String, dynamic> json) {
    final result = json['result'] ?? {};
    final order = json['order'] as List?;

    List<String>? keywords;
    List<String>? albums;
    List<String>? artists;
    List<String>? songs;
    List<String>? playlists;

    if (result['allMatch'] != null) {
      keywords = List<String>.from(result['allMatch']
          .map((e) => e['keyword'] ?? e['name'] ?? ''));
    }

    return SearchSuggest(
      keywords: keywords,
      albums: albums,
      artists: artists,
      songs: songs,
      playlists: playlists,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': {
        'allMatch': keywords?.map((e) => {'keyword': e}).toList(),
      },
    };
  }

  List<String> get allSuggestions {
    final suggestions = <String>[];
    if (keywords != null) suggestions.addAll(keywords!);
    if (albums != null) suggestions.addAll(albums!);
    if (artists != null) suggestions.addAll(artists!);
    if (songs != null) suggestions.addAll(songs!);
    if (playlists != null) suggestions.addAll(playlists!);
    return suggestions;
  }
}

/// Hot Search Model
class HotSearch {
  final List<HotSearchItem> hots;
  final int? code;

  HotSearch({
    required this.hots,
    this.code,
  });

  factory HotSearch.fromJson(Map<String, dynamic> json) {
    List<HotSearchItem> hots = [];
    if (json['result']?['hots'] != null) {
      hots = (json['result']['hots'] as List)
          .map((e) => HotSearchItem.fromJson(e))
          .toList();
    } else if (json['data']?['list'] != null) {
      hots = (json['data']['list'] as List)
          .map((e) => HotSearchItem.fromJson(e))
          .toList();
    }

    return HotSearch(
      hots: hots,
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'result': {'hots': hots.map((e) => e.toJson()).toList()},
    };
  }
}

/// Hot Search Item Model
class HotSearchItem {
  final String? searchWord;
  final String? content;
  final int? score;
  final int? iconType;
  final String? url;
  final int? alg;

  HotSearchItem({
    this.searchWord,
    this.content,
    this.score,
    this.iconType,
    this.url,
    this.alg,
  });

  factory HotSearchItem.fromJson(Map<String, dynamic> json) {
    return HotSearchItem(
      searchWord: json['searchWord'] ?? json['keyword'],
      content: json['content'],
      score: json['score'],
      iconType: json['iconType'],
      url: json['url'],
      alg: json['alg'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchWord': searchWord,
      'content': content,
      'score': score,
      'iconType': iconType,
      'url': url,
      'alg': alg,
    };
  }

  String get displayWord => searchWord ?? content ?? '';

  String getIconTypeText() {
    switch (iconType) {
      case 1:
        return '热';
      case 5:
        return '新';
      case 7:
        return '';
      default:
        return '';
    }
  }
}

/// Search Type Enum
class SearchType {
  static const int song = 1; // 单曲
  static const int album = 10; // 专辑
  static const int artist = 100; // 歌手
  static const int playlist = 1000; // 歌单
  static const int user = 1002; // 用户
  static const int mv = 1004; // MV
  static const int lyric = 1006; // 歌词
  static const int radio = 1009; // 电台

  static String getTypeName(int type) {
    switch (type) {
      case song:
        return '单曲';
      case album:
        return '专辑';
      case artist:
        return '歌手';
      case playlist:
        return '歌单';
      case user:
        return '用户';
      case mv:
        return 'MV';
      case lyric:
        return '歌词';
      case radio:
        return '电台';
      default:
        return '综合';
    }
  }
}

/// Search Detail Model (for multi-type search)
class SearchDetail {
  final List<Song> songs;
  final List<Playlist> playlists;
  final List<Artist> artists;
  final List<Album>? albums;
  final List<User>? users;
  final List<MV>? mvs;
  final int? songCount;
  final int? playlistCount;
  final int? artistCount;
  final int? albumCount;
  final int? userCount;
  final int? mvCount;
  final int? code;

  SearchDetail({
    required this.songs,
    required this.playlists,
    required this.artists,
    this.albums,
    this.users,
    this.mvs,
    this.songCount,
    this.playlistCount,
    this.artistCount,
    this.albumCount,
    this.userCount,
    this.mvCount,
    this.code,
  });

  factory SearchDetail.fromJson(Map<String, dynamic> json, {int type = 1018}) {
    final result = json['result'] ?? {};

    List<Song> songs = [];
    if (result['songs'] != null) {
      songs = (result['songs'] as List)
          .map((e) => Song.fromJson(e))
          .toList();
    }

    List<Playlist> playlists = [];
    if (result['playlists'] != null) {
      playlists = (result['playlists'] as List)
          .map((e) => Playlist.fromJson(e))
          .toList();
    }

    List<Artist> artists = [];
    if (result['artists'] != null) {
      artists = (result['artists'] as List)
          .map((e) => Artist.fromJson(e))
          .toList();
    }

    List<Album>? albums;
    if (result['albums'] != null) {
      albums =
          (result['albums'] as List).map((e) => Album.fromJson(e)).toList();
    }

    List<User>? users;
    if (result['userprofiles'] != null) {
      users = (result['userprofiles'] as List)
          .map((e) => User.fromJson(e))
          .toList();
    }

    List<MV>? mvs;
    if (result['mvs'] != null) {
      mvs = (result['mvs'] as List).map((e) => MV.fromJson(e)).toList();
    }

    return SearchDetail(
      songs: songs,
      playlists: playlists,
      artists: artists,
      albums: albums,
      users: users,
      mvs: mvs,
      songCount: result['songCount'],
      playlistCount: result['playlistCount'],
      artistCount: result['artistCount'],
      albumCount: result['albumCount'],
      userCount: result['userprofileCount'],
      mvCount: result['mvCount'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': {
        'songs': songs.map((e) => e.toJson()).toList(),
        'playlists': playlists.map((e) => e.toJson()).toList(),
        'artists': artists.map((e) => e.toJson()).toList(),
        'albums': albums?.map((e) => e.toJson()).toList(),
        'userprofiles': users?.map((e) => e.toJson()).toList(),
        'mvs': mvs?.map((e) => e.toJson()).toList(),
        'songCount': songCount,
        'playlistCount': playlistCount,
        'artistCount': artistCount,
        'albumCount': albumCount,
        'userprofileCount': userCount,
        'mvCount': mvCount,
      },
      'code': code,
    };
  }
}
