import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/playlist.dart';
import '../../../data/models/song.dart';
import '../../../data/services/music_api_service.dart';
import '../../../data/providers/player_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/song_item.dart';

class PlaylistPage extends StatefulWidget {
  final String playlistId;

  const PlaylistPage({super.key, required this.playlistId});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final MusicApiService _apiService = MusicApiService();
  final PlayerProvider _playerProvider = Get.find<PlayerProvider>();

  // Data
  final Rx<PlaylistDetail?> playlistDetail = Rx<PlaylistDetail?>(null);
  final RxList<Song> songs = <Song>[].obs;

  // Loading state
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    isLoading.value = true;
    try {
      final detail = await _apiService.getPlaylistDetail(widget.playlistId);
      if (detail != null) {
        playlistDetail.value = detail;
        songs.clear();
        songs.addAll(detail.songs.cast<Song>());
      }
    } catch (e) {
      // Silently handle error
    } finally {
      isLoading.value = false;
    }
  }

  void _playAll() {
    if (songs.isNotEmpty) {
      _playerProvider.setPlaylist(songs);
      Get.toNamed('/player');
    }
  }

  void _shufflePlay() {
    if (songs.isNotEmpty) {
      final shuffled = songs.toList()..shuffle();
      _playerProvider.setPlaylist(shuffled);
      Get.toNamed('/player');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Obx(() {
            if (isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final detail = playlistDetail.value;
            if (detail == null) {
              return const Center(child: Text('加载失败'));
            }

            return CustomScrollView(
              slivers: [
                // Header with blur background
                _buildHeader(context, detail.playlist),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Playlist Info Card
                    _buildPlaylistInfo(context, detail.playlist),

                    const SizedBox(height: 16),

                    // Action Buttons
                    _buildActionButtons(context),

                    const SizedBox(height: 16),

                    // Song List Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '歌曲列表 (${detail.playlist.trackCount})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('下载'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Song List
              songs.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无歌曲',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return SongItem(
                            song: songs[index],
                            onTap: () {
                              _playerProvider.setPlaylist(songs,
                                  startIndex: index);
                              Get.toNamed('/player');
                            },
                            onMoreTap: () {},
                          );
                        },
                        childCount: songs.length,
                      ),
                    ),
            ],
          );
        }),
      ),
    ),
  );
}

  Widget _buildHeader(BuildContext context, Playlist playlist) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (playlist.coverUrl != null)
              CachedNetworkImage(
                imageUrl: playlist.coverUrl!.replaceFirst('http:', 'https:'),
                fit: BoxFit.cover,
                httpHeaders: AppConstants.imageHeaders,
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).primaryColor,
                ),
              )
            else
              Container(color: Theme.of(context).primaryColor),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistInfo(BuildContext context, Playlist playlist) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 100,
              height: 100,
              child: playlist.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: playlist.coverUrl!.replaceFirst('http:', 'https:'),
                      fit: BoxFit.cover,
                      httpHeaders: AppConstants.imageHeaders,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.playlist_play, size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.playlist_play, size: 40),
                    ),
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'by ${playlist.creatorName ?? "未知"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.playlist_play,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${playlist.trackCount}首',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.play_circle,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatPlayCount(playlist.playCount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _playAll,
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放全部'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _shufflePlay,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.shuffle),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {},
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.favorite_border),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {},
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.comment_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    } else if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }
}
