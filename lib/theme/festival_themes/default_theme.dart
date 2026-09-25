import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_colors.dart';

ThemeData get defaultGroceryTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: ThemeColors.defaultPrimary,
    scaffoldBackgroundColor: Colors.white, // Pure White App Background
    colorScheme: ColorScheme.fromSeed(
      seedColor: ThemeColors.defaultPrimary,
      primary: ThemeColors.defaultPrimary,
      secondary: ThemeColors.defaultAccent,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
