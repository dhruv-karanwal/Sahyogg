import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'package:user_gdg/flood_map_screen.dart';
import 'package:user_gdg/sos_screen.dart';
import 'package:user_gdg/advisory_screen.dart';
import 'package:user_gdg/safe_zone_screen.dart';
import 'package:user_gdg/screens/registration_screen.dart';
import 'package:user_gdg/services/sms_receiver_service.dart';
import 'package:user_gdg/scenario_selection_screen.dart';
import 'package:user_gdg/seed_safe_zones.dart'; // IMPORT

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  
  await UserSMSReceiverService.startListening();
  
  final prefs = await SharedPreferences.getInstance();
  final bool isRegistered = prefs.getBool('isRegistered') ?? false;

  runApp(FloodCitizenApp(isRegistered: isRegistered));
  // Seed Cyclone Amphan Safe Zones (idempotent, can run once or more)
  await seedCycloneSafeZones();

  runApp(const FloodCitizenApp());
}

class FloodCitizenApp extends StatelessWidget {
  final bool isRegistered;
  const FloodCitizenApp({super.key, required this.isRegistered});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flood Safety Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      initialRoute: isRegistered ? '/home' : '/register',
      routes: {
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const FloodMapScreen(),
        '/advisory': (context) => const AdvisoryScreen(),
        '/': (context) => const ScenarioSelectionScreen(),
        '/flood_map': (context) => const FloodMapScreen(),
        // '/sos': (context) => const SOSScreen(),
        // '/advisory': (context) => const AdvisoryScreen(), // removed because it requires scenarioId
        // '/safezones': (context) => const SafeZoneScreen(),
      },
    );
  }
}
