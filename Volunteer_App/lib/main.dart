import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Theme
import 'theme/app_theme.dart';

// Services
import 'services/volunteer_repository.dart';
import 'services/location_service.dart';
import 'services/mission_service.dart';
import 'services/dispatch_service.dart';
import 'services/fatigue_service.dart';
import 'services/emergency_service.dart';
import 'services/resource_hub_service.dart';

// Screens
import 'screens/dashboard_screen.dart';
import 'screens/missions_screen.dart';
import 'screens/map_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/profile_screen.dart';

import 'screens/volunteer_registration_screen.dart';
import 'screens/volunteer_login_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const VolunteerApp());
}

class VolunteerApp extends StatelessWidget {
  const VolunteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final volunteerRepo = VolunteerRepository();

    return MultiProvider(
      providers: [
        Provider.value(value: volunteerRepo),
        Provider(create: (_) => LocationService()),
        Provider(create: (_) => MissionService()),
        Provider(create: (_) => DispatchService()),
        Provider(create: (_) => EmergencyService()),
        ProxyProvider<VolunteerRepository, FatigueService>(
          update: (BuildContext context, VolunteerRepository repo, FatigueService? previous) => 
              FatigueService(repo),
        ),
        Provider(create: (_) => ResourceHubService()),
        // Controller for bottom navigation to be accessible from children
        ChangeNotifierProvider(create: (_) => ValueNotifier<int>(0)),
      ],
      child: MaterialApp(
        title: 'Volunteer App',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const VolunteerLoginScreen(),
      ),
    );
  }
}

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}
