class AppHelpers {
  static String formatPrice(double price, {String unit = ''}) {
    final priceStr = '\$${price.toStringAsFixed(2)}';
    if (unit.isNotEmpty) {
      return '$priceStr /$unit';
    }
    return priceStr;
  }
}
