import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailylogr/screens/home_screen.dart';
// import 'models/journal_entry.dart';
import 'services/hive_service.dart';

void main() async {
  // Hive initialization
  WidgetsFlutterBinding.ensureInitialized();
  // await Hive.initFlutter();
  // // Register Hive Adapters (for custom types)
  // Hive.registerAdapter(JournalEntryAdapter());
  // await Hive.openBox<JournalEntry>('journal_entries');

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
      home: const HomeScreen(),
    );
  }
}
