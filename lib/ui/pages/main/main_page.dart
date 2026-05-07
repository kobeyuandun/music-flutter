import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/home_page.dart';
import '../discovery/discovery_page.dart';
import '../search/search_page.dart';
import '../library/library_page.dart';
import '../profile/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final RxInt currentIndex = 0.obs;

  final List<Widget> pages = [
    const HomePage(),
    const DiscoveryPage(),
    const SearchPage(),
    const LibraryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: currentIndex.value,
        children: pages,
      )),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: currentIndex.value,
        onTap: (index) => currentIndex.value = index,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: '发现',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: '搜索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_outlined),
            activeIcon: Icon(Icons.library_music),
            label: '我的',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '账号',
          ),
        ],
      )),
    );
  }
}
