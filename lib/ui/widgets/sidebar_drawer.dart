import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/ui/screens/settings_screen.dart';
import 'package:don3txt/ui/screens/debug_screen.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TodoListNotifier>();
    final settings = context.watch<SettingsNotifier>();
    final todayOnlyCount = notifier.todayOnlyTaskCount;
    final overdueCount = notifier.overdueTaskCount;
    final hasBadges = todayOnlyCount > 0 || overdueCount > 0;
    final upcomingCount = notifier.upcomingTaskCount;
    notifier.upcomingDays = settings.upcomingDays;

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
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.orange),
            title: const Text('Upcoming'),
            trailing: upcomingCount > 0
                ? Badge(
                    backgroundColor: Colors.grey,
                    label: Text('$upcomingCount'),
                  )
                : null,
            selected: notifier.activeFilter == TaskFilter.upcoming,
            onTap: () {
              notifier.activeFilter = TaskFilter.upcoming;
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
          if (notifier.hasRecurringTasks) ...[
            const Divider(),
            ListTile(
              leading: Icon(Icons.repeat, color: Colors.green.shade400),
              title: const Text('Recurring'),
              selected: notifier.activeFilter == TaskFilter.recurring,
              onTap: () {
                notifier.activeFilter = TaskFilter.recurring;
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
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Debug'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DebugScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.of(context).pop();

              showAboutDialog(
                context: context,
                applicationName: 'don3txt',
                applicationVersion: '1.1.0',
                children: [
                  const Text('Author: Quique Porta'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse('https://github.com/quiqueporta/don3txt'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text(
                      'https://github.com/quiqueporta/don3txt',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('License: MIT'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
