# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter music player app with NetEase Cloud Music API integration. It provides music discovery, playlist management, audio playback, and user authentication features.

## Common Commands

### Development
- `flutter run` - Run the app in debug mode
- `flutter run --release` - Run in release mode
- `flutter devices` - List available devices

### Code Quality
- `flutter analyze` - Run static analysis
- `flutter format lib/` - Format all Dart files

### Testing
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run a specific test file

### Build
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app (macOS only)
- `flutter build web` - Build for web

### Code Generation
- `dart run build_runner build` - Generate code (JSON serializable, Hive adapters)

## Architecture

### State Management
The app uses **GetX** for state management:
- Controllers are in `lib/data/providers/` and extend `GetxController`
- `PlayerProvider` - Manages audio playback state using `just_audio`
- `UserProvider` - Manages user authentication and playlists
- Controllers are initialized as permanent singletons in `main.dart` using `Get.put()`
- UI uses `Obx()` widgets for reactive updates

### Routing
Routing uses GetX route management:
- Route definitions are in `lib/routes/app_routes.dart` (constants)
- Route configuration is in `lib/routes/app_pages.dart` (`GetPage` instances)
- Navigation uses `Get.toNamed()`, `Get.offAllNamed()`, etc.

### Project Structure
```
lib/
├── main.dart                 # App entry point, initializes GetStorage and providers
├── app.dart                  # Root widget (GetMaterialApp)
├── core/
│   ├── constants/            # App constants, API base URL, storage keys
│   ├── config/               # API endpoints and Dio configuration
│   ├── network/              # Dio HTTP client wrapper
│   ├── theme/                # Light/dark theme definitions
│   └── utils/                # Date formatting, player utilities
├── data/
│   ├── models/               # Data models (Song, Playlist, User, etc.)
│   ├── providers/            # GetX controllers for state management
│   └── services/             # API service layer (MusicApiService)
├── routes/
│   ├── app_routes.dart       # Route name constants
│   └── app_pages.dart        # GetPage route definitions
└── ui/
    ├── pages/                # Screen widgets organized by feature
    │   ├── home/             # Home page with recommendations
    │   ├── player/           # Full-screen music player
    │   ├── login/            # Authentication screens
    │   └── ...
    └── widgets/              # Reusable UI components
        └── common/           # Shared widgets (SongItem, PlaylistCard, etc.)
```

### Key Dependencies
- `get: ^4.6.5` - State management and routing
- `get_storage: ^2.0.15` - Local key-value storage
- `dio: ^5.1.1` - HTTP client for API calls
- `just_audio: ^0.9.36` - Audio playback
- `video_player: ^2.5.0` - Video playback for MVs

### API Integration

The app uses **Meting-API** - a unified music API that supports multiple platforms:

| Platform | Server Code |
|----------|-------------|
| 网易云音乐 | `netease` |
| QQ 音乐 | `tencent` |
| 酷狗音乐 | `kugou` |
| 酷我音乐 | `kuwo` |
| 百度音乐 | `baidu` |

**Meting-API Project**: https://github.com/xizeyoupan/Meting-API

#### Deploy Meting-API Locally

```bash
# Clone the repository
git clone https://github.com/xizeyoupan/Meting-API.git
cd Meting-API

# Install dependencies
npm install

# Start the server
npm start
# Server will run on http://localhost:3000
```

**Docker Deployment**:
```bash
docker run -d -p 3000:3000 xizeyoupan/meting-api
```

#### API Endpoint Format

Meting-API uses a unified endpoint with query parameters:
```
/api?server=:server&type=:type&id=:id
```

- `type`: search, song, playlist, album, artist, lrc, url, pic
- `server`: netease, tencent, kugou, kuwo, baidu
- `id`: resource ID or search keyword

Example:
```bash
curl "http://localhost:3000/api?server=netease&type=search&id=hello"
```

#### API Limitations

- **User authentication**: Not supported by Meting-API (login/logout features disabled)
- **Comments**: Not available through Meting-API
- **MV**: Not available through Meting-API
- **Recommendations**: Uses default playlist IDs as fallback

#### Switching Music Platform

Change the default platform in `AppConstants.defaultServer` or per-request:
```dart
final apiService = MusicApiService();
apiService.setServer('tencent');  // Switch to QQ Music
final songs = await apiService.search(keywords: '周杰伦');
```

### Data Models

Models are in `lib/data/models/`:
- `Song` - Core music track with `fromJson()` (NetEase format) and `fromMetingJson()` (Meting-API format)
- `Playlist` - User and curated playlists
- `User` - User profile (limited support with Meting-API)
- `MV` - Music video data (not available with Meting-API)
- `Comment` - Song/playlist comments (not available with Meting-API)
- `Search` - Search results and suggestions

All models include `fromJson()`, `toJson()`, `copyWith()`, and computed getters like `artistNames`.

### Storage
- `GetStorage` is used for persistent local storage
- Keys are defined in `AppConstants` (e.g., `keyUserId`, `keyToken`, `keyPlayHistory`)
- Player settings (volume, play mode) are persisted automatically

### Theming
- `AppTheme` defines both light and dark themes
- Primary color is red (`0xFFEC4141`) inspired by NetEase/QQ Music
- Uses Material 3 with custom component themes

### Debugging API Issues

If you're not getting song data:

1. Verify Meting-API is running: `curl "http://localhost:3000/api?server=netease&type=search&id=test"`
2. Check console logs - request/response logging is enabled in `DioClient`
3. Try different `server` parameter if one platform fails

### Important Patterns

1. **Reactive State**: Use Rx types (`RxString`, `RxList`, `RxBool`) in controllers and wrap UI in `Obx(() => ...)`
   ```dart
   final apiService = MusicApiService();
   final songs = await apiService.getRecommendSongs();
   ```

3. **Provider Access**: Access providers via GetX:
   ```dart
   final playerProvider = Get.find<PlayerProvider>();
   final userProvider = Get.find<UserProvider>();
   ```

4. **Navigation**: Use named routes with parameters:
   ```dart
   Get.toNamed('/playlist?id=$playlistId');
   // Access in page: Get.parameters['id']
   ```

5. **Snackbar Notifications**: Use `Get.snackbar()` for user feedback (follows app theme automatically)
