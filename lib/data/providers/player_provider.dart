import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/music_api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';

/// Player State
enum PlayerState { idle, loading, playing, paused, error, completed }

/// Play Mode
enum PlayMode { loop, shuffle, single }

/// Player Provider
class PlayerProvider extends GetxController with GetTickerProviderStateMixin {
  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Track which song is currently loaded to detect song changes
  String? _loadedSongId;

  // Current Playlist
  final RxList<Song> playlist = <Song>[].obs;

  // Current Song Index
  final RxInt currentIndex = 0.obs;

  // Current Play Mode
  final RxInt playMode = AppConstants.defaultPlayMode.obs;

  // Current Position
  final Rx<Duration> position = Duration.zero.obs;

  // Total Duration
  final Rx<Duration> duration = Duration.zero.obs;

  // Player State
  final Rx<PlayerState> playerState = PlayerState.idle.obs;

  // Volume
  final RxDouble volume = AppConstants.defaultVolume.obs;

  // Shuffle Indices
  List<int> shuffleIndices = [];

  // Current Song (getter)
  Song? get currentSong =>
      playlist.isNotEmpty && currentIndex.value < playlist.length
          ? playlist[currentIndex.value]
          : null;

  // Is Playing
  bool get isPlaying => playerState.value == PlayerState.playing;

  // Is Loading
  bool get isLoading => playerState.value == PlayerState.loading;

  // Progress (0.0 - 1.0)
  double get progress =>
      duration.value.inMilliseconds > 0
          ? position.value.inMilliseconds / duration.value.inMilliseconds
          : 0.0;

  // Formatted Position
  String get formattedPosition => DateUtils.formatDurationMs(
      position.value.inMilliseconds);

  // Formatted Duration
  String get formattedDuration =>
      DateUtils.formatDurationMs(duration.value.inMilliseconds);

  @override
  void onInit() {
    super.onInit();
    _initPlayer();
    _loadSettings();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  /// Initialize Audio Player
  void _initPlayer() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      // 优先处理 completed 状态
      if (state.processingState == ProcessingState.completed) {
        playerState.value = PlayerState.completed;
        _onSongComplete();
        return;
      }

      if (state.processingState == ProcessingState.idle) {
        playerState.value = PlayerState.idle;
        return;
      }

      // playing 标志优先于 processingState
      // 避免暂停时 buffering 状态覆盖 paused
      if (state.playing) {
        playerState.value = PlayerState.playing;
      } else if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        playerState.value = PlayerState.loading;
      } else {
        playerState.value = PlayerState.paused;
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((pos) {
      position.value = pos;
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        duration.value = dur;
      }
    });

