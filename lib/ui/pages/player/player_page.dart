import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/providers/player_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart' as utils;

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with SingleTickerProviderStateMixin {
  final PlayerProvider _playerProvider = Get.find<PlayerProvider>();
  final UserProvider _userProvider = Get.find<UserProvider>();

  late AnimationController _albumController;
  late Animation<double> _albumAnimation;
  Worker? _playerStateWorker;

  @override
  void initState() {
    super.initState();
    _albumController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _albumAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _albumController, curve: Curves.linear),
    );

    // Start rotation when playing
    _playerStateWorker = ever(_playerProvider.playerState, (state) {
      if (!mounted) return;
      if (state == PlayerState.playing) {
        _albumController.repeat();
      } else {
        _albumController.stop();
      }
    });
  }

  @override
  void dispose() {
    _playerStateWorker?.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取底部安全区域高度（系统导航栏）
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.3),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final currentSong = _playerProvider.currentSong;
            if (currentSong == null) {
              return const Center(child: Text('没有正在播放的歌曲'));
            }

            return Column(
              children: [
                // Header
                _buildHeader(context, currentSong),

                // Album Art - 使用Flexible自适应高度
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _buildAlbumArt(context, currentSong),
                  ),
                ),

                // Song Info
                _buildSongInfo(context, currentSong),

                // Progress Bar
                const SizedBox(height: 16),
                _buildProgressBar(context),

                // Controls
                const SizedBox(height: 16),
                _buildControls(context),

                // Actions
                const SizedBox(height: 16),
                _buildActions(context, currentSong),

                // Playlist Button + 底部安全区域padding
                _buildPlaylistButton(context, bottomPadding),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, currentSong) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  currentSong.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentSong.artistNames,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(BuildContext context, currentSong) {
    // 根据屏幕大小自适应专辑封面尺寸
    final screenSize = MediaQuery.of(context).size;
    final albumSize = screenSize.width * 0.6; // 屏幕宽度的60%
    final actualSize = albumSize.clamp(200.0, 320.0);

    // 处理图片URL
    String? imageUrl = currentSong.coverUrl;
    debugPrint('AlbumArt: original coverUrl=$imageUrl');

    // 检查URL是否有效
    bool isValidUrl = imageUrl != null &&
                      imageUrl.isNotEmpty &&
                      !imageUrl.contains('192.168.') &&
                      !imageUrl.contains('localhost') &&
                      !imageUrl.contains('10.0.2.2') &&
                      !imageUrl.contains('127.0.0.1');

    if (!isValidUrl) {
      debugPrint('AlbumArt: Invalid URL, using default');
      imageUrl = 'https://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg';
    }

    // 确保是HTTPS
    if (imageUrl.startsWith('http:')) {
      imageUrl = imageUrl.replaceFirst('http:', 'https:');
    }

    debugPrint('AlbumArt: final imageUrl=$imageUrl');

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: actualSize,
      height: actualSize,
      fit: BoxFit.cover,
      httpHeaders: AppConstants.imageHeaders,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) {
        debugPrint('AlbumArt Error loading $imageUrl: $error');
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.music_note, size: actualSize * 0.3),
        );
      },
    );

    return Center(
      child: SizedBox(
        width: actualSize,
        height: actualSize,
        child: AnimatedBuilder(
          animation: _albumAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _albumAnimation.value * 3.14159 * 2,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imageWidget,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, currentSong) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSong.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  currentSong.artistNames,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          Obx(() => IconButton(
            icon: Icon(
              _userProvider.isSongLiked(currentSong.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: _userProvider.isSongLiked(currentSong.id)
                  ? Colors.red
                  : null,
            ),
            onPressed: () {
              _userProvider.toggleLikeSong(currentSong.id);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Obx(() {
      final position = _playerProvider.position.value;
      final duration = _playerProvider.duration.value;
      final progress = _playerProvider.progress;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (value) {
                  _playerProvider.seekToPercentage(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    utils.DateUtils.formatDurationMs(position.inMilliseconds),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    utils.DateUtils.formatDurationMs(duration.inMilliseconds),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildControls(BuildContext context) {
    return Obx(() {
      // 直接监听 playerState
      final currentState = _playerProvider.playerState.value;
      final isCurrentlyPlaying = currentState == PlayerState.playing;
      final currentMode = _playerProvider.playMode.value;
      debugPrint('Controls: state=$currentState, isPlaying=$isCurrentlyPlaying');

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play Mode
          IconButton(
            icon: Icon(_getPlayModeIcon(currentMode)),
            iconSize: 28,
            onPressed: _playerProvider.togglePlayMode,
          ),

          const SizedBox(width: 16),

          // Previous
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 36,
            onPressed: _playerProvider.previous,
          ),

          const SizedBox(width: 16),

          // Play/Pause
          MaterialButton(
            onPressed: () {
              debugPrint('Play button clicked, current state: $currentState');
              _playerProvider.togglePlay();
            },
            color: Theme.of(context).primaryColor,
            shape: const CircleBorder(),
            height: 64,
            minWidth: 64,
            child: Icon(
              isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 16),

          // Next
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 36,
            onPressed: _playerProvider.next,
          ),

          const SizedBox(width: 16),

          // Volume
          IconButton(
            icon: const Icon(Icons.volume_up),
            iconSize: 28,
            onPressed: () => _showVolumeDialog(context),
          ),
        ],
      );
    });
  }

  Widget _buildActions(BuildContext context, currentSong) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.download_outlined,
          label: '下载',
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.comment_outlined,
          label: '评论',
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.more_horiz,
          label: '更多',
          onTap: () => _showMoreOptions(context, currentSong),
        ),
      ],
    );
  }

  Widget _buildPlaylistButton(BuildContext context, double bottomPadding) {
    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton.icon(
        onPressed: () => _showPlaylistSheet(context),
        icon: const Icon(Icons.playlist_play),
        label: const Text('播放列表'),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  IconData _getPlayModeIcon(int mode) {
    switch (mode) {
      case 0:
        return Icons.repeat;
      case 1:
        return Icons.shuffle;
      case 2:
        return Icons.repeat_one;
      default:
        return Icons.repeat;
    }
  }

  void _showVolumeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        double volume = _playerProvider.volume.value;
        return AlertDialog(
          title: const Text('音量'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    volume == 0 ? Icons.volume_off : Icons.volume_up,
                    size: 48,
                  ),
                  Slider(
                    value: volume,
                    onChanged: (value) {
                      setState(() => volume = value);
                      _playerProvider.setVolume(value);
                    },
                  ),
                  Text('${(volume * 100).toInt()}%'),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context, currentSong) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('添加到歌单'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('查看歌手'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.album),
              title: const Text('查看专辑'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('从列表删除'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Obx(() {
          final playlist = _playerProvider.playlist;
          if (playlist.isEmpty) {
            return const SizedBox(
              height: 200,
              child: Center(child: Text('播放列表为空')),
            );
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          '播放列表 (${playlist.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.clear_all),
                          onPressed: () {
                            _playerProvider.clearPlaylist();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Playlist
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: playlist.length,
                      itemBuilder: (context, index) {
                        final song = playlist[index];
                        final isCurrent =
                            index == _playerProvider.currentIndex.value;

                        return ListTile(
                          leading: SizedBox(
                            width: 40,
                            child: Center(
                              child: isCurrent
                                  ? Icon(Icons.volume_up,
                                      color: Theme.of(context).primaryColor)
                                  : Text('${index + 1}'),
                            ),
                          ),
                          title: Text(
                            song.name,
                            style: TextStyle(
                              color: isCurrent
                                  ? Theme.of(context).primaryColor
                                  : null,
                              fontWeight:
                                  isCurrent ? FontWeight.bold : null,
                            ),
                          ),
                          subtitle: Text(song.artistNames),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _playerProvider.removeFromPlaylist(index);
                            },
                          ),
                          onTap: () {
                            _playerProvider.playSong(index);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
