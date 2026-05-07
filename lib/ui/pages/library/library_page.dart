import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/models/playlist.dart';
import '../../widgets/common/playlist_card.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  final UserProvider _userProvider = Get.find<UserProvider>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Tabs
            _buildTabs(),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCreatedPlaylists(),
                  _buildSubscribedPlaylists(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            '我的音乐',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
      indicatorColor: Theme.of(context).primaryColor,
      tabs: const [
        Tab(text: '创建的歌单'),
        Tab(text: '收藏的歌单'),
      ],
    );
  }

  Widget _buildCreatedPlaylists() {
    return Obx(() {
      final playlists = _userProvider.playlists
          .where((p) => p.subscribed != true)
          .toList();

      if (playlists.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.playlist_add,
                size: 64,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                '还没有创建歌单',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          return PlaylistCard(
            playlist: playlists[index],
            width: null,
          );
        },
      );
    });
  }

  Widget _buildSubscribedPlaylists() {
    return Obx(() {
      final playlists = _userProvider.playlists
          .where((p) => p.subscribed == true)
          .toList();

      if (playlists.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                '还没有收藏歌单',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          return PlaylistCard(
            playlist: playlists[index],
            width: null,
          );
        },
      );
    });
  }
}
