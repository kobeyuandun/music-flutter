import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// API Configuration
class ApiConfig {
  static final ApiConfig _instance = ApiConfig._internal();
  factory ApiConfig() => _instance;
  ApiConfig._internal();

  late Dio _dio;

  Dio get dio => _dio;

  /// Initialize Dio
  void initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add token if available
        final storage = GetStorage();
        final token = storage.read(AppConstants.keyToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) {
        // Handle errors
        if (error.response != null) {
          switch (error.response?.statusCode) {
            case 401:
              // Unauthorized - redirect to login
              Get.offAllNamed('/login');
              break;
            case 500:
              Get.snackbar('错误', '服务器错误，请稍后重试');
              break;
            default:
              Get.snackbar(
                '错误',
                error.response?.data?['message'] ?? '网络请求失败',
              );
          }
        } else {
          Get.snackbar('错误', '网络连接失败');
        }
        return handler.next(error);
      },
    ));
  }
}

/// API Endpoints for Meting-API
/// Meting-API uses a unified endpoint /api with query parameters:
/// - server: netease, tencent, kugou, kuwo, baidu
/// - type: search, song, playlist, album, artist, lrc, url, pic
/// - id: the resource id or search keyword
class ApiEndpoints {
  static const String api = '/api';

  // Type parameters
  static const String typeSearch = 'search';
  static const String typeSong = 'song';
  static const String typePlaylist = 'playlist';
  static const String typeAlbum = 'album';
  static const String typeArtist = 'artist';
  static const String typeLrc = 'lrc';
  static const String typeUrl = 'url';
  static const String typePic = 'pic';

  // Server parameters
  static const String serverNetease = 'netease';
  static const String serverTencent = 'tencent';
  static const String serverKugou = 'kugou';
  static const String serverKuwo = 'kuwo';
  static const String serverBaidu = 'baidu';

  /// Build API URL with parameters
  static String buildUrl({
    required String type,
    required String id,
    String server = AppConstants.defaultServer,
  }) {
    return '$api?server=$server&type=$type&id=$id';
  }
}
