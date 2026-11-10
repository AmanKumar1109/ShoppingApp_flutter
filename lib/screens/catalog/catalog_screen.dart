import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_model.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/search_engine.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/fast_cached_image.dart';

enum CatalogSortType { featured, priceLowToHigh, priceHighToLow, rating }

class CatalogScreen extends ConsumerStatefulWidget {
  final String title;
  final String? categoryId;
  final String?
  sectionType; // 'deals', 'trending', 'bakery', 'baby', 'bogo', 'all'
  final String? searchTerm;

  const CatalogScreen({
    super.key,
    required this.title,
    this.categoryId,
    this.sectionType,
    this.searchTerm,
  });

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;
  int _displayLimit = 10;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'all';
  CatalogSortType _sortType = CatalogSortType.featured;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final initialSearch = widget.searchTerm?.trim() ?? '';
    _searchQuery = initialSearch;
    _searchController = TextEditingController(text: initialSearch);
    if (widget.sectionType != null && widget.sectionType != 'all') {
      _selectedCategoryFilter = widget.sectionType!;
    } else if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
      _selectedCategoryFilter = widget.categoryId!;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Automatic Lazy Loading Trigger when scrolling within 250px from bottom
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoadingMore) return;
    final allProducts = _getFilteredProducts();
    if (_displayLimit >= allProducts.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _displayLimit += 10;
          _isLoadingMore = false;
        });
      }
    });
  }

  List<ProductModel> _getFilteredProducts() {
    final grocery = ref.read(groceryProvider);
    List<ProductModel> list = List.from(grocery.products);

    // Apply Active Category / Section Filter
    if (_selectedCategoryFilter != 'all') {
      final filterLower = _selectedCategoryFilter.toLowerCase();
      if (filterLower == 'deals' || filterLower == 'deal') {
        list = list.where((p) => p.isDeal || p.offPercentage >= 15).toList();
      } else if (filterLower == 'trending') {
        list = list.where((p) => p.isTrending).toList();
      } else if (filterLower == 'bogo') {
        list = list.where((p) => p.isBogo).toList();
      } else if (filterLower == 'baby' || filterLower.contains('baby')) {
        list = grocery.babyCareProducts;
      } else if (filterLower == 'bakery' || filterLower.contains('bakery')) {
        list = grocery.bakeryAndBiscuitsProducts;
      } else if (filterLower == 'cleaning' || filterLower.contains('cleaning')) {
        list = list.where((p) =>
            p.category.toLowerCase().contains('cleaning') ||
            p.subcategory.toLowerCase().contains('detergent') ||
            p.tags.any((t) => [
                  'surf',
                  'detergent',
                  'cleaning',
                  'laundry',
                  'ariel',
                ].contains(t.toLowerCase()))).toList();
      } else if (filterLower == 'dairy' || filterLower.contains('dairy')) {
        list = list.where((p) =>
            p.category.toLowerCase().contains('dairy') ||
            p.tags.any((t) => [
                  'milk',
                  'dairy',
                  'paneer',
                  'butter',
                  'amul',
                  'doodh',
                ].contains(t.toLowerCase()))).toList();
      } else {
        list = list.where((p) {
          return p.category.toLowerCase() == filterLower ||
              p.category.toLowerCase().contains(filterLower) ||
              filterLower.contains(p.category.toLowerCase()) ||
              p.tags.any((t) => t.toLowerCase().contains(filterLower));
        }).toList();
      }
    }

    // Apply Catalog In-Page Search Query via SmartSearchEngine
    if (_searchQuery.trim().isNotEmpty) {
      list = SmartSearchEngine.search(list, _searchQuery.trim());
    }

    // Apply Sorting
    switch (_sortType) {
      case CatalogSortType.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case CatalogSortType.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case CatalogSortType.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case CatalogSortType.featured:
        list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final grocery = ref.watch(groceryProvider);
    final allProducts = _getFilteredProducts();
    final displayedProducts = allProducts.take(_displayLimit).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // 1. Signature Soft Yellow Gradient Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF4B8), // Soft yellowish top header
                  Color(0xFFFFF9E0),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Row
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 16,
                      top: 4,
                      bottom: 6,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF19251B),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF19251B),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                '${allProducts.length} Items Available',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // In-Page Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: CustomSearchField(
                      controller: _searchController,
                      hintText: 'Search within products...',
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          _displayLimit = 10;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _searchQuery = '';
                          _displayLimit = 10;
                        });
                      },
                    ),
                  ),

                  // Category Filter Tabs Slider
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 4,
                    ),
                    child: Row(
                      children: [
                        _buildCategoryFilterChip('All Products', 'all'),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChip('Deals & Offers', 'deals'),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChip('Trending', 'trending'),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChip('Bakery & Biscuits', 'bakery'),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChip('Baby Care', 'baby'),
                        const SizedBox(width: 8),
                        ...grocery.categories
                            .where(
                              (c) =>
                                  c.id != 'all' &&
                                  c.id != 'Trending' &&
                                  c.id != 'BOGO',
                            )
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildCategoryFilterChip(c.name, c.name),
                              ),
                            ),
                      ],
                    ),
                  ),

                  // Sorting Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 6,
                      bottom: 12,
                    ),
                    child: Row(
                      children: [
                        _buildSortChip('Featured', CatalogSortType.featured),
                        const SizedBox(width: 8),
                        _buildSortChip(
                          'Price: Low to High',
                          CatalogSortType.priceLowToHigh,
                        ),
                        const SizedBox(width: 8),
                        _buildSortChip(
                          'Price: High to Low',
                          CatalogSortType.priceHighToLow,
                        ),
                        const SizedBox(width: 8),
                        _buildSortChip('Top Rated', CatalogSortType.rating),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Products Grid with Lazy Loading
          Expanded(
            child: allProducts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF19251B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your category filters or search terms.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.67,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                        itemCount: displayedProducts.length,
                        itemBuilder: (context, index) {
                          return _buildCatalogProductCard(
                            context,
                            displayedProducts[index],
                            index: index,
                          );
                        },
                      ),

                      // Lazy Loading Progress Spinner or End Indicator
                      if (_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF7C415),
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      else if (displayedProducts.length < allProducts.length)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: _loadMoreItems,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFF7C415),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(
                                Icons.arrow_downward_rounded,
                                size: 16,
                                color: Color(0xFF19251B),
                              ),
                              label: Text(
                                'Load More (${allProducts.length - displayedProducts.length} remaining)',
                                style: const TextStyle(
                                  color: Color(0xFF19251B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'You have seen all ${allProducts.length} items',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),

      // Sticky Bottom Cart Bar
      bottomNavigationBar: grocery.cartCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${grocery.cartCount} ITEMS IN CART',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '₹${grocery.cartTotalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF19251B),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    CustomPillButton(
                      text: 'View Cart',
                      onPressed: () => Navigator.pop(context),
                      backgroundColor: const Color(0xFF10B981),
                      textColor: Colors.white,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCategoryFilterChip(String label, String filterKey) {
    final isSelected =
        _selectedCategoryFilter.toLowerCase() == filterKey.toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryFilter = filterKey;
          _displayLimit = 10;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF19251B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF19251B)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFFF7C415)
                : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, CatalogSortType type) {
    final isSelected = _sortType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF19251B)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF19251B)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFFF7C415)
                : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogProductCard(
    BuildContext context,
    ProductModel product, {
    int? index,
  }) {
    final grocery = ref.watch(groceryProvider);
    final inCartQty = grocery.getQuantity(product.id);
    final heroTag = index != null
        ? 'hero_catalog_${product.id}_$index'
        : 'hero_catalog_${product.id}';

    return InkWell(
      onTap: () {
        AppRoutes.navigateToProduct(
          context,
          product,
          heroTag: heroTag,
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview Container with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Hero(
                    tag: heroTag,
                    child: Material(
                      type: MaterialType.transparency,
                      child: FastCachedImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              // Rating Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF7C415),
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF19251B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Discount or BOGO badge
              if (product.offPercentage > 0 || product.isBogo)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: product.isBogo
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.isBogo ? 'BOGO' : '${product.offPercentage}% OFF',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF152C1E),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.unit,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price & MRP
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF152C1E),
                            ),
                          ),
                          if (product.mrp > product.price)
                            Text(
                              '₹${product.mrp.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),

                      // Add to cart / Quantity incrementer
                      if (inCartQty == 0)
                        GestureDetector(
                          onTap: () {
                            grocery.addToCart(product.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7C415),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF7C415,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'ADD',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF19251B),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF19251B),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    grocery.removeFromCart(product.id),
                                child: const Icon(
                                  Icons.remove,
                                  color: Color(0xFFF7C415),
                                  size: 16,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  '$inCartQty',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    grocery.addToCart(product.id),
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFFF7C415),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
