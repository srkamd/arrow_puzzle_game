import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } catch (_) {}

  final storage = GameStorage();
  try {
    await storage.load();
  } catch (_) {}

  final auth = AuthService();
  try {
    await auth.load();
  } catch (_) {}

  try {
    SoundService().init();
  } catch (_) {}

  runApp(ArrowPuzzleApp(storage: storage, auth: auth));
}

class ArrowPuzzleApp extends StatelessWidget {
  final GameStorage storage;
  final AuthService auth;

  const ArrowPuzzleApp({
    super.key,
    required this.storage,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow Puzzle Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        fontFamily: 'Roboto',
      ),
      home: HomeScreen(storage: storage, auth: auth),
    );
  }
}