    // Listen to errors
    _audioPlayer.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      playerState.value = PlayerState.error;
      Get.snackbar('播放错误', e.toString());
    });
  }

  /// Load saved settings
  void _loadSettings() async {
    // Load play mode
    final savedMode = GetStorage().read('play_mode');
    if (savedMode != null) {
      playMode.value = savedMode;
    }

    // Load volume
    final savedVolume = GetStorage().read('volume');
    if (savedVolume != null) {
      volume.value = savedVolume;
      _audioPlayer.setVolume(savedVolume);
    }
  }

  /// Set Playlist
  void setPlaylist(List<Song> newPlaylist, {int startIndex = 0}) {
    playlist.clear();
    playlist.addAll(newPlaylist);
    currentIndex.value = startIndex.clamp(0, playlist.length - 1);
    _generateShuffleIndices();
    play();
  }

  /// Add to Playlist
  void addToPlaylist(Song song) {
    playlist.add(song);
  }

  /// Add multiple to Playlist
  void addMultipleToPlaylist(List<Song> songs) {
    playlist.addAll(songs);
  }

  /// Remove from Playlist
  void removeFromPlaylist(int index) {
    if (index >= 0 && index < playlist.length) {
      playlist.removeAt(index);
      if (currentIndex.value >= playlist.length) {
        currentIndex.value = playlist.length - 1;
      }
    }
  }

  /// Play specific song
  void playSong(int index) {
    if (index >= 0 && index < playlist.length) {
      currentIndex.value = index;
      play();
    }
  }

  /// Play (resume if same song is paused, otherwise load and play)
  Future<void> play() async {
    if (currentSong == null) return;

    final isSameSong = _loadedSongId == currentSong!.id;

    // Only resume if it's the same song and player is ready but paused
    if (isSameSong &&
        _audioPlayer.processingState == ProcessingState.ready &&
        !_audioPlayer.playing) {
      await _audioPlayer.play();
      playerState.value = PlayerState.playing;
      return;
    }

    playerState.value = PlayerState.loading;

    try {
      // Always reload URL when switching songs
      final apiService = MusicApiService();
      String? songUrl = currentSong!.audioUrl;
      // Skip pre-validation: CDN URLs expire quickly, let ExoPlayer handle errors
      if (songUrl == null || songUrl.isEmpty || songUrl.contains('music.163.com/404')) {
        songUrl = await apiService.getSongUrl(
          currentSong!.id,
          songName: currentSong!.name,
          artistName: currentSong!.artistNames,
        );
        if (songUrl != null && songUrl.isNotEmpty) {
          currentSong!.audioUrl = songUrl;
        } else {
          playerState.value = PlayerState.error;
          Get.snackbar('错误', '当前歌曲暂无可用播放地址');
          return;
        }
      }

      // Prepare and play
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://music.163.com/',
      };
      final source = AudioSource.uri(Uri.parse(songUrl), headers: headers);

      // Switching songs: stop old source first, then load new one
      if (!isSameSong) {
        await _audioPlayer.stop();
      }

      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.play();

      _loadedSongId = currentSong!.id;
      playerState.value = PlayerState.playing;
      _addToHistory(currentSong!);
    } catch (e) {
      playerState.value = PlayerState.error;
      Get.snackbar('播放失败', e.toString());
    }
  }

  /// Pause
  Future<void> pause() async {
    await _audioPlayer.pause();
    playerState.value = PlayerState.paused;
  }

  /// Toggle Play/Pause
  Future<void> togglePlay() async {
    if (isPlaying) {
      await pause();
    } else {
      if (currentSong != null) {
        await play();
      }
    }
  }

  /// Stop
  Future<void> stop() async {
    await _audioPlayer.stop();
    playerState.value = PlayerState.idle;
  }

  /// Seek
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Seek to percentage
  Future<void> seekToPercentage(double percentage) async {
    final target = duration.value * percentage.clamp(0.0, 1.0);
    await seek(target);
  }

  /// Next
  void next() {
    if (playlist.isEmpty) return;

    int nextIndex;
    switch (playMode.value) {
      case 1: // shuffle
        nextIndex = _getNextShuffleIndex();
        break;
      case 2: // single
        nextIndex = currentIndex.value;
        break;
      default: // loop
        nextIndex = (currentIndex.value + 1) % playlist.length;
    }

    currentIndex.value = nextIndex;
    play();
  }

  /// Previous
  void previous() {
    if (playlist.isEmpty) return;

    // If played more than 3 seconds, restart current song
    if (position.value.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    int prevIndex;
    switch (playMode.value) {
      case 1: // shuffle
        prevIndex = _getPreviousShuffleIndex();
        break;
      case 2: // single
        prevIndex = currentIndex.value;
        break;
      default: // loop
        prevIndex = (currentIndex.value - 1 + playlist.length) % playlist.length;
    }

    currentIndex.value = prevIndex;
    play();
  }

  /// Set Play Mode
  void setPlayMode(int mode) {
    playMode.value = mode;
    final storage = GetStorage();
    storage.write('play_mode', mode);
    if (mode == 1) { // shuffle
      _generateShuffleIndices();
    }
    String modeName;
    switch (mode) {
      case 0:
        modeName = '列表循环';
        break;
      case 1:
        modeName = '随机播放';
        break;
      case 2:
        modeName = '单曲循环';
        break;
      default:
        modeName = '列表循环';
    }
    Get.snackbar('播放模式', modeName);
  }

  /// Toggle Play Mode
  void togglePlayMode() {
    int nextMode = (playMode.value + 1) % 3;
    setPlayMode(nextMode);
  }

  /// Set Volume
  Future<void> setVolume(double vol) async {
    final normalizedVol = vol.clamp(0.0, 1.0);
    volume.value = normalizedVol;
    await _audioPlayer.setVolume(normalizedVol);
    GetStorage().write('volume', normalizedVol);
  }

  /// Generate Shuffle Indices
  void _generateShuffleIndices() {
    shuffleIndices = List.generate(playlist.length, (i) => i);
    shuffleIndices.shuffle();
    if (shuffleIndices.isNotEmpty && currentIndex.value < shuffleIndices.length) {
      // Move current index to front
      shuffleIndices.remove(currentIndex.value);
      shuffleIndices.insert(0, currentIndex.value);
    }
  }

  /// Get Next Shuffle Index
  int _getNextShuffleIndex() {
    if (shuffleIndices.isEmpty) {
      _generateShuffleIndices();
    }
    final currentShuffleIndex =
        shuffleIndices.indexOf(currentIndex.value);
    if (currentShuffleIndex < shuffleIndices.length - 1) {
      return shuffleIndices[currentShuffleIndex + 1];
    } else {
      // Reshuffle when reaching the end
      _generateShuffleIndices();
      return shuffleIndices.isNotEmpty ? shuffleIndices[0] : 0;
    }
  }

  /// Get Previous Shuffle Index
  int _getPreviousShuffleIndex() {
    if (shuffleIndices.isEmpty) {
      _generateShuffleIndices();
    }
    final currentShuffleIndex =
        shuffleIndices.indexOf(currentIndex.value);
    if (currentShuffleIndex > 0) {
      return shuffleIndices[currentShuffleIndex - 1];
    } else {
      return currentIndex.value;
    }
  }

  /// On Song Complete
  void _onSongComplete() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (playMode.value == 2) { // single loop
        play();
      } else {
        next();
      }
    });
  }

  /// Add to Play History
  void _addToHistory(Song song) async {
    final storage = GetStorage();
    List<String> history = storage.read(AppConstants.keyPlayHistory) ?? [];

    // Remove if already exists
    history.remove(song.id);

    // Add to front
    history.insert(0, song.id);

    // Keep only last 100
    if (history.length > 100) {
      history = history.sublist(0, 100);
    }

    await storage.write(AppConstants.keyPlayHistory, history);
  }

  /// Clear Playlist
  void clearPlaylist() {
    stop();
    playlist.clear();
    currentIndex.value = 0;
  }
}
