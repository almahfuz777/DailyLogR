import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/widgets/entry_editor.dart';
import 'package:dailylogr/widgets/entry_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,

      appBar: AppBar(
        title: Text('DailyLogR'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: color.primary,
        foregroundColor: color.onPrimary,
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: color.primary,
              ),
              child: Text(
                'DailyLogR',
                style: TextStyle(
                  color: color.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text("close"),
              onTap: () => Navigator.pop(context),  // closes the drawer
            ),

          ],
        ),
      ),

      // FAB to add new entry 
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await showModalBottomSheet<JournalEntry>(
            context: context,
            isScrollControlled: true, 
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: EntryEditor(),
              );
            } 
          );
          if(created != null) {
            await HiveService.addEntry(created);  // upsert by date
          }
        },
        backgroundColor: color.primary,
        foregroundColor: color.onPrimary,
        child: Icon(Icons.add),
      ),

      body: const EntryList(),  // list of entries
      
    );
  }
}



