import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_model.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/search_engine.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/fast_cached_image.dart';
import '../../widgets/floating_cart_bar.dart';

enum SearchSortType { relevance, priceLowToHigh, priceHighToLow, rating }

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  SearchSortType _sortType = SearchSortType.relevance;
  String _currentQuery = '';

  static const List<String> _popularSearchKeywords = [
    'Rice',
    'Atta',
    'Milk',
    'Desi Ghee',
    'Surf Excel',
    'Tomato',
    'Tea',
    'Chocolate',
    'Paneer',
    'Sugar',
    'Oil',
  ];

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.initialQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _currentQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _currentQuery = val.trim();
    });
  }

  void _runSearch(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    setState(() {
      _currentQuery = query.trim();
    });
  }

  List<ProductModel> _getSearchResults(List<ProductModel> allProducts) {
    if (_currentQuery.isEmpty) return [];

    List<ProductModel> list = SmartSearchEngine.search(
      allProducts,
      _currentQuery,
    );

    switch (_sortType) {
      case SearchSortType.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SearchSortType.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SearchSortType.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SearchSortType.relevance:
        // Relevance ordering from SmartSearchEngine is already preserved
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final grocery = ref.watch(groceryProvider);
    final results = _getSearchResults(grocery.products);
    final cartCount = grocery.cartCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. Top Search Header
                _buildSearchHeader(context, cartCount),

                // 2. Sort Bar & Quick Filter (Shown only when results exist)
                if (_currentQuery.isNotEmpty && results.isNotEmpty)
                  _buildResultsBar(results.length),

                // 3. Body: Results Grid or Empty / Discovery State
                Expanded(
                  child: _currentQuery.isEmpty
                      ? _buildDiscoveryState(grocery.products)
                      : results.isEmpty
                          ? _buildNoResultsState()
                          : _buildResultsGrid(results),
                ),
              ],
            ),

            // Floating Cart Bar (Accessible directly while shopping search results)
            FloatingCartBar(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.cart);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Top Search Bar with Back button & Cart button
  Widget _buildSearchHeader(BuildContext context, int cartCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF19251B),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: CustomSearchField(
              controller: _searchController,
              hintText: 'Search "rice", "milk", "surf", "atta"...',
              enableVoiceSearch: true,
              onChanged: _onSearchChanged,
              onSubmitted: _runSearch,
              onVoiceResult: _runSearch,
              onClear: () {
                setState(() {
                  _searchController.clear();
                  _currentQuery = '';
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF19251B),
                    size: 20,
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF19251B),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          cartCount > 9 ? '9+' : '$cartCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFF7C415),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Results Count and Sort Chips Bar
  Widget _buildResultsBar(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count ${count == 1 ? "item" : "items"} for "$_currentQuery"',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF19251B),
            ),
          ),
          PopupMenuButton<SearchSortType>(
            initialValue: _sortType,
            onSelected: (val) {
              setState(() {
                _sortType = val;
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sort_rounded,
                    size: 15,
                    color: Color(0xFF19251B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _sortTypeLabel(_sortType),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF19251B),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: SearchSortType.relevance,
                child: Text('Relevance', style: TextStyle(fontSize: 13)),
              ),
              const PopupMenuItem(
                value: SearchSortType.priceLowToHigh,
                child: Text(
                  'Price: Low to High',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const PopupMenuItem(
                value: SearchSortType.priceHighToLow,
                child: Text(
                  'Price: High to Low',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const PopupMenuItem(
                value: SearchSortType.rating,
                child: Text('Customer Rating', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _sortTypeLabel(SearchSortType type) {
    switch (type) {
      case SearchSortType.relevance:
        return 'Relevance';
      case SearchSortType.priceLowToHigh:
        return 'Price: Low';
      case SearchSortType.priceHighToLow:
        return 'Price: High';
      case SearchSortType.rating:
        return 'Rating';
    }
  }

  /// Results Grid
  Widget _buildResultsGrid(List<ProductModel> products) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(context, products[index], index);
      },
    );
  }

  /// Individual Product Card
  Widget _buildProductCard(
    BuildContext context,
    ProductModel product,
    int index,
  ) {
    final grocery = ref.watch(groceryProvider);
    final inCartQty = grocery.getQuantity(product.id);
    final heroTag = 'hero_search_${product.id}_$index';

    return InkWell(
      onTap: () {
        AppRoutes.navigateToProduct(
          context,
          product,
          heroTag: heroTag,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Discount Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.all(6),
                    child: Hero(
                      tag: heroTag,
                      child: FastCachedImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                if (product.offPercentage > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.offPercentage}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF19251B),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.unit,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF19251B),
                              ),
                            ),
                            if (product.mrp > product.price)
                              Text(
                                '₹${product.mrp.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                        // Add Button / Counter
                        inCartQty == 0
                            ? SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () {
                                    grocery.addToCart(product.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFF9E0),
                                    foregroundColor: const Color(0xFF19251B),
                                    elevation: 0,
                                    side: const BorderSide(
                                      color: Color(0xFFF7C415),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    'ADD',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF19251B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove,
                                        size: 14,
                                        color: Color(0xFFF7C415),
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 26,
                                        minHeight: 32,
                                      ),
                                      onPressed: () {
                                        grocery.removeFromCart(product.id);
                                      },
                                    ),
                                    Text(
                                      '$inCartQty',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add,
                                        size: 14,
                                        color: Color(0xFFF7C415),
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 26,
                                        minHeight: 32,
                                      ),
                                      onPressed: () {
                                        grocery.addToCart(product.id);
                                      },
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

  /// Initial Search Discovery State (Popular keywords & quick chips)
  Widget _buildDiscoveryState(List<ProductModel> allProducts) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 80),
      children: [
        Row(
          children: const [
            Icon(
              Icons.trending_up_rounded,
              size: 18,
              color: Color(0xFFB88600),
            ),
            SizedBox(width: 6),
            Text(
              'Popular Searches',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF19251B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSearchKeywords.map((kw) {
            return InkWell(
              onTap: () => _runSearch(kw),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      kw,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        Row(
          children: const [
            Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: Color(0xFFDC2626),
            ),
            SizedBox(width: 6),
            Text(
              'Trending in Grocery Hub',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF19251B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...allProducts.take(5).map((p) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                color: Colors.white,
                child: FastCachedImage(
                  imageUrl: p.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            title: Text(
              p.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF19251B),
              ),
            ),
            subtitle: Text(
              '₹${p.price.toStringAsFixed(0)} • ${p.unit}',
              style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Colors.grey,
            ),
            onTap: () => _runSearch(p.title),
          );
        }),
      ],
    );
  }

  /// No Results Found State
  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: Color(0xFFB88600),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No items found for "$_currentQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF19251B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching with another keyword or pick from popular essentials below:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ['Rice', 'Atta', 'Milk', 'Oil', 'Surf Excel']
                  .map((kw) => ActionChip(
                        label: Text(
                          kw,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF19251B),
                          ),
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFFDE68A)),
                        onPressed: () => _runSearch(kw),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
