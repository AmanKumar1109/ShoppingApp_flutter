import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_colors.dart';

ThemeData get durgaPujaTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: ThemeColors.durgaPrimary,
    scaffoldBackgroundColor: const Color(0xFFFEF2F2),
    colorScheme: ColorScheme.fromSeed(
      seedColor: ThemeColors.durgaPrimary,
      primary: ThemeColors.durgaPrimary,
      secondary: ThemeColors.durgaAccent,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
  );
}
