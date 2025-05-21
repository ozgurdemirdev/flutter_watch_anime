import 'package:flutter/material.dart';
import 'screens/video_player_screen.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    // Sadece pencereyi göster, fullScreen başlatma!
    WindowOptions windowOptions = const WindowOptions(
        // fullScreen: true, // Bunu kaldırıyoruz!
        // Diğer pencere ayarlarını burada tutabilirsiniz.
        );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: VideoPlayerScreen(),
    );
  }
}
