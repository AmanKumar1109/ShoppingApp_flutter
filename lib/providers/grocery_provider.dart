import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../services/seed_data.dart';
import '../utils/search_engine.dart';

enum ProductSortOption { featured, priceLowToHigh, priceHighToLow, rating }

final groceryProvider = ChangeNotifierProvider<GroceryProvider>((ref) {
  return GroceryProvider();
});

class GroceryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

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

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categoriesList;
  String get selectedCategory => _selectedCategory;
  String get selectedSubcategory => _selectedSubcategory;
  String get searchQuery => _searchQuery;
  ProductSortOption get sortBy => _sortBy;
  Map<String, int> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  int get displayLimit => _displayLimit;
  bool get isLoadingMore => _isLoadingMore;

  GroceryProvider() {
    _initRealTimeSync();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
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
  }

  // Recalculates dynamic item counts and injects Special System Categories
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

    final List<CategoryModel> aggregated = [];

    // 1. Special System Category: All Products
    aggregated.add(
      CategoryModel(
        id: 'all',
        name: 'All Products',
        itemCount: '${_products.length} Items',
      ),
    );

    // 2. Special System Category: Trending Now
    aggregated.add(
      CategoryModel(
        id: 'Trending',
        name: 'Trending',
        itemCount: '$trendingCount Items',
      ),
    );

    // 3. Special System Category: Buy 1 Get 1 (BOGO)
    aggregated.add(
      CategoryModel(
        id: 'BOGO',
        name: 'Buy 1 Get 1',
        itemCount: '$bogoCount Items',
      ),
    );

    // 4. Firestore Database Categories with live counts & subcategories
    for (final cat in _rawCategories) {
      final count = catCounts[cat.name] ?? catCounts[cat.id] ?? 0;
      aggregated.add(
        CategoryModel(
          id: cat.id,
          name: cat.name,
          subcategories: cat.subcategories,
          itemCount: '$count Item${count == 1 ? '' : 's'}',
          icon: cat.icon,
          colorHex: cat.colorHex,
        ),
      );
    }

    _categoriesList = aggregated;
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
    _recalculateCoupon();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    if (_cartItems.containsKey(productId)) {
      if (_cartItems[productId]! > 1) {
        _cartItems[productId] = _cartItems[productId]! - 1;
      } else {
        _cartItems.remove(productId);
      }
      _recalculateCoupon();
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _appliedCouponCode = null;
    _couponDiscount = 0.0;
    _couponError = null;
    notifyListeners();
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
      final prod = _products.firstWhere(
        (p) => p.id == prodId,
        orElse: () => SeedData.fallbackProducts.firstWhere(
          (fp) => fp.id == prodId,
          orElse: () => SeedData.fallbackProducts.first,
        ),
      );
      total += prod.price * qty;
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

  // Coupon Application
  bool applyCoupon(String code) {
    final cleanCode = code.trim().toUpperCase();
    _couponError = null;

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
      _couponDiscount = 100.0;
    } else if (cleanCode == 'GROCERY50') {
      if (cartTotalAmount < 199.0) {
        _couponError = 'GROCERY50 requires minimum order of ₹199';
        notifyListeners();
        return false;
      }
      _appliedCouponCode = 'GROCERY50';
      _couponDiscount = 50.0;
    } else if (cleanCode == 'WELCOME') {
      _appliedCouponCode = 'WELCOME';
      _couponDiscount = (cartTotalAmount * 0.15).roundToDouble().clamp(
        0.0,
        75.0,
      );
    } else {
      _couponError = 'Invalid coupon code. Try FRESH100 or GROCERY50';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _couponDiscount = 0.0;
    _couponError = null;
    notifyListeners();
  }

  void _recalculateCoupon() {
    if (_appliedCouponCode != null) {
      applyCoupon(_appliedCouponCode!);
    }
  }
}
