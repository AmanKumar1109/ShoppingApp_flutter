import '../models/product_model.dart';

class SmartSearchEngine {
  // Typo mapping dictionary
  static const Map<String, String> _typoMap = {
    'tamato': 'tomato',
    'tomoto': 'tomato',
    'tamatar': 'tomato',
    'alu': 'potato',
    'aloo': 'potato',
    'potata': 'potato',
    'shugar': 'sugar',
    'cheeni': 'sugar',
    'chawal': 'rice',
    'doodh': 'milk',
    'dukh': 'milk',
    'chai': 'tea',
    'pyaaz': 'onion',
    'pyaz': 'onion',
    'mirchi': 'chilli',
    'mirch': 'chilli',
    'masala': 'spice',
    'tel': 'oil',
    'paneer': 'cottage cheese',
    'atta': 'flour',
    'aata': 'flour',
    'biskut': 'biscuit',
    'nimbu': 'lemon',
    'sruf': 'surf',
    'cadburbrowney': 'brownie',
    'cadburybrownie': 'brownie',
    'dairymilk': 'dairy milk',
  };

  // Hindi and English Synonym Map
  static const Map<String, List<String>> _synonymMap = {
    'tomato': ['tamatar', 'veg', 'vegetable', 'red'],
    'potato': ['alu', 'aloo', 'batata', 'vegetable'],
    'onion': ['pyaz', 'pyaaz', 'kanda', 'vegetable'],
    'milk': ['doodh', 'dairy', 'cow', 'amul', 'curd', 'paneer', 'butter'],
    'rice': ['chawal', 'basmati', 'grain', 'atta'],
    'tea': ['chai', 'tea leaves', 'beverage'],
    'flour': ['atta', 'aata', 'wheat', 'grain', 'maida'],
    'oil': ['tel', 'mustard', 'refined', 'ghee'],
    'banana': ['kela', 'fruit', 'organic'],
    'apple': ['seb', 'fruit', 'fresh'],
    'mango': ['aam', 'fruit', 'alphonso'],
    'biscuit': ['cookie', 'bakery', 'snack', 'cookies'],
    'bread': ['pav', 'bakery', 'brown bread', 'white bread', 'loaf'],
    'surf': ['surf', 'surf excel', 'detergent', 'washing', 'washing powder', 'liquid detergent', 'cleaning', 'laundry', 'matic'],
    'detergent': ['surf', 'surf excel', 'ariel', 'washing', 'cleaning', 'powder', 'liquid', 'laundry', 'matic'],
    'brownie': ['brownie', 'cadbury', 'chocolate', 'cake', 'fudge', 'pastry', 'bakery', 'sweets'],
    'cadbury': ['cadbury', 'dairy milk', 'silk', 'brownie', 'chocolate', 'sweets', 'cake'],
    'silk': ['dairy milk', 'silk', 'cadbury', 'chocolate'],
    'dairy milk': ['dairy milk', 'silk', 'cadbury', 'chocolate', 'sweets'],
    'chocolate': ['chocolate', 'cadbury', 'silk', 'brownie', 'choco', 'kitkat', 'fudge', 'sweets'],
    'dairy': ['dairy', 'milk', 'doodh', 'paneer', 'butter', 'amul', 'cheese', 'curd', 'ghee'],
  };

  // Preprocesses query to correct typos and expand synonyms
  static String sanitizeQuery(String query) {
    final lower = query.trim().toLowerCase();
    return _typoMap[lower] ?? lower;
  }

  // Smart fuzzy search matching title, category, subcategory, and tags
  static List<ProductModel> search(List<ProductModel> products, String query) {
    if (query.trim().isEmpty) return products;

    final sanitized = sanitizeQuery(query);
    final tokens = sanitized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return products.where((product) {
      final title = product.title.toLowerCase();
      final category = product.category.toLowerCase();
      final subcategory = product.subcategory.toLowerCase();
      final tags = product.tags.map((t) => t.toLowerCase()).join(' ');

      // Check if direct token match
      bool allTokensMatch = tokens.every((token) {
        if (title.contains(token) ||
            category.contains(token) ||
            subcategory.contains(token) ||
            tags.contains(token)) {
          return true;
        }

        // Check synonyms
        for (final entry in _synonymMap.entries) {
          if (token.contains(entry.key) || entry.key.contains(token)) {
            if (entry.value.any((syn) =>
                title.contains(syn) ||
                category.contains(syn) ||
                subcategory.contains(syn) ||
                tags.contains(syn))) {
              return true;
            }
          }
        }

        return false;
      });

      return allTokensMatch;
    }).toList();
  }
}
