import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:music_flutter/app.dart';
import 'package:music_flutter/data/providers/player_provider.dart';
import 'package:music_flutter/data/providers/user_provider.dart';

void main() {
  testWidgets('Music app starts', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    await GetStorage.init();
    Get.put(PlayerProvider(), permanent: true);
    Get.put(UserProvider(), permanent: true);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MusicApp());

    // Skip splash animation (1500ms) and auth check delay (2000ms)
    await tester.pump(const Duration(seconds: 3));

    // Verify app starts
    expect(find.byType(GetMaterialApp), findsOneWidget);
  });
}
