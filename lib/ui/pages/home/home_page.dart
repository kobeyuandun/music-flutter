import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/playlist.dart';
import '../../../data/models/song.dart';
import '../../../data/services/music_api_service.dart';
import '../../../data/providers/player_provider.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/playlist_card.dart';
import '../../widgets/common/song_item.dart';
import '../../../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MusicApiService _apiService = MusicApiService();

  // Data
  List<Playlist> recommendPlaylists = [];
  List<Song> recommendSongs = [];
  List<Song> newSongs = [];

  // Loading states
  bool isLoadingPlaylists = true;
  bool isLoadingSongs = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadRecommendPlaylists(),
      _loadRecommendSongs(),
    ]);
  }

  Future<void> _loadRecommendPlaylists() async {
    try {
      final result = await _apiService.getRecommendPlaylists();
      if (mounted) {
        setState(() {
          if (result.isNotEmpty) {
            recommendPlaylists = result.take(20).toList();
          }
          isLoadingPlaylists = false;
        });
      }
    } catch (e) {
      print('Error loading playlists: $e');
      if (mounted) {
        setState(() {
          isLoadingPlaylists = false;
        });
      }
    }
  }

  Future<void> _loadRecommendSongs() async {
    try {
      final result = await _apiService.getRecommendSongs();
      if (mounted) {
        setState(() {
          if (result.isNotEmpty) {
            recommendSongs = result.take(20).toList();
          }
          isLoadingSongs = false;
        });
      }
    } catch (e) {
      print('Error loading songs: $e');
      if (mounted) {
        setState(() {
          isLoadingSongs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Row(
                children: [
                  // App Logo/Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.music_note, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Music',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _QuickAction(
                          icon: Icons.favorite_border,
                          label: '每日推荐',
                          onTap: () {},
                        ),
                        _QuickAction(
                          icon: Icons.radio_outlined,
                          label: '私人FM',
                          onTap: () {},
                        ),
                        _QuickAction(
                          icon: Icons.playlist_play,
                          label: '歌单',
                          onTap: () {},
                        ),
                        _QuickAction(
                          icon: Icons.leaderboard,
                          label: '排行榜',
                          onTap: () {},
                        ),
                        _QuickAction(
                          icon: Icons.sports_esports,
                          label: '象棋',
                          onTap: () => Get.toNamed(AppRoutes.chess),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Recommend Playlists Section
                  SectionHeader(
                    title: '推荐歌单',
                    onMoreTap: () {},
                  ),

                  const SizedBox(height: 8),

                  // Recommend Playlists Horizontal List
                  _buildPlaylistsSection(),

                  const SizedBox(height: 24),

                  // Recommend Songs Section
                  SectionHeader(
                    title: '推荐歌曲',
                    onMoreTap: () {},
                  ),

                  const SizedBox(height: 8),

                  // Recommend Songs List
                  _buildSongsSection(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistsSection() {
    if (isLoadingPlaylists) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (recommendPlaylists.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('暂无推荐歌单')),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: recommendPlaylists.length,
        itemBuilder: (context, index) {
          return PlaylistCard(
            playlist: recommendPlaylists[index],
            width: 120,
          );
        },
      ),
    );
  }

  Widget _buildSongsSection() {
    if (isLoadingSongs) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (recommendSongs.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('暂无推荐歌曲')),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: recommendSongs.length,
      itemBuilder: (context, index) {
        return SongItem(
          song: recommendSongs[index],
          onTap: () {
            final playerProvider = Get.find<PlayerProvider>();
            playerProvider.setPlaylist(recommendSongs, startIndex: index);
            Get.toNamed('/player');
          },
          onMoreTap: () {},
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '夜深了';
    } else if (hour < 12) {
      return '早上好';
    } else if (hour < 18) {
      return '下午好';
    } else {
      return '晚上好';
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
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
