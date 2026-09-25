import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_colors.dart';

ThemeData get christmasTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: ThemeColors.christmasPrimary,
    scaffoldBackgroundColor: const Color(0xFFF0FDF4),
    colorScheme: ColorScheme.fromSeed(
      seedColor: ThemeColors.christmasPrimary,
      primary: ThemeColors.christmasPrimary,
      secondary: ThemeColors.christmasAccent,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
  );
}
