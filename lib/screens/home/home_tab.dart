import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_model.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/fast_cached_image.dart';
import '../../widgets/grocery_grand_deals_section.dart';
import '../../widgets/promo_ad_banner_carousel.dart';
import '../../widgets/skeleton_loader.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grocery = ref.watch(groceryProvider);

    // If initial loading from Firestore is in progress -> Show Skeleton Screen
    if (grocery.isLoading && grocery.products.isEmpty) {
      return const HomeSkeletonScreen();
    }

    final isCategoryFiltered =
        grocery.selectedCategory != 'all' ||
        grocery.searchQuery.trim().isNotEmpty;
    final activeSubcategories = grocery.activeCategorySubcategories;
    final filteredList = grocery.filteredProducts;
    final displayedProducts = filteredList
        .take(grocery.displayLimit)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Soft Yellow Gradient Header
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar with live interactive Delivery Address
                const HomeAppBarWidget(),

                // Delivering in 10 minutes badge
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 2,
                    bottom: 6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF19251B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFFF7C415),
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Delivering in 10 minutes',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF19251B),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: CustomSearchField(
                    hintText: 'Search "surf", "milk", "brownie", "atta"...',
                    onChanged: (query) {
                      grocery.setSearchQuery(query);
                    },
                    onSubmitted: (query) {
                      if (query.trim().isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.catalog,
                          arguments: {
                            'title': 'Search: "$query"',
                            'sectionType': 'all',
                            'searchTerm': query.trim(),
                          },
                        );
                      }
                    },
                    onVoiceResult: (query) {
                      if (query.trim().isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.catalog,
                          arguments: {
                            'title': 'Search: "$query"',
                            'sectionType': 'all',
                            'searchTerm': query.trim(),
                          },
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Horizontal Category Showcase Slider
                SizedBox(
                  height: 104,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: grocery.categories.length,
                    itemBuilder: (context, index) {
                      final category = grocery.categories[index];
                      final isSelected =
                          grocery.selectedCategory == category.id ||
                          grocery.selectedCategory == category.name;

                      return GestureDetector(
                        onTap: () {
                          grocery.selectCategory(category.id);
                        },
                        child: Container(
                          width: 78,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF7C415)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF19251B)
                                        : Colors.transparent,
                                    width: isSelected ? 2 : 0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isSelected ? 0.15 : 0.05,
                                      ),
                                      blurRadius: isSelected ? 8 : 4,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    category.iconData,
                                    size: 26,
                                    color: isSelected
                                        ? const Color(0xFF19251B)
                                        : const Color(0xFF3B4D3F),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                category.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF19251B)
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                              Text(
                                category.itemCount,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFFB88600)
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 2. Secondary Subcategory Bar
                if (activeSubcategories.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: activeSubcategories.length + 1,
                      itemBuilder: (context, index) {
                        final isAllTab = index == 0;
                        final subcatName = isAllTab
                            ? 'All'
                            : activeSubcategories[index - 1];
                        final isSubSelected = isAllTab
                            ? grocery.selectedSubcategory.isEmpty
                            : grocery.selectedSubcategory
                                      .toLowerCase() ==
                                  subcatName.toLowerCase();

                        return GestureDetector(
                          onTap: () {
                            if (isAllTab) {
                              grocery.selectSubcategory('');
                            } else {
                              grocery.selectSubcategory(subcatName);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSubSelected
                                  ? const Color(0xFF19251B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSubSelected
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
                            child: Center(
                              child: Text(
                                subcatName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSubSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSubSelected
                                      ? const Color(0xFFF7C415)
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // If Category Filter or Search is Active -> Show Lazy-Loaded Filtered Grid
          if (isCategoryFiltered) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredList.length} Items Found',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF152C1E),
                    ),
                  ),
                  if (grocery.selectedCategory != 'all' ||
                      grocery.searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        grocery.selectCategory('all');
                        grocery.setSearchQuery('');
                      },
                      child: const Text(
                        'Clear Filters',
                        style: TextStyle(
                          color: Color(0xFFB88600),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: filteredList.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 54,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No items match your search or filter',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomPillButton(
                            text: 'View All Products',
                            onPressed: () {
                              grocery.selectCategory('all');
                              grocery.setSearchQuery('');
                            },
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 14,
                              ),
                          itemCount: displayedProducts.length,
                          itemBuilder: (context, index) {
                            final product = displayedProducts[index];
                            final heroTag = 'hero_home_grid_${product.id}_$index';
                            return _buildProductCard(
                              context,
                              ref,
                              product,
                              heroTag: heroTag,
                            );
                          },
                        ),
                        if (displayedProducts.length < filteredList.length) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: grocery.isLoadingMore
                                ? const CircularProgressIndicator(
                                    color: Color(0xFFF7C415),
                                  )
                                : TextButton.icon(
                                    onPressed: () =>
                                        grocery.loadMoreProducts(),
                                    icon: const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Color(0xFF19251B),
                                    ),
                                    label: Text(
                                      'Load More (${filteredList.length - displayedProducts.length} more)',
                                      style: const TextStyle(
                                        color: Color(0xFF19251B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 30),
          ] else ...[
            // 1. TOP PROMOTIONAL AD BANNER CAROUSEL (Cadbury Brownie, Surf Excel, etc.)
            const PromoAdBannerCarousel(),

            const SizedBox(height: 24),

            // 2. TODAY SPECIAL DEALS
            _buildSectionHeader(
              title: 'Today Special Deals',
              onSeeAll: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.catalog,
                  arguments: {
                    'title': 'Today Special Deals',
                    'sectionType': 'deals',
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            // Special Deals Horizontal Carousel
            SizedBox(
              height: 248,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: grocery.specialDeals.length,
                itemBuilder: (context, index) {
                  final product = grocery.specialDeals[index];
                  final heroTag = 'hero_home_deals_${product.id}_$index';
                  return Container(
                    width: 168,
                    margin: const EdgeInsets.only(right: 14),
                    child: _buildProductCard(
                      context,
                      ref,
                      product,
                      heroTag: heroTag,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 3. "THE GROCERY DEALS" CURATED LUXURY SHOWCASE
            const GroceryGrandDealsSection(),

            const SizedBox(height: 28),

            // 5. BAKERY & BISCUITS PROMOTIONAL BANNER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 170,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFF3E0),
                      Color(0xFFFFE0B2),
                      Color(0xFFFFCC80),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 8,
                      top: 12,
                      bottom: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: const FastCachedImage(
                          imageUrl:
                              'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=400&auto=format&fit=crop',
                          width: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF19251B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OVEN FRESH BAKERY',
                              style: TextStyle(
                                color: Color(0xFFF7C415),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Bakery & Biscuits',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF19251B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Up to 25% Off on Cookies & Cakes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomPillButton(
                            text: 'Shop Bakery',
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.catalog,
                                arguments: {
                                  'title': 'Bakery & Biscuits',
                                  'sectionType': 'bakery',
                                  'categoryId': 'cat_bakery',
                                },
                              );
                            },
                            backgroundColor: const Color(0xFF19251B),
                            textColor: const Color(0xFFF7C415),
                            fontSize: 11.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. BAKERY & BISCUITS PRODUCTS CAROUSEL
            if (grocery.bakeryAndBiscuitsProducts.isNotEmpty) ...[
              _buildSectionHeader(
                title: 'Bakery & Biscuits',
                onSeeAll: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.catalog,
                    arguments: {
                      'title': 'Bakery & Biscuits',
                      'sectionType': 'bakery',
                      'categoryId': 'cat_bakery',
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 248,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: grocery.bakeryAndBiscuitsProducts.length,
                  itemBuilder: (context, index) {
                    final product = grocery.bakeryAndBiscuitsProducts[index];
                    final heroTag = 'hero_home_bakery_${product.id}_$index';
                    return Container(
                      width: 168,
                      margin: const EdgeInsets.only(right: 14),
                      child: _buildProductCard(
                        context,
                        ref,
                        product,
                        heroTag: heroTag,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 5. TRENDING IN YOUR AREA
            _buildSectionHeader(
              title: 'Trending in Your Area',
              onSeeAll: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.catalog,
                  arguments: {
                    'title': 'Trending in Your Area',
                    'sectionType': 'trending',
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            // Trending Products Horizontal Carousel
            SizedBox(
              height: 248,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: grocery.trendingProducts.length,
                itemBuilder: (context, index) {
                  final product = grocery.trendingProducts[index];
                  final heroTag = 'hero_home_trending_${product.id}_$index';
                  return Container(
                    width: 168,
                    margin: const EdgeInsets.only(right: 14),
                    child: _buildProductCard(
                      context,
                      ref,
                      product,
                      heroTag: heroTag,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // 6. BABY CARE PROMOTIONAL BANNER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 170,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFEF3C7),
                      Color(0xFFFDE68A),
                      Color(0xFFFBBF24),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 8,
                      top: 12,
                      bottom: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: const FastCachedImage(
                          imageUrl:
                              'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400&auto=format&fit=crop',
                          width: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF19251B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BABY CARE SPECIAL',
                              style: TextStyle(
                                color: Color(0xFFF7C415),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Baby Care Essentials',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF19251B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Up to 30% Off on Diapers & Wipes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomPillButton(
                            text: 'Shop Baby Care',
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.catalog,
                                arguments: {
                                  'title': 'Baby Care Essentials',
                                  'sectionType': 'baby',
                                  'categoryId': 'cat_baby_care',
                                },
                              );
                            },
                            backgroundColor: const Color(0xFF19251B),
                            textColor: const Color(0xFFF7C415),
                            fontSize: 11.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 7. BABY CARE PRODUCTS CAROUSEL
            if (grocery.babyCareProducts.isNotEmpty) ...[
              _buildSectionHeader(
                title: 'Baby Care Essentials',
                onSeeAll: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.catalog,
                    arguments: {
                      'title': 'Baby Care Essentials',
                      'sectionType': 'baby',
                      'categoryId': 'cat_baby_care',
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 248,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: grocery.babyCareProducts.length,
                  itemBuilder: (context, index) {
                    final product = grocery.babyCareProducts[index];
                    final heroTag = 'hero_home_baby_${product.id}_$index';
                    return Container(
                      width: 168,
                      margin: const EdgeInsets.only(right: 14),
                      child: _buildProductCard(
                        context,
                        ref,
                        product,
                        heroTag: heroTag,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF152C1E),
            ),
          ),
          InkWell(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    ProductModel product, {
    String? heroTag,
  }) {
    final grocery = ref.watch(groceryProvider);
    final inCartQty = grocery.getQuantity(product.id);
    final effectiveHeroTag = heroTag ?? 'hero_home_${product.id}';

    return InkWell(
      onTap: () {
        AppRoutes.navigateToProduct(
          context,
          product,
          heroTag: effectiveHeroTag,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fast Cached Image preview container with badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
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
                    tag: effectiveHeroTag,
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

              // Rating Badge pill on top left
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

              // Discount badge (e.g. 25% OFF) or BOGO badge
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
