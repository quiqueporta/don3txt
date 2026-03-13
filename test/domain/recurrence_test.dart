import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/recurrence.dart';

void main() {
  group('parseRecurrence', () {
    test('parses days', () {
      final rec = parseRecurrence('3d');

      expect(rec, isNotNull);
      expect(rec!.amount, 3);
      expect(rec.unit, RecurrenceUnit.day);
      expect(rec.isStrict, false);
    });

    test('parses weeks', () {
      final rec = parseRecurrence('2w');

      expect(rec, isNotNull);
      expect(rec!.amount, 2);
      expect(rec.unit, RecurrenceUnit.week);
    });

    test('parses months', () {
      final rec = parseRecurrence('1m');

      expect(rec, isNotNull);
      expect(rec!.amount, 1);
      expect(rec.unit, RecurrenceUnit.month);
    });

    test('parses years', () {
      final rec = parseRecurrence('1y');

      expect(rec, isNotNull);
      expect(rec!.amount, 1);
      expect(rec.unit, RecurrenceUnit.year);
    });

    test('parses strict recurrence with + prefix', () {
      final rec = parseRecurrence('+2w');

      expect(rec, isNotNull);
      expect(rec!.amount, 2);
      expect(rec.unit, RecurrenceUnit.week);
      expect(rec.isStrict, true);
    });

    test('returns null for invalid input', () {
      expect(parseRecurrence('abc'), isNull);
      expect(parseRecurrence(''), isNull);
      expect(parseRecurrence('3x'), isNull);
    });
  });

  group('Recurrence.applyTo', () {
    test('adds days', () {
      final rec = Recurrence(amount: 3, unit: RecurrenceUnit.day);
      final result = rec.applyTo(DateTime(2026, 3, 10));

      expect(result, DateTime(2026, 3, 13));
    });

    test('adds weeks', () {
      final rec = Recurrence(amount: 2, unit: RecurrenceUnit.week);
      final result = rec.applyTo(DateTime(2026, 3, 10));

      expect(result, DateTime(2026, 3, 24));
    });

    test('adds months', () {
      final rec = Recurrence(amount: 3, unit: RecurrenceUnit.month);
      final result = rec.applyTo(DateTime(2026, 3, 15));

      expect(result, DateTime(2026, 6, 15));
    });

    test('adds years', () {
      final rec = Recurrence(amount: 1, unit: RecurrenceUnit.year);
      final result = rec.applyTo(DateTime(2026, 3, 15));

      expect(result, DateTime(2027, 3, 15));
    });

    test('handles month overflow', () {
      final rec = Recurrence(amount: 1, unit: RecurrenceUnit.month);
      final result = rec.applyTo(DateTime(2026, 1, 31));

      expect(result, DateTime(2026, 2, 28));
    });
  });
}
