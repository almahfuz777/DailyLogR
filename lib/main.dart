import 'package:flutter/material.dart';
import 'package:dailylogr/screens/main_screen.dart';
import 'services/hive_service.dart';

void main() async {
  // Hive initialization
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MainScreen(),
    );
  }
}
