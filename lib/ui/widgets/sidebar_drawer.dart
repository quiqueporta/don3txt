import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/application/task_view.dart';
import 'package:don3txt/application/todo_list_notifier.dart';
import 'package:don3txt/application/settings_notifier.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';
import 'package:don3txt/ui/screens/settings_screen.dart';
import 'package:don3txt/ui/screens/debug_screen.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TodoListNotifier>();
    final settings = context.watch<SettingsNotifier>();
    final loc = AppLocalizations.of(context);
    final pastCount = notifier.pastTaskCount;
    final todayCount = notifier.todayTaskCount;
    final upcomingCount = notifier.upcomingTaskCount;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  children: const [
                    TextSpan(text: 'don'),
                    TextSpan(
                      text: '3',
                      style: TextStyle(color: Color(0xFFF5A623)),
                    ),
                    TextSpan(text: 'txt'),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.inbox, color: Colors.blue),
            title: Text(loc.inbox),
            selected: notifier.isShowing(const InboxView()),
            onTap: () {
              notifier.showView(const InboxView());
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.red),
            title: Text(loc.past),
            trailing: pastCount > 0
                ? Badge(
                    backgroundColor: Colors.red,
                    label: Text('$pastCount'),
                  )
                : null,
            selected: notifier.isShowing(const PastView()),
            onTap: () {
              notifier.showView(const PastView());
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.today, color: Colors.amber),
            title: Text(loc.today),
            trailing: todayCount > 0
                ? Badge(
                    backgroundColor: Colors.grey,
                    label: Text('$todayCount'),
                  )
                : null,
            selected: notifier.isShowing(const TodayView()),
            onTap: () {
              notifier.showView(const TodayView());
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.orange),
            title: Text(loc.upcomingWithDays(settings.upcomingDays)),
            trailing: upcomingCount > 0
                ? Badge(
                    backgroundColor: Colors.grey,
                    label: Text('$upcomingCount'),
                  )
                : null,
            selected: notifier.isShowing(const UpcomingView()),
            onTap: () {
              notifier.showView(const UpcomingView());
              Navigator.of(context).pop();
            },
          ),
          if (notifier.allProjects.isNotEmpty)
            ExpansionTile(
              leading: Icon(Icons.tag, color: Colors.teal.shade400),
              title: Text(
                loc.myProjects,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              initiallyExpanded: false,
              children: [
                for (final project in notifier.allProjects)
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 56),
                    title: Text(project.replaceFirst('+', '')),
                    selected: notifier.isShowing(ProjectView(project)),
                    onTap: () {
                      notifier.showView(ProjectView(project));
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          if (notifier.allContexts.isNotEmpty)
            ExpansionTile(
              leading: Icon(Icons.alternate_email,
                  color: Colors.deepPurple.shade400),
              title: Text(
                loc.myContexts,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              initiallyExpanded: false,
              children: [
                for (final ctx in notifier.allContexts)
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 56),
                    title: Text(ctx.replaceFirst('@', '')),
                    selected: notifier.isShowing(ContextView(ctx)),
                    onTap: () {
                      notifier.showView(ContextView(ctx));
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          if (notifier.allTags.isNotEmpty)
            ExpansionTile(
              leading: Icon(Icons.label_outline, color: Colors.orange.shade400),
              title: Text(
                loc.myTags,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              initiallyExpanded: false,
              children: [
                for (final tag in notifier.allTags)
                  ListTile(
                    contentPadding:
                        EdgeInsets.only(left: tag.value == null ? 56 : 72),
                    title: Text(tag.value ?? tag.key),
                    selected: notifier.isShowing(TagView(tag)),
                    onTap: () {
                      notifier.showView(TagView(tag));
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          if (notifier.hasRecurringTasks || notifier.hasCompletedTasks) ...[
            if (notifier.allProjects.isEmpty && notifier.allContexts.isEmpty)
              const Divider(),
            if (notifier.hasRecurringTasks)
              ListTile(
                leading: Icon(Icons.repeat, color: Colors.green.shade400),
                title: Text(loc.recurring),
                selected: notifier.isShowing(const RecurringView()),
                onTap: () {
                  notifier.showView(const RecurringView());
                  Navigator.of(context).pop();
                },
              ),
            if (notifier.hasCompletedTasks)
              ListTile(
                leading: Icon(Icons.check_circle_outline,
                    color: Colors.grey.shade500),
                title: Text(loc.completed),
                selected: notifier.isShowing(const CompletedView()),
                onTap: () {
                  notifier.showView(const CompletedView());
                  Navigator.of(context).pop();
                },
              ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(loc.settings),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: Text(loc.debug),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DebugScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(loc.about),
            onTap: () {
              Navigator.of(context).pop();

              showAboutDialog(
                context: context,
                applicationName: 'don3txt',
                applicationVersion: '1.14.0',
                children: [
                  Text(loc.aboutAuthor),
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
                  Text(loc.aboutLicense),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
