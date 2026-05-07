import 'package:flutter_test/flutter_test.dart';
import 'package:music_flutter/data/services/music_api_service.dart';

void main() {
  test('MusicApiService can fetch recommend songs', () async {
    final service = MusicApiService();
    final songs = await service.getRecommendSongs();
    print('Songs count: \${songs.length}');
    for (final song in songs.take(3)) {
      print('Song: \${song.name} - \${song.artistNames}');
    }
    expect(songs.isNotEmpty, true);
  });

  test('MusicApiService can fetch recommend playlists', () async {
    final service = MusicApiService();
    final playlists = await service.getRecommendPlaylists();
    print('Playlists count: \${playlists.length}');
    for (final p in playlists) {
      print('Playlist: \${p.name} (\${p.trackCount} tracks)');
    }
    expect(playlists.isNotEmpty, true);
  });
}
