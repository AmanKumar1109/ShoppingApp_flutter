enum FestivalType { defaultTheme, diwali, holi, durgaPuja, christmas }

class FestivalDateHelper {
  static FestivalType getCurrentFestival() {
    final now = DateTime.now();
    final month = now.month;
    final day = now.day;

    if (month == 12 && day >= 15 && day <= 30) {
      return FestivalType.christmas;
    } else if (month == 10 || month == 11) {
      return FestivalType.diwali;
    } else if (month == 3) {
      return FestivalType.holi;
    } else if (month == 9 || month == 10) {
      return FestivalType.durgaPuja;
    }
    return FestivalType.defaultTheme;
  }
}
