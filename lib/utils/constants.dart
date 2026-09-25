import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'GroceryHub';
  static const String currencySymbol = '₹';

  // Yellow accents & pure white scaffold background
  static const Color primaryYellow = Color(0xFFF7C415); // Vibrant Yellow
  static const Color accentYellow = Color(0xFFFEF08A); // Soft Light Yellow
  static const Color lightHeaderBg = Color(
    0xFFFFF4B8,
  ); // Top Soft Yellow Header
  static const Color bannerBg = Color(0xFFFFF4B8);
  static const Color scaffoldBg = Colors.white; // Pure White App Background
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF19251B);
  static const Color textMuted = Color(0xFF758578);

  // Collections
  static const String userCol = 'users';
  static const String productCol = 'products';
  static const String categoryCol = 'categories';
  static const String orderCol = 'orders';
}
