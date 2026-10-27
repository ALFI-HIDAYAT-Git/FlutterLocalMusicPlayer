import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/music_provider.dart';
import 'screens/main_screen.dart';
import 'services/audio_player_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final handler = await AudioService.init<AudioPlayerHandler>(
      builder: AudioPlayerHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_application.audio',
        androidNotificationChannelName: 'Pemutaran musik',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    await handler.configureAudioSession();
    final provider = MusicProvider(handler);
    await provider.initialize();
    runApp(MusicApplication(provider: provider));
  } catch (error) {
    runApp(StartupErrorApp(message: 'Aplikasi gagal dimulai: $error'));
  }
}

class MusicApplication extends StatelessWidget {
  const MusicApplication({required this.provider, super.key});

  final MusicProvider provider;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      title: 'Nada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8BE9B0),
          brightness: Brightness.dark,
          surface: const Color(0xFF101512),
        ),
        scaffoldBackgroundColor: const Color(0xFF101512),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101512),
          foregroundColor: Color(0xFFF2F6F3),
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF171E1A),
          indicatorColor: const Color(0xFF284C38),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A211D),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const MainScreen(),
    ),
  );
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}
