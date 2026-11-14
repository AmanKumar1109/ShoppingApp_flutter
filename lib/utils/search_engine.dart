import '../models/product_model.dart';

class SearchSuggestion {
  final String text;
  final String? category;
  final bool isProduct;

  const SearchSuggestion({
    required this.text,
    this.category,
    this.isProduct = false,
  });
}

class SmartSearchEngine {
  // Common typo corrections
  static const Map<String, String> _typoMap = {
    'tamato': 'tomato',
    'tomoto': 'tomato',
    'tamatar': 'tomato',
    'alu': 'potato',
    'aloo': 'potato',
    'potata': 'potato',
    'shugar': 'sugar',
    'cheeni': 'sugar',
    'chini': 'sugar',
    'chawal': 'rice',
    'chaawal': 'rice',
    'doodh': 'milk',
    'dudh': 'milk',
    'chai': 'tea',
    'chay': 'tea',
    'pyaaz': 'onion',
    'pyaz': 'onion',
    'kanda': 'onion',
    'mirchi': 'chilli',
    'mirch': 'chilli',
    'masala': 'spice',
    'tel': 'oil',
    'paneer': 'paneer',
    'panir': 'paneer',
    'atta': 'atta',
    'aata': 'atta',
    'biskut': 'biscuit',
    'biskit': 'biscuit',
    'nimbu': 'lemon',
    'sruf': 'surf',
    'srufexcel': 'surf excel',
    'surfexcel': 'surf excel',
    'dairymilk': 'dairy milk',
    'cadbary': 'cadbury',
    'cadburybrownie': 'brownie',
    'makhan': 'butter',
    'makhhan': 'butter',
  };

  // Precise, targeted synonym dictionary (Hindi <-> English & Brand Aliases)
  static const Map<String, List<String>> _synonymMap = {
    'rice': ['chawal', 'basmati', 'kolam', 'biryani'],
    'chawal': ['rice', 'basmati', 'kolam'],
    'basmati': ['rice', 'chawal'],
    'atta': ['flour', 'wheat', 'gehu', 'aata', 'chakki'],
    'flour': ['atta', 'aata', 'wheat', 'maida'],
    'wheat': ['atta', 'gehu', 'flour'],
    'milk': ['doodh', 'dairy', 'amul', 'toned', 'taaza'],
    'doodh': ['milk', 'dairy', 'amul'],
    'tomato': ['tamatar'],
    'tamatar': ['tomato'],
    'potato': ['aloo', 'alu', 'batata'],
    'aloo': ['potato', 'alu'],
    'alu': ['potato', 'aloo'],
    'onion': ['pyaz', 'pyaaz', 'kanda'],
    'pyaz': ['onion', 'pyaaz', 'kanda'],
    'pyaaz': ['onion', 'pyaz', 'kanda'],
    'oil': ['tel', 'mustard', 'refined', 'ghee', 'cooking oil'],
    'tel': ['oil', 'mustard', 'ghee', 'refined'],
    'ghee': ['desi ghee', 'oil', 'cow ghee'],
    'sugar': ['cheeni', 'chini', 'shakkar'],
    'cheeni': ['sugar', 'chini'],
    'tea': ['chai', 'tea leaves', 'tata tea'],
    'chai': ['tea', 'tea leaves'],
    'biscuit': ['biscuits', 'cookie', 'cookies', 'biskut'],
    'surf': ['surf excel', 'detergent', 'ariel', 'washing powder', 'liquid detergent'],
    'detergent': ['surf', 'surf excel', 'ariel', 'washing powder', 'powder', 'cleaner'],
    'soap': ['sabun', 'bath soap', 'body wash'],
    'chocolate': ['cadbury', 'silk', 'dairy milk', 'choco', 'kitkat'],
    'cadbury': ['chocolate', 'silk', 'dairy milk'],
    'silk': ['chocolate', 'cadbury', 'dairy milk'],
    'brownie': ['brownie', 'cake', 'fudge'],
    'paneer': ['cottage cheese', 'malai paneer'],
    'butter': ['makhan', 'pasteurised butter', 'amul'],
    'egg': ['eggs', 'anda'],
    'bread': ['pav', 'loaf', 'garlic bread', 'toast'],
    'banana': ['kela'],
    'apple': ['seb'],
    'mango': ['aam'],
    'chilli': ['mirch', 'mirchi', 'green chilli'],
    'turmeric': ['haldi'],
    'salt': ['namak'],
    'coriander': ['dhaniya'],
    'ginger': ['adrak'],
    'garlic': ['lahsun', 'lehsun'],
    'spinach': ['palak'],
    'dal': ['daal', 'toor', 'moong', 'chana', 'urad', 'pulse'],
    'daal': ['dal', 'toor', 'moong', 'chana', 'pulse'],
    'baby': ['diaper', 'pampers', 'wipes', 'cerelac', 'himalaya', 'johnson'],
    'diaper': ['diapers', 'pampers', 'pants', 'baby'],
    'wipes': ['baby wipes', 'wet wipes', 'himalaya'],
  };

