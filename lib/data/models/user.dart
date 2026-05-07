import 'playlist.dart';

/// User Model
class User {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String? backgroundUrl;
  final String? signature;
  final int? gender; // 0: unknown, 1: male, 2: female
  final int? birthday;
  final int? province;
  final int? city;
  final int? vipType;
  final bool? vipStatus;
  final int? followCount;
  final int? followedCount;
  final int? playlistCount;
  final int? createTime;

  User({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.backgroundUrl,
    this.signature,
    this.gender,
    this.birthday,
    this.province,
    this.city,
    this.vipType,
    this.vipStatus,
    this.followCount,
    this.followedCount,
    this.playlistCount,
    this.createTime,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatarUrl'],
      backgroundUrl: json['backgroundUrl'],
      signature: json['signature'],
      gender: json['gender'],
      birthday: json['birthday'],
      province: json['province'],
      city: json['city'],
      vipType: json['vipType'],
      vipStatus: json['vipStatus'],
      followCount: (json['follows'] as num?)?.toInt(),
      followedCount: (json['followeds'] as num?)?.toInt(),
      playlistCount: json['playlistCount'],
      createTime: json['createTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'backgroundUrl': backgroundUrl,
      'signature': signature,
      'gender': gender,
      'birthday': birthday,
      'province': province,
      'city': city,
      'vipType': vipType,
      'vipStatus': vipStatus,
      'follows': followCount,
      'followeds': followedCount,
      'playlistCount': playlistCount,
      'createTime': createTime,
    };
  }

  User copyWith({
    String? id,
    String? nickname,
    String? avatarUrl,
    String? backgroundUrl,
    String? signature,
    int? gender,
    int? birthday,
    int? province,
    int? city,
    int? vipType,
    bool? vipStatus,
    int? followCount,
    int? followedCount,
    int? playlistCount,
    int? createTime,
  }) {
    return User(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      signature: signature ?? this.signature,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      province: province ?? this.province,
      city: city ?? this.city,
      vipType: vipType ?? this.vipType,
      vipStatus: vipStatus ?? this.vipStatus,
      followCount: followCount ?? this.followCount,
      followedCount: followedCount ?? this.followedCount,
      playlistCount: playlistCount ?? this.playlistCount,
      createTime: createTime ?? this.createTime,
    );
  }

  String getGenderText() {
    switch (gender) {
      case 1:
        return '男';
      case 2:
        return '女';
      default:
        return '保密';
    }
  }

  bool get isVip => vipStatus == true;
}

/// Login Response Model
class LoginResponse {
  final bool success;
  final String? token;
  final String? cookie;
  final User? user;
  final String? errorMessage;
  final int? code;

  LoginResponse({
    required this.success,
    this.token,
    this.cookie,
    this.user,
    this.errorMessage,
    this.code,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final code = json['code'] ?? 200;
    final success = code == 200;

    User? user;
    if (json['profile'] != null) {
      user = User.fromJson(json['profile']);
    } else if (json['account'] != null && json['profile'] != null) {
      user = User.fromJson(json['profile']);
    }

    return LoginResponse(
      success: success,
      token: json['token'],
      cookie: json['cookie'],
      user: user,
      code: code,
      errorMessage: !success ? json['message'] ?? '登录失败' : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'token': token,
      'cookie': cookie,
      'user': user?.toJson(),
      'code': code,
    };
  }
}

/// User Playlist Model
class UserPlaylist {
  final bool? more;
  final List<Playlist> playlists;
  final int? count;

  UserPlaylist({
    this.more,
    required this.playlists,
    this.count,
  });

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    List<Playlist> playlists = [];
    if (json['playlist'] != null || json['playlists'] != null) {
      final list = json['playlist'] ?? json['playlists'] ?? [];
      playlists = (list as List).map((e) => Playlist.fromJson(e)).toList();
    }

    return UserPlaylist(
      more: json['more'],
      playlists: playlists,
      count: json['count'] ?? playlists.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'more': more,
      'playlist': playlists.map((e) => e.toJson()).toList(),
      'count': count,
    };
  }

  // Get favorite playlist (first one, usually "我喜欢的音乐")
  Playlist? get favoritePlaylist {
    if (playlists.isEmpty) return null;
    return playlists.firstWhere(
      (p) => p.name == '我喜欢的音乐',
      orElse: () => playlists.first,
    );
  }

  // Get user created playlists
  List<Playlist> get createdPlaylists {
    return playlists.where((p) => p.userId != null).toList();
  }

  // Get user subscribed playlists
  List<Playlist> get subscribedPlaylists {
    return playlists.where((p) => p.subscribed == true).toList();
  }
}

/// Liked Songs Response
class LikedSongs {
  final List<int> ids;
  final int? count;
  final int? code;

  LikedSongs({
    required this.ids,
    this.count,
    this.code,
  });

  factory LikedSongs.fromJson(Map<String, dynamic> json) {
    List<int> ids = [];
    if (json['ids'] != null) {
      ids = List<int>.from(json['ids'].map((e) => e as int));
    }

    return LikedSongs(
      ids: ids,
      count: json['count'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
      'count': count,
      'code': code,
    };
  }

  bool isLiked(String songId) {
    return ids.contains(int.tryParse(songId));
  }
}
