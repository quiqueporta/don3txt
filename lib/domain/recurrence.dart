enum RecurrenceUnit { day, week, month, year }

class Recurrence {
  final int amount;
  final RecurrenceUnit unit;
  final bool isStrict;

  const Recurrence({
    required this.amount,
    required this.unit,
    this.isStrict = false,
  });

  DateTime applyTo(DateTime date) {
    switch (unit) {
      case RecurrenceUnit.day:
        return DateTime(date.year, date.month, date.day + amount);
      case RecurrenceUnit.week:
        return DateTime(date.year, date.month, date.day + amount * 7);
      case RecurrenceUnit.month:
        final targetMonth = DateTime(date.year, date.month + amount, 1);
        final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
        final day = date.day > lastDay ? lastDay : date.day;

        return DateTime(targetMonth.year, targetMonth.month, day);
      case RecurrenceUnit.year:
        final lastDay = DateTime(date.year + amount, date.month + 1, 0).day;
        final day = date.day > lastDay ? lastDay : date.day;

        return DateTime(date.year + amount, date.month, day);
    }
  }
}

final _recPattern = RegExp(r'^(\+)?(\d+)([dwmy])$');

Recurrence? parseRecurrence(String value) {
  final match = _recPattern.firstMatch(value);
  if (match == null) return null;

  final isStrict = match.group(1) == '+';
  final amount = int.parse(match.group(2)!);
  final unitChar = match.group(3)!;

  final unit = switch (unitChar) {
    'd' => RecurrenceUnit.day,
    'w' => RecurrenceUnit.week,
    'm' => RecurrenceUnit.month,
    'y' => RecurrenceUnit.year,
    _ => null,
  };

  if (unit == null) return null;

  return Recurrence(amount: amount, unit: unit, isStrict: isStrict);
}
