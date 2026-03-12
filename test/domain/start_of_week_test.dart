import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/start_of_week.dart';

void main() {
  group('StartOfWeek', () {
    test('monday maps to Spanish locale', () {
      expect(StartOfWeek.monday.datePickerLocale, const Locale('es'));
    });

    test('sunday maps to English locale', () {
      expect(StartOfWeek.sunday.datePickerLocale, const Locale('en'));
    });
  });
}
