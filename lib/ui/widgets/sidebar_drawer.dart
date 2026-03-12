import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/ui/screens/settings_screen.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TodoListNotifier>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Text('don3txt', style: TextStyle(fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.inbox, color: Colors.blue),
            title: const Text('Inbox'),
            selected: notifier.activeFilter == TaskFilter.inbox,
            onTap: () {
              notifier.activeFilter = TaskFilter.inbox;
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.today, color: Colors.amber),
            title: const Text('Today'),
            selected: notifier.activeFilter == TaskFilter.today,
            onTap: () {
              notifier.activeFilter = TaskFilter.today;
              Navigator.of(context).pop();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
