import 'package:flutter/material.dart';
import '../../../data/models/playlist.dart';
import '../../../data/services/music_api_service.dart';
import '../../widgets/common/playlist_card.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage>
    with SingleTickerProviderStateMixin {
  final MusicApiService _apiService = MusicApiService();

  late TabController _tabController;

  // Categories
  final List<String> categories = [
    '推荐',
    '华语',
    '流行',
    '摇滚',
    '民谣',
    '电子',
    '轻音乐',
  ];

  int selectedCategory = 0;

  // Data
  List<Playlist> playlists = [];
  List<Playlist> topPlaylists = [];
  List<Playlist> rankingPlaylists = [];

  // Loading states
  bool isLoadingTopPlaylists = false;
  bool isLoadingRankings = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        selectedCategory = _tabController.index;
      });
      _loadPlaylists();
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTopPlaylists(),
      _loadRankings(),
      _loadPlaylists(),
    ]);
  }

  Future<void> _loadTopPlaylists() async {
    try {
      final result = await _apiService.getHighQualityPlaylists(limit: 10);
      if (mounted && result.isNotEmpty) {
        setState(() {
          topPlaylists = result;
        });
      }
    } catch (e) {
      print('Error loading top playlists: $e');
    }
  }

  Future<void> _loadRankings() async {
    try {
      final result = await _apiService.getTopList();
      if (mounted && result.isNotEmpty) {
        setState(() {
          rankingPlaylists = result;
        });
      }
    } catch (e) {
      print('Error loading rankings: $e');
    }
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      isLoading = true;
    });
    try {
      final category = categories[selectedCategory];
      final result = await _apiService.getHotPlaylists(
        cat: category == '推荐' ? '全部' : category,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          playlists = result;
        });
      }
    } catch (e) {
      print('Error loading playlists: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Categories Tab Bar
                  SliverToBoxAdapter(child: _buildCategories()),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Top Playlists Section (horizontal scroll)
                  SliverToBoxAdapter(child: _buildTopPlaylistsSection()),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Rankings Section (horizontal scroll)
                  SliverToBoxAdapter(child: _buildRankingsSection()),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Category Playlists Grid
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '歌单推荐',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Grid Content
                  if (isLoading && playlists.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (playlists.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: Text('暂无歌单')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.58,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return PlaylistCard(
                              playlist: playlists[index],
                              width: null,
                            );
                          },
                          childCount: playlists.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPlaylistsSection() {
    if (topPlaylists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '精品歌单',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: topPlaylists.length,
            itemBuilder: (context, index) {
              return PlaylistCard(
                playlist: topPlaylists[index],
                width: 140,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsSection() {
    if (rankingPlaylists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '排行榜',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: rankingPlaylists.length,
            itemBuilder: (context, index) {
              return PlaylistCard(
                playlist: rankingPlaylists[index],
                width: 140,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            '发现',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 3,
        tabs: categories.map((category) {
          return Tab(text: category);
        }).toList(),
      ),
    );
  }
}
