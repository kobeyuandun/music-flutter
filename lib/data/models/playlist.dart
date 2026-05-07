import 'song.dart';

/// Playlist Model
class Playlist {
  final String id;
  final String name;
  final String? coverUrl;
  final String? description;
  final List<Artist>? creators;
  final int trackCount;
  final int playCount;
  final int? userId;
  final String? creatorName;
  final String? creatorAvatar;
  final int createTime;
  final int? updateTime;
  final List<String>? tags;
  final int? subscribedCount;
  final int? commentCount;
  final bool? subscribed;

  Playlist({
    required this.id,
    required this.name,
    this.coverUrl,
    this.description,
    this.creators,
    required this.trackCount,
    required this.playCount,
    this.userId,
    this.creatorName,
    this.creatorAvatar,
    required this.createTime,
    this.updateTime,
    this.tags,
    this.subscribedCount,
    this.commentCount,
    this.subscribed,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    // Handle creator from different API response formats
    String? creatorName;
    String? creatorAvatar;
    int? userId;
    List<Artist>? creators;

    if (json['creator'] != null) {
      creatorName = json['creator']['nickname'];
      creatorAvatar = json['creator']['avatarUrl'];
      userId = json['creator']['userId'];
      creators = [Artist.fromJson(json['creator'])];
    } else if (json['creatorName'] != null) {
      creatorName = json['creatorName'];
      creatorAvatar = json['creatorAvatar'];
      userId = json['userId'];
    }

    // Get cover URL
    String? coverUrl;
    if (json['coverImgUrl'] != null) {
      coverUrl = json['coverImgUrl'];
    } else if (json['picUrl'] != null) {
      coverUrl = json['picUrl'];
    }

    return Playlist(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      coverUrl: coverUrl,
      description: json['description'],
      creators: creators,
      trackCount: json['trackCount'] ?? json['trackIds']?.length ?? 0,
      playCount: json['playCount'] ?? 0,
      userId: userId,
      creatorName: creatorName,
      creatorAvatar: creatorAvatar,
      createTime: json['createTime'] ?? 0,
      updateTime: json['updateTime'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : null,
      subscribedCount: json['subscribedCount'],
      commentCount: json['commentCount'],
      subscribed: json['subscribed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coverImgUrl': coverUrl,
      'description': description,
      'trackCount': trackCount,
      'playCount': playCount,
      'createTime': createTime,
      'updateTime': updateTime,
      'tags': tags,
      'subscribedCount': subscribedCount,
      'commentCount': commentCount,
      'subscribed': subscribed,
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? coverUrl,
    String? description,
    List<Artist>? creators,
    int? trackCount,
    int? playCount,
    int? userId,
    String? creatorName,
    String? creatorAvatar,
    int? createTime,
    int? updateTime,
    List<String>? tags,
    int? subscribedCount,
    int? commentCount,
    bool? subscribed,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      creators: creators ?? this.creators,
      trackCount: trackCount ?? this.trackCount,
      playCount: playCount ?? this.playCount,
      userId: userId ?? this.userId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      tags: tags ?? this.tags,
      subscribedCount: subscribedCount ?? this.subscribedCount,
      commentCount: commentCount ?? this.commentCount,
      subscribed: subscribed ?? this.subscribed,
    );
  }
}

/// Playlist Detail Model
class PlaylistDetail {
  final Playlist playlist;
  final List<Song> songs;
  final List<String>? privileges;

  PlaylistDetail({
    required this.playlist,
    required this.songs,
    this.privileges,
  });

  factory PlaylistDetail.fromJson(Map<String, dynamic> json) {
    List<Song> songs = [];
    if (json['songs'] != null) {
      songs = (json['songs'] as List)
          .map((e) => Song.fromJson(e))
          .toList();
    }

    return PlaylistDetail(
      playlist: Playlist.fromJson(json['playlist']),
      songs: songs,
      privileges: json['privileges'] != null
          ? List<String>.from(json['privileges'].map((e) => e.toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlist': playlist.toJson(),
      'songs': songs.map((e) => e.toJson()).toList(),
      'privileges': privileges,
    };
  }
}

/// Track IDs Model (for getting playlist tracks)
class TrackIds {
  final int id;
  final int? v;

  TrackIds({required this.id, this.v});

  factory TrackIds.fromJson(Map<String, dynamic> json) {
    return TrackIds(
      id: json['id'] ?? 0,
      v: json['v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'v': v,
    };
  }
}

/// High Quality Playlist Model (for discovery)
class HighQualityPlaylist {
  final List<Playlist> playlists;
  final int? more;
  final String? cat;
  final int? total;

  HighQualityPlaylist({
    required this.playlists,
    this.more,
    this.cat,
    this.total,
  });

  factory HighQualityPlaylist.fromJson(Map<String, dynamic> json) {
    List<Playlist> playlists = [];
    if (json['playlists'] != null) {
      playlists = (json['playlists'] as List)
          .map((e) => Playlist.fromJson(e))
          .toList();
    }

    return HighQualityPlaylist(
      playlists: playlists,
      more: json['more'],
      cat: json['cat'],
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlists': playlists.map((e) => e.toJson()).toList(),
      'more': more,
      'cat': cat,
      'total': total,
    };
  }
}

/// Recommend Playlist Model
class RecommendPlaylist {
  final bool? hasTaste;
  final List<Playlist> recommend;

  RecommendPlaylist({
    this.hasTaste,
    required this.recommend,
  });

  factory RecommendPlaylist.fromJson(Map<String, dynamic> json) {
    List<Playlist> recommend = [];
    if (json['recommend'] != null) {
      recommend = (json['recommend'] as List)
          .map((e) => Playlist.fromJson(e))
          .toList();
    }

    return RecommendPlaylist(
      hasTaste: json['hasTaste'],
      recommend: recommend,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasTaste': hasTaste,
      'recommend': recommend.map((e) => e.toJson()).toList(),
    };
  }
}
