/// Song Model
class Song {
  final String id;
  final String name;
  final List<Artist> artists;
  final Album? album;
  final int duration;
  String? coverUrl;
  String? audioUrl;
  final int? mvId;
  final int? copyrightId;
  final int score;
  final int? commentCount;

  Song({
    required this.id,
    required this.name,
    required this.artists,
    this.album,
    required this.duration,
    this.coverUrl,
    this.audioUrl,
    this.mvId,
    this.copyrightId,
    this.score = 0,
    this.commentCount,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    List<Artist> artists = [];
    if (json['ar'] != null) {
      artists = (json['ar'] as List).map((e) => Artist.fromJson(e)).toList();
    } else if (json['artists'] != null) {
      artists = (json['artists'] as List)
          .map((e) => Artist.fromJson(e))
          .toList();
    }

    Album? album;
    if (json['al'] != null) {
      album = Album.fromJson(json['al']);
    } else if (json['album'] != null) {
      album = Album.fromJson(json['album']);
    }

    String? coverUrl;
    if (json['al'] != null && json['al']['picUrl'] != null) {
      coverUrl = json['al']['picUrl'];
    } else if (album?.picUrl != null) {
      coverUrl = album!.picUrl;
    }

    return Song(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      artists: artists,
      album: album,
      duration: json['dt'] ?? json['duration'] ?? 0,
      coverUrl: coverUrl,
      mvId: json['mv'] ?? json['mvId'],
      copyrightId: json['copyrightId'],
      score: json['score'] ?? 0,
      commentCount: json['commentCount'] ?? json['commentThreadId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ar': artists.map((e) => e.toJson()).toList(),
      'al': album?.toJson(),
      'dt': duration,
      'mv': mvId,
      'copyrightId': copyrightId,
      'score': score,
    };
  }

  /// Parse from Meting-API response format
  /// Meting-API returns: {title, author, url, pic, lrc}
  factory Song.fromMetingJson(Map<dynamic, dynamic> json) {
    // Parse artist - Meting returns it in 'author' field (not 'artist')
    List<Artist> artists = [];
    if (json['author'] != null) {
      final artistStr = json['author'].toString();
      // Handle multiple artists separated by comma or slash
      final artistNames = artistStr.split(RegExp(r'[,/、]'));
      artists = artistNames
          .map((name) => Artist(
                id: '', // Meting doesn't provide artist ID
                name: name.trim(),
              ))
          .toList();
    } else if (json['artist'] != null) {
      final artistStr = json['artist'].toString();
      final artistNames = artistStr.split(RegExp(r'[,/、]'));
      artists = artistNames
          .map((name) => Artist(
                id: '',
                name: name.trim(),
              ))
          .toList();
    } else if (json['artists'] != null) {
      artists = (json['artists'] as List)
          .map((e) => Artist.fromJson(e))
          .toList();
    }

    // Parse album - Meting may return album in 'album' field
    Album? album;
    if (json['album'] != null && json['album'] is Map) {
      album = Album.fromJson(json['album']);
    }

    // Get song name first (needed for debug print)
    String songName = '未知歌曲';
    if (json['title'] != null) {
      songName = json['title'].toString();
    } else if (json['name'] != null) {
      songName = json['name'].toString();
    }

    // Get cover URL - Meting uses 'pic' field
    String? coverUrl;
    if (json['pic'] != null) {
      coverUrl = json['pic'].toString();
    } else if (json['cover'] != null) {
      coverUrl = json['cover'].toString();
    } else if (json['picUrl'] != null) {
      coverUrl = json['picUrl'].toString();
    }

    // 修复Vercel返回的本地地址问题
    // 如果URL包含本地地址，使用网易云CDN图片
    if (coverUrl != null && (coverUrl.contains('192.168.') || coverUrl.contains('localhost') || coverUrl.contains('10.0.2.2'))) {
      // 从URL中提取图片ID，或使用默认图片
      coverUrl = 'https://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg';
    }
    // 如果是相对路径，补全为完整URL
    else if (coverUrl != null && coverUrl.startsWith('/')) {
      coverUrl = 'https://p1.music.126.net$coverUrl';
    }
    // 如果没有协议头，添加https
    else if (coverUrl != null && !coverUrl.startsWith('http')) {
      coverUrl = 'https://$coverUrl';
    }

    // Get audio URL - Meting uses 'url' field
    String? audioUrl;
    if (json['url'] != null) {
      audioUrl = json['url'].toString();
    }

    // Parse duration if available
    int duration = 0;
    if (json['duration'] != null) {
      duration = int.tryParse(json['duration'].toString()) ?? 0;
    } else if (json['dt'] != null) {
      duration = int.tryParse(json['dt'].toString()) ?? 0;
    }

    // Get song ID - Meting returns id embedded in the url field
    // e.g., "http://192.168.3.15:3000/api?server=netease&type=url&id=12345"
    String songId = '';
    if (json['url'] != null) {
      final urlStr = json['url'].toString();
      final match = RegExp(r'id=(\d+)').firstMatch(urlStr);
      if (match != null) {
        songId = match.group(1) ?? '';
      }
    }
    // Fallback: try direct id field if exists
    if (songId.isEmpty && json['id'] != null) {
      songId = json['id'].toString();
    }

    return Song(
      id: songId,
      name: songName,
      artists: artists.isNotEmpty ? artists : [Artist(id: '', name: '未知歌手')],
      album: album,
      duration: duration,
      coverUrl: coverUrl,
      audioUrl: audioUrl,
      mvId: json['mvId'] != null ? int.tryParse(json['mvId'].toString()) : null,
      copyrightId: json['copyrightId'] != null
          ? int.tryParse(json['copyrightId'].toString())
          : null,
      score: json['score'] != null ? int.tryParse(json['score'].toString()) ?? 0 : 0,
    );
  }

  String get artistNames => artists.map((e) => e.name).join('/');

  Song copyWith({
    String? id,
    String? name,
    List<Artist>? artists,
    Album? album,
    int? duration,
    String? coverUrl,
    String? audioUrl,
    int? mvId,
    int? copyrightId,
    int? score,
    int? commentCount,
  }) {
    return Song(
      id: id ?? this.id,
      name: name ?? this.name,
      artists: artists ?? this.artists,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      mvId: mvId ?? this.mvId,
      copyrightId: copyrightId ?? this.copyrightId,
      score: score ?? this.score,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

/// Artist Model
class Artist {
  final String id;
  final String name;
  final String? picUrl;
  final int? albumSize;
  final int? mvSize;
  final String? transName;

  Artist({
    required this.id,
    required this.name,
    this.picUrl,
    this.albumSize,
    this.mvSize,
    this.transName,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      picUrl: json['picUrl'] ?? json['img1v1Url'],
      albumSize: json['albumSize'],
      mvSize: json['mvSize'],
      transName: json['trans'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'picUrl': picUrl,
      'albumSize': albumSize,
      'mvSize': mvSize,
      'trans': transName,
    };
  }
}

/// Album Model
class Album {
  final String id;
  final String name;
  final String? picUrl;
  final List<Artist>? artists;
  final String? description;
  final int? publishTime;
  final int? size;
  final int? companyId;

  Album({
    required this.id,
    required this.name,
    this.picUrl,
    this.artists,
    this.description,
    this.publishTime,
    this.size,
    this.companyId,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    List<Artist>? artists;
    if (json['artists'] != null) {
      artists =
          (json['artists'] as List).map((e) => Artist.fromJson(e)).toList();
    }

    return Album(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      picUrl: json['picUrl'] ?? json['blurPicUrl'],
      artists: artists,
      description: json['description'],
      publishTime: json['publishTime'],
      size: json['size'],
      companyId: json['company'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'picUrl': picUrl,
      'artists': artists?.map((e) => e.toJson()).toList(),
      'description': description,
      'publishTime': publishTime,
      'size': size,
    };
  }

  String get artistNames => artists?.map((e) => e.name).join('/') ?? '';
}

/// Song URL Model
class SongUrl {
  final String id;
  final String url;
  final int? br; // bitrate
  final int? size;
  final String? type; // music format
  final String? encodeType;

  SongUrl({
    required this.id,
    required this.url,
    this.br,
    this.size,
    this.type,
    this.encodeType,
  });

  factory SongUrl.fromJson(Map<String, dynamic> json) {
    return SongUrl(
      id: json['id']?.toString() ?? '',
      url: json['url'] ?? '',
      br: json['br'],
      size: json['size'],
      type: json['type'],
      encodeType: json['encodeType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'br': br,
      'size': size,
      'type': type,
      'encodeType': encodeType,
    };
  }
}

/// Lyric Model
class Lyric {
  final int time;
  final String text;

  Lyric({required this.time, required this.text});

  factory Lyric.fromJson(Map<String, dynamic> json) {
    return Lyric(
      time: json['time'] ?? 0,
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'text': text,
    };
  }
}

/// Lyrics Model
class Lyrics {
  final String? lyric;
  final String? tlyric; // translation
  final List<Lyric> lyrics;
  final bool isOriginal;

  Lyrics({
    this.lyric,
    this.tlyric,
    List<Lyric>? lyrics,
    this.isOriginal = true,
  }) : lyrics = lyrics ?? [];

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    List<Lyric> parsedLyrics = [];
    final lyricText = json['lrc']?['lyric'] ?? json['lyric'] ?? '';

    if (lyricText.isNotEmpty) {
      parsedLyrics = _parseLyric(lyricText);
    }

    return Lyrics(
      lyric: lyricText,
      tlyric: json['tlyric']?['lyric'],
      lyrics: parsedLyrics,
      isOriginal: json['lrc']?['lyric'] != null || json['lyric'] != null,
    );
  }

  static List<Lyric> _parseLyric(String lyricText) {
    final lines = lyricText.split('\n');
    final lyrics = <Lyric>[];

    for (final line in lines) {
      if (line.isEmpty || !line.startsWith('[')) continue;

      final firstBracketEnd = line.indexOf(']');
      if (firstBracketEnd == -1) continue;

      final timeTag = line.substring(1, firstBracketEnd);
      final text = line.substring(firstBracketEnd + 1).trim();

      if (text.isEmpty) continue;

      final time = _parseTimeTag(timeTag);
      if (time >= 0) {
        lyrics.add(Lyric(time: time, text: text));
      }
    }

    return lyrics;
  }

  static int _parseTimeTag(String timeTag) {
    final parts = timeTag.split(':');
    if (parts.length != 2) return -1;

    try {
      final minutes = double.tryParse(parts[0]) ?? 0;
      final seconds = double.tryParse(parts[1]) ?? 0;
      return ((minutes * 60 + seconds) * 1000).toInt();
    } catch (_) {
      return -1;
    }
  }

  Lyric? getLyricAt(int positionMs) {
    for (int i = 0; i < lyrics.length; i++) {
      if (lyrics[i].time > positionMs) {
        return i > 0 ? lyrics[i - 1] : null;
      }
    }
    return lyrics.isNotEmpty ? lyrics.last : null;
  }

  int getLyricIndex(int positionMs) {
    for (int i = 0; i < lyrics.length; i++) {
      if (lyrics[i].time > positionMs) {
        return i > 0 ? i - 1 : 0;
      }
    }
    return lyrics.isNotEmpty ? lyrics.length - 1 : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'lrc': {'lyric': lyric},
      'tlyric': {'lyric': tlyric},
    };
  }
}
