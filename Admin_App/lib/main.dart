import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/ssh_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/lg_controller.dart';
import 'screens/scenario_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final settingsController = SettingsController();
  await settingsController.loadSettings();
  
  final sshController = SSHController();
  final lgController = LGController(
    sshController: sshController,
    settingsController: settingsController,
  );
  
  runApp(
    ProviderScope(
      child: MyApp(
        sshController: sshController,
        settingsController: settingsController,
        lgController: lgController,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final SSHController sshController;
  final SettingsController settingsController;
  final LGController lgController;

  const MyApp({
    super.key,
    required this.sshController,
    required this.settingsController,
    required this.lgController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LG Controller',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      home: ScenarioSelectionScreen(
        sshController: sshController,
        settingsController: settingsController,
        lgController: lgController,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final seed = Colors.tealAccent;
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF121826),
      background: const Color(0xFF0B111B),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B111B),
      canvasColor: const Color(0xFF0B111B),
      cardColor: const Color(0xFF141A26),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey.shade900,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogBackgroundColor: const Color(0xFF141A26),
    );
  }
}
