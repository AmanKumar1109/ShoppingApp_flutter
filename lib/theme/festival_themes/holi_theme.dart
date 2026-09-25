import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_colors.dart';

ThemeData get holiTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: ThemeColors.holiPrimary,
    scaffoldBackgroundColor: const Color(0xFFFDF2F8),
    colorScheme: ColorScheme.fromSeed(
      seedColor: ThemeColors.holiPrimary,
      primary: ThemeColors.holiPrimary,
      secondary: ThemeColors.holiAccent,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
  );
}
