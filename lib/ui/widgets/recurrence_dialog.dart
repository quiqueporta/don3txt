import 'package:flutter/material.dart';
import 'package:don3txt/l10n/generated/app_localizations.dart';

Future<String?> showRecurrenceDialog(
  BuildContext context, {
  String? initial,
}) {
  int amount = 1;
  String unit = 'd';
  bool strict = false;

  if (initial != null) {
    strict = initial.startsWith('+');
    final body = strict ? initial.substring(1) : initial;

    if (body.length >= 2) {
      amount = int.tryParse(body.substring(0, body.length - 1)) ?? 1;
      unit = body[body.length - 1];
    }
  }

  final loc = AppLocalizations.of(context);

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(loc.recurrenceTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(loc.every),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    controller: TextEditingController(text: '$amount'),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0) {
                        amount = parsed;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: unit,
                  items: [
                    DropdownMenuItem(value: 'd', child: Text(loc.unitDays)),
                    DropdownMenuItem(value: 'w', child: Text(loc.unitWeeks)),
                    DropdownMenuItem(value: 'm', child: Text(loc.unitMonths)),
                    DropdownMenuItem(value: 'y', child: Text(loc.unitYears)),
                  ],
                  onChanged: (v) => setDialogState(() => unit = v!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: strict,
                  onChanged: (v) => setDialogState(() => strict = v!),
                ),
                Expanded(child: Text(loc.strictFromStart)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              final prefix = strict ? '+' : '';
              Navigator.pop(dialogContext, '$prefix$amount$unit');
            },
            child: Text(loc.ok),
          ),
        ],
      ),
    ),
  );
}
