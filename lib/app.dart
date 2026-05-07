import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Music Flutter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      builder: (context, child) {
        // Dynamically update status bar based on current theme
        final brightness = MediaQuery.platformBrightnessOf(context);
        final isDark = brightness == Brightness.dark;

        final overlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark ? const Color(0xFF121212) : Colors.white,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        );

        SystemChrome.setSystemUIOverlayStyle(overlayStyle);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: child!,
        );
      },
    );
  }
}
