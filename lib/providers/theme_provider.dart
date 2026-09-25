import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../utils/festival_date_helper.dart';

final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) {
  return ThemeProvider();
});

class ThemeProvider extends ChangeNotifier {
  FestivalType _currentThemeType = FestivalType.defaultTheme;

  FestivalType get currentThemeType => _currentThemeType;

  ThemeProvider() {
    // Auto detect festival theme if any, or default
    _currentThemeType = FestivalDateHelper.getCurrentFestival();
  }

  void setTheme(FestivalType type) {
    _currentThemeType = type;
    notifyListeners();
  }
}
