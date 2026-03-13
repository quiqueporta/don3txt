import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/ui/screens/settings_screen.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TodoListNotifier>();
    final todayOnlyCount = notifier.todayOnlyTaskCount;
    final overdueCount = notifier.overdueTaskCount;
    final hasBadges = todayOnlyCount > 0 || overdueCount > 0;

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
            trailing: hasBadges
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (overdueCount > 0)
                        Badge(
                          backgroundColor: Colors.red,
                          label: Text('$overdueCount'),
                        ),
                      if (overdueCount > 0 && todayOnlyCount > 0)
                        const SizedBox(width: 6),
                      if (todayOnlyCount > 0)
                        Badge(
                          backgroundColor: Colors.grey,
                          label: Text('$todayOnlyCount'),
                        ),
                    ],
                  )
                : null,
            selected: notifier.activeFilter == TaskFilter.today,
            onTap: () {
              notifier.activeFilter = TaskFilter.today;
              Navigator.of(context).pop();
            },
          ),
          if (notifier.allProjects.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text(
                'My Projects',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            for (final project in notifier.allProjects)
              ListTile(
                leading: Icon(Icons.tag, color: Colors.teal.shade400),
                title: Text(project.replaceFirst('+', '')),
                selected: notifier.activeFilter == TaskFilter.project &&
                    notifier.selectedProject == project,
                onTap: () {
                  notifier.selectProject(project);
                  Navigator.of(context).pop();
                },
              ),
          ],
          if (notifier.allContexts.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text(
                'My Contexts',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            for (final ctx in notifier.allContexts)
              ListTile(
                leading:
                    Icon(Icons.alternate_email, color: Colors.deepPurple.shade400),
                title: Text(ctx.replaceFirst('@', '')),
                selected: notifier.activeFilter == TaskFilter.context &&
                    notifier.selectedContext == ctx,
                onTap: () {
                  notifier.selectContext(ctx);
                  Navigator.of(context).pop();
                },
              ),
          ],
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
