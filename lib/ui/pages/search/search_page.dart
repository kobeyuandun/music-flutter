import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/song.dart';
import '../../../data/services/music_api_service.dart';
import '../../../data/providers/player_provider.dart';
import '../../widgets/common/song_item.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final MusicApiService _apiService = MusicApiService();
  final TextEditingController _searchController = TextEditingController();

  // Search State
  final RxBool isSearching = false.obs;
  final RxBool hasSearched = false.obs;

  // Data
  final RxList<String> hotSearch = <String>[].obs;
  final RxList<Song> searchResults = <Song>[].obs;

  @override
  void initState() {
    super.initState();
    _loadHotSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHotSearch() async {
    try {
      final result = await _apiService.getHotSearch();
      if (result.isNotEmpty) {
        hotSearch.value = result;
      }
    } catch (e) {
      print('Error loading hot search: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    isSearching.value = true;
    hasSearched.value = true;

    try {
      final result = await _apiService.search(
        keywords: query,
        limit: 50,
      );
      searchResults.value = result;
    } catch (e) {
      print('Error searching: $e');
    } finally {
      isSearching.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            _buildSearchHeader(context),

            // Search Types (only show after search)
            Obx(() {
              if (!hasSearched.value) return const SizedBox.shrink();
              return _buildSearchTypes();
            }),

            // Content
            Expanded(
              child: Obx(() {
                if (isSearching.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!hasSearched.value) {
                  return _buildSearchSuggestions(context);
                }

                return _buildSearchResults(context);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => _performSearch(value),
                decoration: InputDecoration(
                  hintText: '搜索歌曲、歌手、专辑...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            hasSearched.value = false;
                            searchResults.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTypes() {
    // Meting-API only supports song search, show a simple indicator
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.music_note, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 4),
          Text(
            '单曲',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hot Searches
          Obx(() {
            if (hotSearch.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '热门搜索',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hotSearch.take(10).map((keyword) {
                    return InkWell(
                      onTap: () {
                        _searchController.text = keyword;
                        _performSearch(keyword);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Chip(
                        label: Text(keyword),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }),

          const SizedBox(height: 32),

          // Quick Actions
          Text(
            '快速入口',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            children: const [
              _QuickEntry(icon: Icons.grade, label: '精品歌单'),
              _QuickEntry(icon: Icons.upcoming, label: '新歌速递'),
              _QuickEntry(icon: Icons.trending_up, label: '排行榜'),
              _QuickEntry(icon: Icons.podcasts, label: '电台'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到相关内容',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Show songs
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return SongItem(
          song: searchResults[index],
          onTap: () {
            final playerProvider = Get.find<PlayerProvider>();
            playerProvider.setPlaylist(searchResults, startIndex: index);
            Get.toNamed('/player');
          },
          onMoreTap: () {},
        );
      },
    );
  }
}

class _QuickEntry extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickEntry({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
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
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
