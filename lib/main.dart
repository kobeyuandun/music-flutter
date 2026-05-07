import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app.dart';
import 'data/providers/player_provider.dart';
import 'data/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style for splash screen and initial launch
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize providers
  Get.put(PlayerProvider(), permanent: true);
  Get.put(UserProvider(), permanent: true);

  runApp(const MusicApp());
}
