import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/application/settings_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'First day of the week',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          RadioListTile<StartOfWeek>(
            title: const Text('Monday'),
            value: StartOfWeek.monday,
            groupValue: settings.startOfWeek,
            onChanged: (value) => settings.setStartOfWeek(value!),
          ),
          RadioListTile<StartOfWeek>(
            title: const Text('Sunday'),
            value: StartOfWeek.sunday,
            groupValue: settings.startOfWeek,
            onChanged: (value) => settings.setStartOfWeek(value!),
          ),
        ],
      ),
    );
  }
}
