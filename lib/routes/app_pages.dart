import 'package:get/get.dart';
import '../ui/pages/splash/splash_page.dart';
import '../ui/pages/login/login_page.dart';
import '../ui/pages/main/main_page.dart';
import '../ui/pages/home/home_page.dart';
import '../ui/pages/discovery/discovery_page.dart';
import '../ui/pages/search/search_page.dart';
import '../ui/pages/library/library_page.dart';
import '../ui/pages/profile/profile_page.dart';
import '../ui/pages/player/player_page.dart';
import '../ui/pages/playlist/playlist_page.dart';
import '../ui/pages/chess/chess_page.dart';
import 'app_routes.dart';

/// App Pages Configuration
class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainPage(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
    ),
    GetPage(
      name: AppRoutes.discovery,
      page: () => const DiscoveryPage(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
    ),
    GetPage(
      name: AppRoutes.library,
      page: () => const LibraryPage(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
    ),
    GetPage(
      name: AppRoutes.player,
      page: () => const PlayerPage(),
    ),
    GetPage(
      name: AppRoutes.playlist,
      page: () => PlaylistPage(playlistId: Get.parameters['id'] ?? ''),
    ),
    GetPage(
      name: AppRoutes.chess,
      page: () => const ChessPage(),
    ),
  ];

  static final pages = routes;

  static String getInitialRoute() {
    return AppRoutes.splash;
  }
}
