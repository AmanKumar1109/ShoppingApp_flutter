import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/seed_data.dart';
import '../utils/search_engine.dart';

enum ProductSortOption { featured, priceLowToHigh, priceHighToLow, rating }

final groceryProvider = ChangeNotifierProvider<GroceryProvider>((ref) {
  return GroceryProvider();
});

class GroceryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<ProductModel> _products = [];
  List<CategoryModel> _rawCategories = [];
  List<CategoryModel> _categoriesList = [];

  String _selectedCategory = 'all';
  String _selectedSubcategory = '';
  String _searchQuery = '';
  ProductSortOption _sortBy = ProductSortOption.featured;
  final Map<String, int> _cartItems = {}; // productId -> quantity

  bool _isLoading = true;
  int _displayLimit = 10;
  bool _isLoadingMore = false;
  StreamSubscription<List<ProductModel>>? _productsSub;
  StreamSubscription<List<CategoryModel>>? _categoriesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _categoryCoversSub;
  StreamSubscription<List<Map<String, dynamic>>?>? _homeSectionsSub;
  StreamSubscription<Map<String, dynamic>>? _settingsSub;
  Map<String, Map<String, dynamic>> _categoryCoversMap = {};
  List<Map<String, dynamic>>? _homeSections;
  bool _isAppAcceptingOrders = true;
  String _appOrderPauseMessage =
      'Online ordering is temporarily paused on our app. You can still browse products & prices!';

  // App Version Control (Hardcoded vs Admin Enforced)
  static const String hardcodedAppVersion = '1.0.0';
  String _minAppVersion = '1.0.0';
  bool _isForceUpdateEnabled = true;
  String _appUpdateUrl = 'https://play.google.com/store/apps/details?id=com.thegroceryhub.app';
  String _appUpdateMessage =
      'A new and improved version of The Grocery Hub is available with exciting new deals and faster delivery. Please update to continue!';

  String get currentAppVersion => hardcodedAppVersion;
  String get minAppVersion => _minAppVersion;
  bool get isForceUpdateEnabled => _isForceUpdateEnabled;
  String get appUpdateUrl => _appUpdateUrl;
  String get appUpdateMessage => _appUpdateMessage;

  // Referral Campaign Dynamic Settings
  bool _referralCampaignActive = true;
  double _referralMinOrderValue = 299.0;
  double _referralCouponMinOrderValue = 100.0;
  int _referralCouponValidityDays = 30;
  double _referrerRewardAmount = 30.0;
  double _referredUserRewardAmount = 30.0;
  String _referralBannerTitle = 'Refer Friends, Earn Rewards!';
  String _referralBannerDescription =
      'Invite friends to The Grocery Hub! After their first order is delivered, BOTH of you earn exciting reward coupons!';

  bool get isReferralCampaignActive => _referralCampaignActive;
  double get referralMinOrderValue => _referralMinOrderValue;
  double get referralCouponMinOrderValue => _referralCouponMinOrderValue;
  int get referralCouponValidityDays => _referralCouponValidityDays;
  double get referrerRewardAmount => _referrerRewardAmount;
  double get referredUserRewardAmount => _referredUserRewardAmount;
  String get referralBannerTitle => _referralBannerTitle;
  String get referralBannerDescription => _referralBannerDescription;

  bool get isAppOutdated {
    if (!_isForceUpdateEnabled) return false;
    final targetMin = _minAppVersion.trim();
    if (targetMin.isEmpty) return false;
    return compareVersions(hardcodedAppVersion, targetMin) < 0;
  }

  static int compareVersions(String v1, String v2) {
    final clean1 = v1.split('+').first.trim();
    final clean2 = v2.split('+').first.trim();
    final parts1 = clean1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = clean2.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final num1 = i < parts1.length ? parts1[i] : 0;
      final num2 = i < parts2.length ? parts2[i] : 0;
      if (num1 < num2) return -1;
      if (num1 > num2) return 1;
    }
    return 0;
  }

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categoriesList;
  List<Map<String, dynamic>>? get homeSections => _homeSections;
  bool get isAppAcceptingOrders => _isAppAcceptingOrders;
  String get appOrderPauseMessage => _appOrderPauseMessage;
  String get orderPauseMessage => _appOrderPauseMessage;
  String get selectedCategory => _selectedCategory;
  String get selectedSubcategory => _selectedSubcategory;
  String get searchQuery => _searchQuery;
  ProductSortOption get sortBy => _sortBy;
  Map<String, int> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  int get displayLimit => _displayLimit;
  bool get isLoadingMore => _isLoadingMore;

  static const String _kCartPrefKey = 'cached_cart_items_v1';
  static const String _kCategoriesPrefKey = 'cached_categories_list_v2';
  static const String _kCategoryCoversPrefKey = 'cached_category_covers_v2';
  static const String _kHomeSectionsPrefKey = 'cached_home_sections_v1';

  GroceryProvider({bool autoSync = true, FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService() {
    _loadCartFromStorage();
    _loadCategoriesFromStorage();
    if (autoSync) {
      _initRealTimeSync();
    }
  }

  Future<void> _loadCategoriesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load cached covers map for zero-lag instant rendering
      final coversRaw = prefs.getString(_kCategoryCoversPrefKey);
      if (coversRaw != null && coversRaw.isNotEmpty) {
        final List<dynamic> decodedCovers = jsonDecode(coversRaw);
        final map = <String, Map<String, dynamic>>{};
        for (final item in decodedCovers) {
          if (item is Map<String, dynamic>) {
            final target = (item['targetKey'] ?? '').toString().trim().toLowerCase();
            if (target.isNotEmpty) map[target] = item;
            final docId = (item['id'] ?? '').toString().trim().toLowerCase();
            if (docId.isNotEmpty) map[docId] = item;
          }
        }
        _categoryCoversMap = map;
      }

      // 2. Load cached categories list with covers & badges
      final catsRaw = prefs.getString(_kCategoriesPrefKey);
      if (catsRaw != null && catsRaw.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(catsRaw);
        final List<CategoryModel> loadedCats = [];
        for (final item in decodedList) {
          if (item is Map<String, dynamic>) {
            final id = (item['id'] ?? item['name'] ?? '').toString();
            loadedCats.add(CategoryModel.fromMap(item, id));
          }
        }
        if (loadedCats.isNotEmpty) {
          _categoriesList = loadedCats;
          _isLoading = false;
          notifyListeners();
        }
      }

      // 3. Load cached home sections layout for zero-delay home feed
      final sectionsRaw = prefs.getString(_kHomeSectionsPrefKey);
      if (sectionsRaw != null && sectionsRaw.isNotEmpty) {
        final List<dynamic> decodedSecs = jsonDecode(sectionsRaw);
        _homeSections = decodedSecs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading categories cache from storage: $e');
    }
  }

  Future<void> _persistCategoriesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_categoryCoversMap.isNotEmpty) {
        final coversList = _categoryCoversMap.values.toList();
        await prefs.setString(_kCategoryCoversPrefKey, jsonEncode(coversList));
      }
      if (_categoriesList.isNotEmpty) {
        final catMaps = _categoriesList.map((c) => c.toMap()).toList();
        await prefs.setString(_kCategoriesPrefKey, jsonEncode(catMaps));
      }
    } catch (e) {
      debugPrint('Error persisting categories cache to storage: $e');
    }
  }

  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCartPrefKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        _cartItems.clear();
        decoded.forEach((key, val) {
          if (val is int && val > 0) {
            _cartItems[key] = val;
          }
        });
        _recalculateCoupon();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart from storage: $e');
    }
  }

  Future<void> _persistCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cartItems.isEmpty) {
        await prefs.remove(_kCartPrefKey);
      } else {
        await prefs.setString(_kCartPrefKey, jsonEncode(_cartItems));
      }
    } catch (e) {
      debugPrint('Error saving cart to storage: $e');
    }
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    _categoryCoversSub?.cancel();
    _homeSectionsSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }

  void _initRealTimeSync() {
    _isLoading = true;
    notifyListeners();

    // 1. Sync Categories from Firestore
    _categoriesSub = _firestoreService.streamCategories().listen((cats) {
      _rawCategories = cats;
      _recalculateCategoryAggregations();
      notifyListeners();
    });

    // 2. Sync Products from Firestore
    _productsSub = _firestoreService.streamProducts().listen((prods) {
      _products = prods;
      _recalculateCategoryAggregations();
      _isLoading = false;
      notifyListeners();
    });

    // 3. Sync Dynamic Category Covers & System Tiles from Firestore
    _categoryCoversSub = _firestoreService.streamCategoryCovers().listen((covers) {
      final map = <String, Map<String, dynamic>>{};
      for (final c in covers) {
        final target = (c['targetKey'] ?? '').toString().trim().toLowerCase();
        if (target.isNotEmpty) {
          map[target] = c;
        }
        final docId = (c['id'] ?? '').toString().trim().toLowerCase();
        if (docId.isNotEmpty) {
          map[docId] = c;
        }
        final title = (c['title'] ?? '').toString().trim().toLowerCase();
        if (title.isNotEmpty) {
          map[title] = c;
        }
      }
      _categoryCoversMap = map;
      _recalculateCategoryAggregations();
      notifyListeners();
    });

    // 4. Sync Dynamic Home Layout Sections from Firestore
    _homeSectionsSub = _firestoreService.streamHomeSections().listen((sections) async {
      _homeSections = sections;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        if (sections != null && sections.isNotEmpty) {
          await prefs.setString(_kHomeSectionsPrefKey, jsonEncode(sections));
        }
      } catch (_) {}
    });

    // 5. Sync Global Store & App Settings (Order Acceptance / Pause State)
    _settingsSub = _firestoreService.streamGlobalSettings().listen((settings) {
      if (settings.isNotEmpty) {
        final bool appFlag = settings['isAppAcceptingOrders'] as bool? ??
            settings['isAcceptingOrders'] as bool? ??
            true;
        _isAppAcceptingOrders = appFlag;

        final msg = (settings['appOrderPauseMessage'] as String?)?.trim().isNotEmpty == true
            ? settings['appOrderPauseMessage'] as String
            : (settings['orderPauseMessage'] as String?)?.trim().isNotEmpty == true
                ? settings['orderPauseMessage'] as String
                : null;
        if (msg != null) {
          _appOrderPauseMessage = msg.trim();
        }

        // Sync App Version & Force Update Config
        final minVer = (settings['minAppVersion'] as String?)?.trim();
        if (minVer != null && minVer.isNotEmpty) {
          _minAppVersion = minVer;
        }
        if (settings['isForceUpdateEnabled'] != null) {
          _isForceUpdateEnabled = settings['isForceUpdateEnabled'] as bool;
        }
        final updateUrl = (settings['appUpdateUrl'] as String?)?.trim();
        if (updateUrl != null && updateUrl.isNotEmpty) {
          _appUpdateUrl = updateUrl;
        }
        final updateMsg = (settings['appUpdateMessage'] as String?)?.trim();
        if (updateMsg != null && updateMsg.isNotEmpty) {
          _appUpdateMessage = updateMsg;
        }

        // Sync Dynamic Referral Campaign Settings
        if (settings['referralCampaignActive'] != null) {
          _referralCampaignActive = settings['referralCampaignActive'] as bool;
        }
        if (settings['referralMinOrderValue'] != null) {
          _referralMinOrderValue =
              (settings['referralMinOrderValue'] as num).toDouble();
        }
        if (settings['referralCouponMinOrderValue'] != null) {
          _referralCouponMinOrderValue =
              (settings['referralCouponMinOrderValue'] as num).toDouble();
        }
        if (settings['referralCouponValidityDays'] != null) {
          _referralCouponValidityDays =
              (settings['referralCouponValidityDays'] as num).toInt();
        }
        if (settings['referrerRewardAmount'] != null) {
          _referrerRewardAmount =
              (settings['referrerRewardAmount'] as num).toDouble();
        }
        if (settings['referredUserRewardAmount'] != null) {
          _referredUserRewardAmount =
              (settings['referredUserRewardAmount'] as num).toDouble();
        }
        if ((settings['referralBannerTitle'] as String?)?.isNotEmpty == true) {
          _referralBannerTitle = settings['referralBannerTitle'] as String;
        }
        if ((settings['referralBannerDescription'] as String?)?.isNotEmpty ==
            true) {
          _referralBannerDescription =
              settings['referralBannerDescription'] as String;
        }

        notifyListeners();
      }
    });
  }

  // Recalculates dynamic item counts and injects Special System Categories with dynamic covers
  void _recalculateCategoryAggregations() {
    final Map<String, int> catCounts = {};
    int trendingCount = 0;
    int bogoCount = 0;

    for (final p in _products) {
      if (p.isTrending) trendingCount++;
      if (p.isBogo) bogoCount++;

      final catKey = p.category.trim();
      if (catKey.isNotEmpty) {
        catCounts[catKey] = (catCounts[catKey] ?? 0) + 1;
      }
    }

    Map<String, dynamic>? findCover(String key, [String? fallbackKey]) {
      final k1 = key.trim().toLowerCase();
      if (_categoryCoversMap.containsKey(k1)) return _categoryCoversMap[k1];
      if (fallbackKey != null) {
        final k2 = fallbackKey.trim().toLowerCase();
        if (_categoryCoversMap.containsKey(k2)) return _categoryCoversMap[k2];
      }
      // Also try normalized key matching (ignoring punctuation, ampersands, spaces)
      final normKey1 = k1.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normKey1.isNotEmpty) {
        for (final entry in _categoryCoversMap.entries) {
          final normEntry = entry.key.replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (normEntry.isNotEmpty &&
              (normEntry == normKey1 ||
                  normKey1.contains(normEntry) ||
                  normEntry.contains(normKey1))) {
            return entry.value;
          }
        }
      }
      return null;
    }

    final List<CategoryModel> aggregated = [];

    // 1. Special System Category: All Products
    final allCover = findCover('all');
    final allVisible = allCover != null ? (allCover['isActive'] != false) : true;
    if (allVisible) {
      aggregated.add(
        CategoryModel(
          id: 'all',
          name: (allCover?['title'] as String?)?.trim().isNotEmpty == true
              ? (allCover!['title'] as String).trim()
              : 'All Products',
          itemCount: '${_products.length} Items',
          imageUrl: allCover?['imageUrl'] as String?,
          tag: allCover?['tag'] as String?,
          colorHex: allCover?['colorHex'] as String? ?? '0xFFFFF4B8',
          order: ((allCover?['order'] ?? 0) as num).toInt(),
          isVisible: true,
        ),
      );
    }

    // 2. Special System Category: Trending Now
    final trendCover = findCover('trending');
    final trendVisible = trendCover != null ? (trendCover['isActive'] != false) : true;
    if (trendVisible) {
      aggregated.add(
        CategoryModel(
          id: 'Trending',
          name: (trendCover?['title'] as String?)?.trim().isNotEmpty == true
              ? (trendCover!['title'] as String).trim()
              : 'Trending',
          itemCount: '$trendingCount Items',
          imageUrl: trendCover?['imageUrl'] as String?,
          tag: trendCover?['tag'] as String? ?? 'HOT',
          colorHex: trendCover?['colorHex'] as String? ?? '0xFFFFE0B2',
          order: ((trendCover?['order'] ?? 1) as num).toInt(),
          isVisible: true,
        ),
      );
    }

    // 3. Special System Category: Buy 1 Get 1 (BOGO)
    final bogoCover = findCover('bogo');
    final bogoVisible = bogoCover != null ? (bogoCover['isActive'] != false) : true;
    if (bogoVisible) {
      aggregated.add(
        CategoryModel(
          id: 'BOGO',
          name: (bogoCover?['title'] as String?)?.trim().isNotEmpty == true
              ? (bogoCover!['title'] as String).trim()
              : 'Buy 1 Get 1',
          itemCount: '$bogoCount Items',
          imageUrl: bogoCover?['imageUrl'] as String?,
          tag: bogoCover?['tag'] as String? ?? 'BOGO',
          colorHex: bogoCover?['colorHex'] as String? ?? '0xFFE1BEE7',
          order: ((bogoCover?['order'] ?? 2) as num).toInt(),
          isVisible: true,
        ),
      );
    }

    // 4. Firestore Database Categories with live counts & subcategories & custom covers
    int fallbackOrder = 3;
    for (final cat in _rawCategories) {
      final count = catCounts[cat.name] ?? catCounts[cat.id] ?? 0;
      final cover = findCover(cat.name, cat.id);
      final isVis = cover != null ? (cover['isActive'] != false) : cat.isVisible;
      if (!isVis) continue;

      String? resolvedImageUrl = (cover?['imageUrl'] as String?)?.trim();
      if (resolvedImageUrl == null || resolvedImageUrl.isEmpty) {
        resolvedImageUrl = cat.imageUrl?.trim();
      }
      if (resolvedImageUrl == null || resolvedImageUrl.isEmpty) {
        final catLower = cat.name.trim().toLowerCase();
        final catIdLower = cat.id.trim().toLowerCase();
        for (final p in _products) {
          final pCatLower = p.category.trim().toLowerCase();
          if ((pCatLower == catLower ||
                  pCatLower == catIdLower ||
                  catLower.contains(pCatLower)) &&
              p.imageUrl.trim().isNotEmpty) {
            resolvedImageUrl = p.imageUrl.trim();
            break;
          }
        }
      }

      aggregated.add(
        CategoryModel(
          id: cat.id,
          name: (cover?['title'] as String?)?.trim().isNotEmpty == true
              ? (cover!['title'] as String).trim()
              : cat.name,
          subcategories: cat.subcategories,
          itemCount: '$count Item${count == 1 ? '' : 's'}',
          icon: cat.icon,
          colorHex: cover?['colorHex'] as String? ?? cat.colorHex,
          imageUrl: resolvedImageUrl,
          tag: cover?['tag'] as String? ?? cat.tag,
          order: cover != null && cover['order'] != null
              ? (cover['order'] as num).toInt()
              : fallbackOrder++,
          isVisible: true,
        ),
      );
    }

    // Sort by designated order
    aggregated.sort((a, b) => a.order.compareTo(b.order));

    _categoriesList = aggregated;
    _persistCategoriesToStorage();
  }

  // Active Category Selection
  void selectCategory(String categoryIdOrName) {
    if (_selectedCategory == categoryIdOrName) {
      _selectedCategory = 'all';
    } else {
      _selectedCategory = categoryIdOrName;
    }
    _selectedSubcategory = ''; // Reset subcategory on category switch
    _displayLimit = 10;
    notifyListeners();
  }

  // Active Subcategory Selection
  void selectSubcategory(String subcategory) {
    if (_selectedSubcategory == subcategory) {
      _selectedSubcategory = '';
    } else {
      _selectedSubcategory = subcategory;
    }
    _displayLimit = 10;
    notifyListeners();
  }

  // Search Query Handler with SmartSearchEngine
  void setSearchQuery(String query) {
    _searchQuery = query;
    _displayLimit = 10;
    notifyListeners();
  }

  // Sort Option Handler
  void setSortOption(ProductSortOption sortOption) {
    _sortBy = sortOption;
    notifyListeners();
  }

  // Lazy Loading Pagination Handler
  void loadMoreProducts() {
    if (_isLoadingMore || _displayLimit >= filteredProducts.length) return;
    _isLoadingMore = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 300), () {
      _displayLimit += 8;
      _isLoadingMore = false;
      notifyListeners();
    });
  }

  // Returns list of subcategories for currently active category
  List<String> get activeCategorySubcategories {
    final activeCat = _categoriesList.firstWhere(
      (c) => c.id == _selectedCategory || c.name == _selectedCategory,
      orElse: () => CategoryModel(id: '', name: ''),
    );
    return activeCat.subcategories;
  }

  // Dynamic Product Filter Pipeline
  List<ProductModel> get filteredProducts {
    List<ProductModel> result = List.from(_products);

    // Category Filtering
    if (_selectedCategory != 'all') {
      if (_selectedCategory == 'Trending') {
        result = result.where((p) => p.isTrending).toList();
      } else if (_selectedCategory == 'BOGO') {
        result = result.where((p) => p.isBogo).toList();
      } else {
        result = result.where((p) {
          final catLower = _selectedCategory.toLowerCase();
          return p.category.toLowerCase() == catLower ||
              p.category.toLowerCase().contains(catLower) ||
              catLower.contains(p.category.toLowerCase());
        }).toList();
      }
    }

    // Subcategory Filtering
    if (_selectedSubcategory.isNotEmpty) {
      result = result.where((p) {
        return p.subcategory.toLowerCase() ==
                _selectedSubcategory.toLowerCase() ||
            p.title.toLowerCase().contains(_selectedSubcategory.toLowerCase());
      }).toList();
    }

    // Smart Search Engine with Typo and Synonym support
    if (_searchQuery.trim().isNotEmpty) {
      result = SmartSearchEngine.search(result, _searchQuery);
    }

    // Sorting
    switch (_sortBy) {
      case ProductSortOption.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProductSortOption.featured:
        result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
    }

    return result;
  }

  List<ProductModel> get specialDeals {
    return _products.where((p) => p.isDeal || p.offPercentage >= 15).toList();
  }

  List<ProductModel> get trendingProducts {
    final trending = _products.where((p) => p.isTrending).toList();
    return trending.isNotEmpty ? trending : _products.take(6).toList();
  }

  List<ProductModel> get bogoProducts {
    return _products.where((p) => p.isBogo).toList();
  }

  // Bakery & Biscuits specific products
  List<ProductModel> get bakeryAndBiscuitsProducts {
    final bakery = _products.where((p) {
      final cat = p.category.toLowerCase();
      final title = p.title.toLowerCase();
      return cat.contains('bake') ||
          cat.contains('bread') ||
          cat.contains('biscuit') ||
          cat.contains('cake') ||
          cat.contains('cookie') ||
          p.tags.any(
            (t) =>
                t.toLowerCase().contains('bake') ||
                t.toLowerCase().contains('bread') ||
                t.toLowerCase().contains('biscuit') ||
                t.toLowerCase().contains('cake') ||
                t.toLowerCase().contains('cookie') ||
                t.toLowerCase().contains('toast'),
          ) ||
          title.contains('cookie') ||
          title.contains('bread') ||
          title.contains('cake') ||
          title.contains('brownie') ||
          title.contains('biscuit');
    }).toList();
    return bakery.isNotEmpty ? bakery : _products.take(4).toList();
  }

  // Baby Care specific products
  List<ProductModel> get babyCareProducts {
    final babyProds = _products.where((p) {
      final cat = p.category.toLowerCase();
      final title = p.title.toLowerCase();
      return cat.contains('baby') ||
          p.tags.any(
            (t) =>
                t.toLowerCase().contains('baby') ||
                t.toLowerCase().contains('diaper'),
          ) ||
          title.contains('baby') ||
          title.contains('pampers') ||
          title.contains('diaper') ||
          title.contains('wipes') ||
          title.contains('cerelac');
    }).toList();
    return babyProds;
  }

  // Coupon & Checkout State
  String? _appliedCouponCode;
  String? _appliedCouponUserId;
  double _couponDiscount = 0.0;
  String? _couponError;

  String? get appliedCouponCode => _appliedCouponCode;
  double get couponDiscount => _couponDiscount;
  String? get couponError => _couponError;

  // Cart Management
  void addToCart(String productId, {int maxLimit = 5}) {
    final currentQty = _cartItems[productId] ?? 0;
    if (currentQty >= maxLimit) {
      _couponError = 'Maximum $maxLimit units allowed per product';
      notifyListeners();
      return;
    }

    if (_cartItems.containsKey(productId)) {
      _cartItems[productId] = _cartItems[productId]! + 1;
    } else {
      _cartItems[productId] = 1;
    }
    _persistCartToStorage();
    _recalculateCoupon();
    notifyListeners();

    // Schedule or extend local Hinglish abandoned cart reminder (2 hours delay)
    try {
      final sampleProd = _products.where((p) => p.id == productId).isNotEmpty
          ? _products.firstWhere((p) => p.id == productId).title
          : null;
      NotificationService.instance.scheduleAbandonedCartReminder(
        delay: const Duration(hours: 2),
        itemCount: cartCount,
        sampleItemName: sampleProd,
      );
    } catch (_) {}
  }

  void removeFromCart(String productId) {
    if (_cartItems.containsKey(productId)) {
      if (_cartItems[productId]! > 1) {
        _cartItems[productId] = _cartItems[productId]! - 1;
      } else {
        _cartItems.remove(productId);
      }
      _persistCartToStorage();
      _recalculateCoupon();
      notifyListeners();

      // If cart is now empty, cancel the reminder. Otherwise extend it.
      try {
        if (_cartItems.isEmpty) {
          NotificationService.instance.cancelAbandonedCartReminder();
        } else {
          NotificationService.instance.scheduleAbandonedCartReminder(
            delay: const Duration(hours: 2),
            itemCount: cartCount,
          );
        }
      } catch (_) {}
    }
  }

  void clearCart() {
    _cartItems.clear();
    _appliedCouponCode = null;
    _appliedCouponUserId = null;
    _couponDiscount = 0.0;
    _couponError = null;
    _persistCartToStorage();
    notifyListeners();

    // Cancel reminder upon successful order / checkout
    try {
      NotificationService.instance.cancelAbandonedCartReminder();
    } catch (_) {}
  }

  int getQuantity(String productId) {
    return _cartItems[productId] ?? 0;
  }

  int get cartCount {
    int total = 0;
    _cartItems.forEach((_, qty) => total += qty);
    return total;
  }

  double get cartTotalAmount {
    double total = 0.0;
    _cartItems.forEach((prodId, qty) {
      ProductModel? prod;
      try {
        prod = _products.firstWhere((p) => p.id == prodId);
      } catch (_) {
        try {
          prod = SeedData.fallbackProducts.firstWhere((fp) => fp.id == prodId);
        } catch (_) {
          prod = null;
        }
      }

      // If product exists in active or fallback catalog, add price.
      // If deleted/orphaned, safely contribute ₹0 instead of charging for wrong item!
      if (prod != null) {
        total += prod.price * qty;
      }
    });
    return total;
  }

  // Delivery Fee: Free on orders ₹199+, else ₹25
  double get deliveryFee {
    if (cartTotalAmount == 0 || cartTotalAmount >= 199.0) {
      return 0.0;
    }
    return 25.0;
  }

  // Final Payable Total
  double get finalPayableAmount {
    if (cartTotalAmount == 0) return 0.0;
    final total = cartTotalAmount + deliveryFee - _couponDiscount;
    return total > 0 ? total : 0.0;
  }

  // Coupon Application (Supports Firestore Dynamic & Referral Coupons + Legacy fallback)
  Future<bool> applyCoupon(String code, {String? userId}) async {
    final cleanCode = code.trim().toUpperCase();
    _couponError = null;

    if (cartTotalAmount <= 0) {
      _couponError = 'Your cart is empty';
      notifyListeners();
      return false;
    }

    try {
      // 1. Check dynamic coupon from Firestore (Admin generated or Referral Reward Coupons)
      final couponDoc = await _firestoreService.fetchCoupon(cleanCode);
      if (couponDoc != null) {
        final bool isActive = couponDoc['isActive'] as bool? ?? true;
        if (!isActive) {
          _couponError = 'This coupon is no longer active';
          notifyListeners();
          return false;
        }

        // Check user restriction (for referral coupons locked to specific user)
        final String? couponUser = couponDoc['userId'] as String?;
        if (couponUser != null && couponUser.trim().isNotEmpty) {
          if (userId == null || userId.trim() != couponUser.trim()) {
            _couponError =
                'This coupon is exclusive to its registered recipient';
            notifyListeners();
            return false;
          }
        }

        // Check validity date
        final dynamic rawExpiry = couponDoc['validUntil'];
        if (rawExpiry != null) {
          DateTime? expiryDate;
          if (rawExpiry is Timestamp) {
            expiryDate = rawExpiry.toDate();
          } else if (rawExpiry is String && rawExpiry.isNotEmpty) {
            expiryDate = DateTime.tryParse(rawExpiry);
          }
          if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
            _couponError = 'This coupon has expired';
            notifyListeners();
            return false;
          }
        }

        // Check minimum order value
        final double minOrder =
            ((couponDoc['minOrderValue'] ?? 0) as num).toDouble();
        if (cartTotalAmount < minOrder) {
          _couponError =
              'Minimum cart value of ₹${minOrder.toInt()} required for this coupon';
          notifyListeners();
          return false;
        }

        // Check usage limits if specified
        final int maxUses = ((couponDoc['maxUses'] ?? 0) as num).toInt();
        final int usedCount = ((couponDoc['usedCount'] ?? 0) as num).toInt();
        if (maxUses > 0 && usedCount >= maxUses) {
          _couponError = 'This coupon has already been redeemed';
          notifyListeners();
          return false;
        }

        // Calculate discount
        final String discountType =
            (couponDoc['discountType'] ?? couponDoc['type'] ?? 'flat')
                .toString()
                .toLowerCase();
        final double discountValue =
            ((couponDoc['discountValue'] ?? couponDoc['discount'] ?? 0) as num)
                .toDouble();
        final double maxDiscount =
            ((couponDoc['maxDiscount'] ?? 0) as num).toDouble();

        double discount = 0.0;
        if (discountType == 'percentage') {
          discount = (cartTotalAmount * (discountValue / 100)).roundToDouble();
          if (maxDiscount > 0 && discount > maxDiscount) {
            discount = maxDiscount;
          }
        } else {
          // Flat discount
          discount = discountValue;
        }

        if (discount > cartTotalAmount) {
          discount = cartTotalAmount;
        }

        _appliedCouponCode = cleanCode;
        _appliedCouponUserId = userId;
        _couponDiscount = discount;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error verifying coupon from Firestore: $e');
    }

    // 2. Fallback to Legacy Static Coupon Codes
    if (cartTotalAmount < 100.0) {
      _couponError = 'Minimum order value of ₹100 required for coupons';
      notifyListeners();
      return false;
    }

    if (cleanCode == 'FRESH100') {
      if (cartTotalAmount < 399.0) {
        _couponError = 'FRESH100 requires minimum order of ₹399';
        notifyListeners();
        return false;
      }
      _appliedCouponCode = 'FRESH100';
      _appliedCouponUserId = null;
      _couponDiscount = 100.0;
    } else if (cleanCode == 'GROCERY50') {
      if (cartTotalAmount < 199.0) {
        _couponError = 'GROCERY50 requires minimum order of ₹199';
        notifyListeners();
        return false;
      }
      _appliedCouponCode = 'GROCERY50';
      _appliedCouponUserId = null;
      _couponDiscount = 50.0;
    } else if (cleanCode == 'WELCOME') {
      _appliedCouponCode = 'WELCOME';
      _appliedCouponUserId = null;
      _couponDiscount =
          (cartTotalAmount * 0.15).roundToDouble().clamp(0.0, 75.0);
    } else {
      _couponError = 'Invalid coupon code. Please check and try again.';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _appliedCouponUserId = null;
    _couponDiscount = 0.0;
    _couponError = null;
    notifyListeners();
  }

  void _recalculateCoupon() {
    if (_appliedCouponCode != null) {
      applyCoupon(_appliedCouponCode!, userId: _appliedCouponUserId);
    }
  }
}
