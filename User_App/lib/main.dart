import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'package:user_gdg/screens/registration_screen.dart';
import 'package:user_gdg/screens/login_screen.dart';
import 'package:user_gdg/screens/scenario_selection_screen.dart';
import 'package:user_gdg/services/sms_receiver_service.dart';
import 'package:provider/provider.dart';
import 'package:user_gdg/providers/locale_provider.dart';

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
}

class FloodCitizenApp extends StatelessWidget {
  final bool isRegistered;
  const FloodCitizenApp({super.key, required this.isRegistered});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: MaterialApp(
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
        initialRoute: isRegistered ? '/scenario' : '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/scenario': (context) => const ScenarioSelectionScreen(),
        },
      ),
    );
  }
}
