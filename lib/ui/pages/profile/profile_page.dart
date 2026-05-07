import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/providers/user_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/settings_item.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Get.find<UserProvider>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              floating: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                '账号',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _showSettings(context, userProvider),
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // User Info Card
                    Obx(() {
                      if (!userProvider.isAuthenticated) {
                        return _buildLoginCard(context, userProvider);
                      }
                      return _buildUserInfoCard(context, userProvider);
                    }),

                    const SizedBox(height: 24),

                    // Stats
                    Obx(() {
                      if (!userProvider.isAuthenticated) {
                        return const SizedBox.shrink();
                      }
                      return _buildStatsCard(context, userProvider);
                    }),

                    const SizedBox(height: 24),

                    // Menu Items
                    Obx(() {
                      if (!userProvider.isAuthenticated) {
                        return const SizedBox.shrink();
                      }
                      return _buildMenuItems(context);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_circle,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            '登录网易云音乐',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '手机号 / 邮箱登录',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.toNamed('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('立即登录'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, UserProvider userProvider) {
    final user = userProvider.currentUser.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundImage: user?.avatarUrl != null
                ? CachedNetworkImageProvider(
                    user!.avatarUrl!.replaceFirst('http:', 'https:'),
                    headers: AppConstants.imageHeaders,
                  )
                : null,
            child: user?.avatarUrl == null
                ? const Icon(Icons.person, size: 32)
                : null,
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.nickname ?? '未知用户',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: user?.isVip == true
                        ? Colors.amber
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user?.isVip == true ? 'VIP' : '普通用户',
                    style: TextStyle(
                      color: user?.isVip == true
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, UserProvider userProvider) {
    final user = userProvider.currentUser.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: '关注',
            value: user?.followCount?.toString() ?? '0',
          ),
          _StatItem(
            label: '粉丝',
            value: user?.followedCount?.toString() ?? '0',
          ),
          _StatItem(
            label: '歌单',
            value: user?.playlistCount?.toString() ?? '0',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final userProvider = Get.find<UserProvider>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SettingsItem(
            icon: Icons.favorite_border,
            title: '我喜欢的音乐',
            trailing: userProvider.likedSongIds.isEmpty
                ? null
                : Text('${userProvider.likedSongIds.length}首'),
            onTap: () {},
          ),
          Divider(
            height: 1,
            indent: 56,
            color: Theme.of(context).dividerColor,
          ),
          SettingsItem(
            icon: Icons.history,
            title: '最近播放',
            onTap: () {},
          ),
          Divider(
            height: 1,
            indent: 56,
            color: Theme.of(context).dividerColor,
          ),
          SettingsItem(
            icon: Icons.cloud_download_outlined,
            title: '下载管理',
            onTap: () {},
          ),
          Divider(
            height: 1,
            indent: 56,
            color: Theme.of(context).dividerColor,
          ),
          SettingsItem(
            icon: Icons.radio_outlined,
            title: '我的电台',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('深色模式'),
              trailing: Get.isPlatformDarkMode
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                // Toggle dark mode
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('关于'),
              onTap: () {
                Navigator.pop(context);
                _showAbout(context);
              },
            ),
            if (userProvider.isAuthenticated) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('退出登录', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context, userProvider);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Music Flutter',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.music_note, size: 48),
      children: [
        const Text('一款功能完整的Flutter音乐播放器应用'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              userProvider.logout();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
