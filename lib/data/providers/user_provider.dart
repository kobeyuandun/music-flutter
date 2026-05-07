import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/music_api_service.dart';
import '../../core/constants/app_constants.dart';

/// User Auth State
enum AuthState { unknown, unauthenticated, authenticating, authenticated }

/// User Provider
class UserProvider extends GetxController {
  // API Service
  final MusicApiService _apiService = MusicApiService();

  // Current User
  final Rx<User?> currentUser = Rx<User?>(null);

  // Auth State
  final Rx<AuthState> authState = AuthState.unknown.obs;

  // User Playlists
  final RxList<Playlist> playlists = <Playlist>[].obs;

  // Liked Songs IDs
  final RxList<String> likedSongIds = <String>[].obs;

  // Is Loading
  final RxBool isLoading = false.obs;

  // Getters
  bool get isAuthenticated => authState.value == AuthState.authenticated;
  bool get isAuthenticating => authState.value == AuthState.authenticating;
  bool get isGuest => authState.value == AuthState.unauthenticated;

  // Favorite Playlist (usually "我喜欢的音乐")
  Playlist? get favoritePlaylist {
    if (playlists.isEmpty) return null;
    return playlists.firstWhere(
      (p) => p.name == '我喜欢的音乐',
      orElse: () => playlists.first,
    );
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  /// Load User Data from Storage
  Future<void> _loadUserData() async {
    final storage = GetStorage();

    // Check if user is logged in
    final userId = storage.read(AppConstants.keyUserId);
    if (userId != null) {
      // Load user info from storage
      final userInfo = storage.read(AppConstants.keyUserInfo);
      if (userInfo != null) {
        try {
          currentUser.value = User.fromJson(userInfo);
          authState.value = AuthState.authenticated;
        } catch (e) {
          authState.value = AuthState.unauthenticated;
        }
      } else {
        // Try to fetch user detail from API
        await fetchUserDetail(userId);
      }

      // Load liked songs
      await _loadLikedSongs();

      // Load playlists
      await fetchUserPlaylists(userId);
    } else {
      authState.value = AuthState.unauthenticated;
    }
  }

  /// Login with Phone
  Future<bool> loginWithPhone({
    required String phone,
    required String password,
    String countryCode = '86',
  }) async {
    authState.value = AuthState.authenticating;
    isLoading.value = true;

    try {
      final response = await _apiService.loginWithPhone(
        phone: phone,
        password: password,
        countrycode: countryCode,
      );

      if (response.success && response.user != null) {
        await _handleLoginSuccess(response);
        return true;
      } else {
        authState.value = AuthState.unauthenticated;
        Get.snackbar('登录失败', response.errorMessage ?? '未知错误');
        return false;
      }
    } catch (e) {
      authState.value = AuthState.unauthenticated;
      Get.snackbar('登录失败', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Login with Email
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    authState.value = AuthState.authenticating;
    isLoading.value = true;

    try {
      final response = await _apiService.loginWithEmail(
        email: email,
        password: password,
      );

      if (response.success && response.user != null) {
        await _handleLoginSuccess(response);
        return true;
      } else {
        authState.value = AuthState.unauthenticated;
        Get.snackbar('登录失败', response.errorMessage ?? '未知错误');
        return false;
      }
    } catch (e) {
      authState.value = AuthState.unauthenticated;
      Get.snackbar('登录失败', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle Login Success
  Future<void> _handleLoginSuccess(LoginResponse response) async {
    final storage = GetStorage();

    // Save user info
    currentUser.value = response.user!;
    await storage.write(AppConstants.keyUserId, response.user!.id);
    await storage.write(AppConstants.keyUserInfo, response.user!.toJson());

    // Save token if available
    if (response.token != null) {
      await storage.write(AppConstants.keyToken, response.token);
    }

    // Save cookie if available
    if (response.cookie != null) {
      await storage.write('cookie', response.cookie);
    }

    authState.value = AuthState.authenticated;

    // Fetch user playlists
    if (response.user!.id.isNotEmpty) {
      await fetchUserPlaylists(response.user!.id);
    }

    Get.snackbar('登录成功', '欢迎回来，${response.user!.nickname}');
  }

  /// Logout
  Future<void> logout() async {
    final storage = GetStorage();

    // Call logout API
    await _apiService.logout();

    // Clear local storage
    await storage.remove(AppConstants.keyUserId);
    await storage.remove(AppConstants.keyUserInfo);
    await storage.remove(AppConstants.keyToken);
    await storage.remove('cookie');

    // Clear state
    currentUser.value = null;
    authState.value = AuthState.unauthenticated;
    playlists.clear();
    likedSongIds.clear();

    Get.offAllNamed('/login');
  }

  /// Fetch User Detail
  Future<void> fetchUserDetail(String userId) async {
    try {
      final user = await _apiService.getUserDetail(userId);
      if (user != null) {
        currentUser.value = user;
        final storage = GetStorage();
        await storage.write(AppConstants.keyUserInfo, user.toJson());
      }
    } catch (e) {
      print('Error fetching user detail: $e');
    }
  }

  /// Fetch User Playlists
  Future<void> fetchUserPlaylists(String userId) async {
    try {
      final result = await _apiService.getUserPlaylists(userId);
      if (result != null) {
        playlists.clear();
        playlists.addAll(result.playlists.cast<Playlist>());
      }
    } catch (e) {
      // Silently handle error
    }
  }

  /// Load Liked Songs
  Future<void> _loadLikedSongs() async {
    final storage = GetStorage();
    final liked = storage.read(AppConstants.keyLikedSongs);
    if (liked != null && liked is List) {
      likedSongIds.clear();
      likedSongIds.addAll(List<String>.from(liked));
    }
  }

  /// Toggle Like Song
  Future<void> toggleLikeSong(String songId) async {
    if (likedSongIds.contains(songId)) {
      likedSongIds.remove(songId);
    } else {
      likedSongIds.add(songId);
    }

    // Save to storage
    final storage = GetStorage();
    await storage.write(AppConstants.keyLikedSongs, likedSongIds.toList());
  }

  /// Check if Song is Liked
  bool isSongLiked(String songId) {
    return likedSongIds.contains(songId);
  }

  /// Add Playlist
  void addPlaylist(Playlist playlist) {
    playlists.add(playlist);
  }

  /// Remove Playlist
  void removePlaylist(String playlistId) {
    playlists.removeWhere((p) => p.id == playlistId);
  }

  /// Update User Profile
  Future<bool> updateProfile({
    String? nickname,
    String? signature,
    String? avatarUrl,
  }) async {
    try {
      // This would call an API to update profile
      // For now, just update locally
      if (currentUser.value != null) {
        final updatedUser = currentUser.value!.copyWith(
          nickname: nickname ?? currentUser.value!.nickname,
          signature: signature ?? currentUser.value!.signature,
        );
        currentUser.value = updatedUser;

        final storage = GetStorage();
        await storage.write(AppConstants.keyUserInfo, updatedUser.toJson());

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
