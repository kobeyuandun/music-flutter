import 'song.dart';

/// MV Model
class MV {
  final String id;
  final String name;
  final String? coverUrl;
  final String? artistName;
  final String? artistId;
  final int playCount;
  final int? likeCount;
  final int? commentCount;
  final int duration;
  final String? desc;
  final String? briefDesc;
  final int publishTime;
  final String? subed;
  final int? artistIdMap;

  MV({
    required this.id,
    required this.name,
    this.coverUrl,
    this.artistName,
    this.artistId,
    required this.playCount,
    this.likeCount,
    this.commentCount,
    required this.duration,
    this.desc,
    this.briefDesc,
    required this.publishTime,
    this.subed,
    this.artistIdMap,
  });

  factory MV.fromJson(Map<String, dynamic> json) {
    String? artistName;
    String? artistId;

    if (json['artists'] != null && json['artists'].isNotEmpty) {
      artistName = json['artists'][0]['name'];
      artistId = json['artists'][0]['id']?.toString();
    } else if (json['artistName'] != null) {
      artistName = json['artistName'];
    } else if (json['artist'] != null) {
      artistName = json['artist']['name'];
      artistId = json['artist']['id']?.toString();
    }

    return MV(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
      coverUrl: json['cover'] ?? json['coverUrl'],
      artistName: artistName,
      artistId: artistId,
      playCount: json['playCount'] ?? json['playTime'] ?? 0,
      likeCount: json['likeCount'],
      commentCount: json['commentCount'],
      duration: json['duration'] ?? json['dt'] ?? 0,
      desc: json['desc'],
      briefDesc: json['briefDesc'],
      publishTime: json['publishTime'] ?? 0,
      subed: json['subed']?.toString(),
      artistIdMap: json['artistId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cover': coverUrl,
      'artistName': artistName,
      'artistId': artistId,
      'playCount': playCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'duration': duration,
      'desc': desc,
      'briefDesc': briefDesc,
      'publishTime': publishTime,
    };
  }

  MV copyWith({
    String? id,
    String? name,
    String? coverUrl,
    String? artistName,
    String? artistId,
    int? playCount,
    int? likeCount,
    int? commentCount,
    int? duration,
    String? desc,
    String? briefDesc,
    int? publishTime,
  }) {
    return MV(
      id: id ?? this.id,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      artistName: artistName ?? this.artistName,
      artistId: artistId ?? this.artistId,
      playCount: playCount ?? this.playCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      duration: duration ?? this.duration,
      desc: desc ?? this.desc,
      briefDesc: briefDesc ?? this.briefDesc,
      publishTime: publishTime ?? this.publishTime,
    );
  }
}

/// MV Detail Model
class MVDetail {
  final MV mv;
  final List<String>? urls;
  final String? coverUrl;
  final String? subed;
  final List<Artist>? artists;

  MVDetail({
    required this.mv,
    this.urls,
    this.coverUrl,
    this.subed,
    this.artists,
  });

  factory MVDetail.fromJson(Map<String, dynamic> json) {
    MV mv = MV.fromJson(json['data'] ?? json);

    List<String>? urls;
    if (json['data']?['brs'] != null) {
      final brs = json['data']['brs'] as Map<String, dynamic>;
      urls = brs.values.cast<String>().toList();
    }

    List<Artist>? artists;
    if (json['data']?['artists'] != null) {
      artists = (json['data']['artists'] as List)
          .map((e) => Artist.fromJson(e))
          .toList();
    }

    return MVDetail(
      mv: mv,
      urls: urls,
      coverUrl: json['data']?['cover'],
      subed: json['data']?['subed']?.toString(),
      artists: artists,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': mv.toJson(),
      'urls': urls,
      'cover': coverUrl,
      'subed': subed,
      'artists': artists?.map((e) => e.toJson()).toList(),
    };
  }
}

/// MV URL Model
class MVUrl {
  final String id;
  final String url;
  final int? r; // resolution
  final int? size;
  final String? md5;
  final int? rotation;

  MVUrl({
    required this.id,
    required this.url,
    this.r,
    this.size,
    this.md5,
    this.rotation,
  });

  factory MVUrl.fromJson(Map<String, dynamic> json) {
    return MVUrl(
      id: json['id']?.toString() ?? '',
      url: json['url'] ?? json['data']?['url'] ?? '',
      r: json['r'],
      size: json['size'],
      md5: json['md5'],
      rotation: json['rotation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'r': r,
      'size': size,
      'md5': md5,
      'rotation': rotation,
    };
  }

  // Resolution names
  String getResolutionName() {
    switch (r) {
      case 1080:
        return '1080P';
      case 720:
        return '720P';
      case 480:
        return '480P';
      case 240:
        return '240P';
      default:
        return '${r}P';
    }
  }
}

/// All MVs Model
class AllMVs {
  final bool hasMore;
  final List<MV> mvs;
  final int? count;

  AllMVs({
    required this.hasMore,
    required this.mvs,
    this.count,
  });

  factory AllMVs.fromJson(Map<String, dynamic> json) {
    List<MV> mvs = [];
    if (json['data'] != null && json['data']['list'] != null) {
      mvs = (json['data']['list'] as List)
          .map((e) => MV.fromJson(e))
          .toList();
    } else if (json['list'] != null) {
      mvs = (json['list'] as List).map((e) => MV.fromJson(e)).toList();
    }

    return AllMVs(
      hasMore: json['hasMore'] ?? json['more'] ?? false,
      mvs: mvs,
      count: json['count'] ?? json['total'] ?? mvs.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasMore': hasMore,
      'list': mvs.map((e) => e.toJson()).toList(),
      'count': count,
    };
  }
}

/// Top MV Model (for ranking)
class TopMVs {
  final List<MV> mvs;
  final int? count;
  final String? updateTime;

  TopMVs({
    required this.mvs,
    this.count,
    this.updateTime,
  });

  factory TopMVs.fromJson(Map<String, dynamic> json) {
    List<MV> mvs = [];
    if (json['data'] != null && json['data']['list'] != null) {
      mvs = (json['data']['list'] as List)
          .map((e) => MV.fromJson(e))
          .toList();
    } else if (json['list'] != null) {
      mvs = (json['list'] as List).map((e) => MV.fromJson(e)).toList();
    }

    return TopMVs(
      mvs: mvs,
      count: json['count'] ?? json['total'] ?? mvs.length,
      updateTime: json['updateTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'list': mvs.map((e) => e.toJson()).toList(),
      'count': count,
      'updateTime': updateTime,
    };
  }
}
