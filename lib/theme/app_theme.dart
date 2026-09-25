import 'package:flutter/material.dart';
import '../utils/festival_date_helper.dart';
import 'festival_themes/christmas_theme.dart';
import 'festival_themes/default_theme.dart';
import 'festival_themes/diwali_theme.dart';
import 'festival_themes/durga_puja_theme.dart';
import 'festival_themes/holi_theme.dart';

class AppTheme {
  static ThemeData getTheme(FestivalType type) {
    switch (type) {
      case FestivalType.diwali:
        return diwaliTheme;
      case FestivalType.holi:
        return holiTheme;
      case FestivalType.durgaPuja:
        return durgaPujaTheme;
      case FestivalType.christmas:
        return christmasTheme;
      case FestivalType.defaultTheme:
        return defaultGroceryTheme;
    }
  }
}
