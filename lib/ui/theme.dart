import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _accentBlue = Color(0xFF007AFF);

ThemeData buildLightTheme() {
  final textTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorSchemeSeed: _accentBlue,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _accentBlue,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
      elevation: 2,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: _accentBlue,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _accentBlue,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
      elevation: 2,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );
}