  /// Sanitizes raw input with typo correction
  static String sanitizeQuery(String query) {
    final lower = query.trim().toLowerCase();
    return _typoMap[lower] ?? lower;
  }

  /// High-precision search with relevance scoring
  static List<ProductModel> search(List<ProductModel> products, String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final sanitized = sanitizeQuery(cleanQuery);
    final tokens = sanitized
        .split(RegExp(r'[\s,\-_]+'))
        .where((t) => t.trim().isNotEmpty)
        .toList();

    if (tokens.isEmpty) return [];

    final List<_ProductScore> scoredList = [];

    for (final product in products) {
      final title = product.title.toLowerCase();
      final category = product.category.toLowerCase();
      final subcategory = product.subcategory.toLowerCase();
      final tags = product.tags.map((t) => t.toLowerCase()).toList();
      final desc = product.description.toLowerCase();

      int score = 0;

      // 1. Exact full query matching
      if (title == cleanQuery || title == sanitized) {
        score += 1200;
      } else if (title.startsWith(cleanQuery) || title.startsWith(sanitized)) {
        score += 650;
      } else if (_containsWord(title, cleanQuery) || _containsWord(title, sanitized)) {
        score += 480;
      } else if (title.contains(cleanQuery) || title.contains(sanitized)) {
        score += 320;
      }

      // 2. Token Matching
      for (final token in tokens) {
        if (token.length == 1 && !RegExp(r'[a-zA-Z0-9]').hasMatch(token)) continue;

        // Title matches
        if (_containsWord(title, token)) {
          score += 220;
        } else if (title.startsWith(token)) {
          score += 140;
        } else if (title.contains(token)) {
          score += 90;
        }

        // Subcategory matches
        if (_containsWord(subcategory, token)) {
          score += 110;
        } else if (subcategory.contains(token)) {
          score += 60;
        }

        // Tag matches
        for (final tag in tags) {
          if (tag == token) {
            score += 90;
          } else if (_containsWord(tag, token)) {
            score += 50;
          }
        }

        // Category matches (requires at least 3 characters)
        if (token.length >= 3 && _containsWord(category, token)) {
          score += 40;
        }

        // Description matches
        if (token.length >= 3 && _containsWord(desc, token)) {
          score += 20;
        }

        // Synonym matches (Strict 1-to-1)
        final synonyms = _synonymMap[token] ?? [];
        for (final syn in synonyms) {
          if (_containsWord(title, syn)) {
            score += 260;
          } else if (title.contains(syn)) {
            score += 150;
          } else if (tags.contains(syn)) {
            score += 70;
          } else if (_containsWord(subcategory, syn)) {
            score += 60;
          }
        }
      }

      // Minimum score threshold: Must have genuine relevance
      if (score >= 50) {
        scoredList.add(_ProductScore(product: product, score: score));
      }
    }

    // Sort by relevance score descending
    scoredList.sort((a, b) {
      final scoreComp = b.score.compareTo(a.score);
      if (scoreComp != 0) return scoreComp;
      return b.product.rating.compareTo(a.product.rating);
    });

    return scoredList.map((s) => s.product).toList();
  }

  /// Helper to check whole-word containment
  static bool _containsWord(String source, String word) {
    if (word.isEmpty) return false;
    final pattern = RegExp(r'(^|\W)' + RegExp.escape(word) + r'($|\W)');
    return pattern.hasMatch(source);
  }

  /// Returns quick matching suggestions for autocomplete
  static List<SearchSuggestion> getSuggestions(
    List<ProductModel> products,
    String query, {
    int limit = 6,
  }) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final sanitized = sanitizeQuery(clean);
    final Set<String> addedTexts = {};
    final List<SearchSuggestion> suggestions = [];

    // 1. Direct Product Title matches
    for (final p in products) {
      final titleLower = p.title.toLowerCase();
      if (titleLower.contains(clean) || titleLower.contains(sanitized)) {
        if (addedTexts.add(p.title)) {
          suggestions.add(
            SearchSuggestion(
              text: p.title,
              category: p.category,
              isProduct: true,
            ),
          );
        }
      }
      if (suggestions.length >= limit) return suggestions;
    }

    // 2. Subcategory & Brand matches
    for (final p in products) {
      final subLower = p.subcategory.toLowerCase();
      if (subLower.contains(clean) || subLower.contains(sanitized)) {
        if (p.subcategory.trim().isNotEmpty && addedTexts.add(p.subcategory)) {
          suggestions.add(
            SearchSuggestion(
              text: p.subcategory,
              category: p.category,
              isProduct: false,
            ),
          );
        }
      }
      if (suggestions.length >= limit) return suggestions;
    }

    return suggestions;
  }
}

class _ProductScore {
  final ProductModel product;
  final int score;

  _ProductScore({required this.product, required this.score});
}
