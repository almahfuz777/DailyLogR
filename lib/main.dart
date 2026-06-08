import 'package:flutter/material.dart';
import 'package:dailylogr/screens/main_screen.dart';
import 'package:dailylogr/screens/onboarding_screen.dart';
import 'package:dailylogr/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/hive_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  // Firebase initialization
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Hive initialization
  await HiveService.init();

  // Notification initialization
  await NotificationService().init();

  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('show_onboarding') ?? true;

  // Run the app
  runApp(
    ProviderScope(
      child: MyApp(showOnboarding: showOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  
  const MyApp({super.key, required this.showOnboarding});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: showOnboarding ? const OnboardingScreen() : const MainScreen(),
    );
  }
}
