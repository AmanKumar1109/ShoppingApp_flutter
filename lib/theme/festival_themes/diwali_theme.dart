import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_colors.dart';

ThemeData get diwaliTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: ThemeColors.diwaliPrimary,
    scaffoldBackgroundColor: const Color(0xFFFFFBEB),
    colorScheme: ColorScheme.fromSeed(
      seedColor: ThemeColors.diwaliPrimary,
      primary: ThemeColors.diwaliPrimary,
      secondary: ThemeColors.diwaliAccent,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
  );
}
