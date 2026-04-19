import 'dart:ui';

enum AppLanguage {
  system,
  spanish,
  english,
  french,
  italian,
  portuguese;

  Locale? get locale {
    switch (this) {
      case AppLanguage.system:
        return null;
      case AppLanguage.spanish:
        return const Locale('es');
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.french:
        return const Locale('fr');
      case AppLanguage.italian:
        return const Locale('it');
      case AppLanguage.portuguese:
        return const Locale('pt');
    }
  }

  static AppLanguage fromName(String? name) {
    return AppLanguage.values.firstWhere(
      (l) => l.name == name,
      orElse: () => AppLanguage.system,
    );
  }
}
