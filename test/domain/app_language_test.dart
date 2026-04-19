import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/app_language.dart';

void main() {
  group('AppLanguage', () {
    test('system has no locale', () {
      expect(AppLanguage.system.locale, isNull);
    });

    test('spanish maps to Locale("es")', () {
      expect(AppLanguage.spanish.locale, const Locale('es'));
    });

    test('english maps to Locale("en")', () {
      expect(AppLanguage.english.locale, const Locale('en'));
    });

    test('french maps to Locale("fr")', () {
      expect(AppLanguage.french.locale, const Locale('fr'));
    });

    test('italian maps to Locale("it")', () {
      expect(AppLanguage.italian.locale, const Locale('it'));
    });

    test('portuguese maps to Locale("pt")', () {
      expect(AppLanguage.portuguese.locale, const Locale('pt'));
    });

    test('fromName returns matching language', () {
      expect(AppLanguage.fromName('spanish'), AppLanguage.spanish);
      expect(AppLanguage.fromName('english'), AppLanguage.english);
      expect(AppLanguage.fromName('french'), AppLanguage.french);
      expect(AppLanguage.fromName('italian'), AppLanguage.italian);
      expect(AppLanguage.fromName('portuguese'), AppLanguage.portuguese);
      expect(AppLanguage.fromName('system'), AppLanguage.system);
    });

    test('fromName returns system for unknown or null', () {
      expect(AppLanguage.fromName(null), AppLanguage.system);
      expect(AppLanguage.fromName('klingon'), AppLanguage.system);
    });
  });
}
