import 'dart:ui';

enum StartOfWeek {
  monday,
  sunday;

  Locale get datePickerLocale {
    switch (this) {
      case StartOfWeek.monday:
        return const Locale('es');
      case StartOfWeek.sunday:
        return const Locale('en');
    }
  }
}
