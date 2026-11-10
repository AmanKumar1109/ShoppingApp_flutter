import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_model.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/fast_cached_image.dart';

class CartScreen extends ConsumerWidget {
  final VoidCallback? onExploreGroceries;

  const CartScreen({super.key, this.onExploreGroceries});

  String _getCategoryEmoji(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('dairy') ||
        name.contains('milk') ||
        name.contains('egg') ||
        name.contains('bread')) {
      return '🥛';
    } else if (name.contains('fruit') || name.contains('veg')) {
      return '🥦';
    } else if (name.contains('snack') ||
        name.contains('biscuit') ||
        name.contains('munch')) {
      return '🍿';
    } else if (name.contains('beverage') ||
        name.contains('drink') ||
        name.contains('juice') ||
        name.contains('tea') ||
        name.contains('coffee')) {
      return '🧃';
    } else if (name.contains('atta') ||
        name.contains('rice') ||
        name.contains('dal') ||
        name.contains('oil') ||
        name.contains('grain')) {
      return '🌾';
    } else if (name.contains('baby') || name.contains('care')) {
      return '👶';
    } else if (name.contains('clean') ||
        name.contains('house') ||
        name.contains('detergent')) {
      return '🧼';
    } else if (name.contains('sweet') ||
        name.contains('choc') ||
        name.contains('dessert')) {
      return '🍫';
    }
    return '🛒';
  }

  Map<String, List<ProductModel>> _getRecommendedCategories(
    GroceryProvider grocery,
  ) {
    final allProducts = grocery.products.isNotEmpty
        ? grocery.products
        : FirestoreService.fallbackProducts;

    final Map<String, List<ProductModel>> categoryMap = {};
    for (final product in allProducts) {
      if (!product.isVisible) continue;
      final cat = product.category.trim().isNotEmpty
          ? product.category.trim()
          : 'Popular Daily Essentials';
      categoryMap.putIfAbsent(cat, () => []).add(product);
    }

    // Pick 2 to 3 categories that have at least 1 product
    final validCategoryKeys = categoryMap.keys.toList();
    validCategoryKeys.sort(
      (a, b) => categoryMap[b]!.length.compareTo(categoryMap[a]!.length),
    );

    final selectedKeys = validCategoryKeys.take(3).toList();
    final Map<String, List<ProductModel>> result = {};
    for (final key in selectedKeys) {
      result[key] = categoryMap[key]!.take(8).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grocery = ref.watch(groceryProvider);
    final cartItems = grocery.cartItems;
    final subtotal = grocery.cartTotalAmount;
    final remainingForFreeDelivery = (199.0 - subtotal).clamp(0.0, 199.0);
    final recommendedCategories = _getRecommendedCategories(grocery);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Soft Yellow Header matching Home Screen
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF4B8), // Soft yellow header gradient
                  Color(0xFFFFF9E0),
                  Color(0xFFF9FAFB),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeAppBarWidget(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF19251B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          color: Color(0xFFF7C415),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Your Shopping Cart',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF19251B),
                        ),
                      ),
                      if (cartItems.isNotEmpty) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF19251B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${grocery.cartCount} ${grocery.cartCount == 1 ? 'item' : 'items'}',
                            style: const TextStyle(
                              color: Color(0xFFF7C415),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // Cart Body Content
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCartView(context, grocery, recommendedCategories)
                : _buildFilledCartView(
                    context,
                    grocery,
                    cartItems,
                    remainingForFreeDelivery,
                    recommendedCategories,
                  ),
          ),
        ],
      ),
    );
  }

  // --- EMPTY CART VIEW WITH 2-3 CATEGORY RECOMMENDATIONS ---
  Widget _buildEmptyCartView(
    BuildContext context,
    GroceryProvider groceryProvider,
    Map<String, List<ProductModel>> recommendedCategories,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Empty State Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEEEEEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF4B8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      size: 34,
                      color: Color(0xFF19251B),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF19251B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Explore popular daily essentials below & tap ADD to start your quick 15-min delivery order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (onExploreGroceries != null) {
                        onExploreGroceries!();
                      } else {
                        Navigator.pushNamed(context, AppRoutes.home);
                      }
                    },
                    icon: const Icon(Icons.explore_outlined, size: 16),
                    label: const Text(
                      'Explore Full Catalogue',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19251B),
                      foregroundColor: const Color(0xFFF7C415),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2-3 Category Recommendations Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7C415).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Recommended for You',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF19251B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Render 2-3 Recommendation Categories
          ...recommendedCategories.entries.map((entry) {
            return _buildCategoryShelf(
              context,
              categoryName: entry.key,
              products: entry.value,
              groceryProvider: groceryProvider,
            );
          }),
        ],
      ),
    );
  }

  // --- FILLED CART VIEW WITH CART ITEMS + RECOMMENDATIONS BELOW ---
  Widget _buildFilledCartView(
    BuildContext context,
    GroceryProvider groceryProvider,
    Map<String, int> cartItems,
    double remainingForFreeDelivery,
    Map<String, List<ProductModel>> recommendedCategories,
  ) {
    return Column(
      children: [
        // Free delivery progress pill
        if (remainingForFreeDelivery > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.delivery_dining_rounded,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add ₹${remainingForFreeDelivery.toStringAsFixed(0)} more for FREE 15-min delivery!',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Color(0xFF15803D),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🎉 Congratulations! You have unlocked FREE Express Delivery.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Scrollable area containing Cart Items + Recommendations
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              // 1. Cart Items List Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(6, 4, 6, 8),
                      child: Text(
                        'Items in Your Cart',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF19251B),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ...cartItems.entries.map((entry) {
                      final product = groceryProvider.products.firstWhere(
                        (p) => p.id == entry.key,
                        orElse: () =>
                            FirestoreService.fallbackProducts.firstWhere(
                              (fp) => fp.id == entry.key,
                              orElse: () =>
                                  FirestoreService.fallbackProducts.first,
                            ),
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 52,
                                height: 52,
                                color: const Color(0xFFF9FAFB),
                                padding: const EdgeInsets.all(4),
                                child: FastCachedImage(
                                  imageUrl: product.imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: Color(0xFF19251B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.unit,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${(product.price * entry.value).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Compact quantity changer pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF19251B),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => groceryProvider.removeFromCart(
                                      product.id,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(
                                        Icons.remove,
                                        color: Color(0xFFF7C415),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '${entry.value}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        groceryProvider.addToCart(product.id),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(
                                        Icons.add,
                                        color: Color(0xFFF7C415),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Recommendations Header Below Cart Items
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7C415).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      size: 16,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Frequently Added Together',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF19251B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Render 2-3 Recommendation Categories
              ...recommendedCategories.entries.map((entry) {
                return _buildCategoryShelf(
                  context,
                  categoryName: entry.key,
                  products: entry.value,
                  groceryProvider: groceryProvider,
                );
              }),
            ],
          ),
        ),

        // Bottom Sticky Checkout Bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${groceryProvider.cartTotalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF19251B),
                      ),
                    ),
                  ],
                ),
                CustomPillButton(
                  text: 'Proceed to Checkout',
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.checkout);
                  },
                  backgroundColor: const Color(0xFFF7C415),
                  textColor: const Color(0xFF19251B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- HORIZONTAL CATEGORY SHELF ---
  Widget _buildCategoryShelf(
    BuildContext context, {
    required String categoryName,
    required List<ProductModel> products,
    required GroceryProvider groceryProvider,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();
    final emoji = _getCategoryEmoji(categoryName);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Title Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF19251B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${products.length} items',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Product Cards Scroll
          SizedBox(
            height: 215,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildRecommendationCard(
                  context,
                  product,
                  groceryProvider,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPACT RECOMMENDATION PRODUCT CARD WITH ADD BUTTON ---
  Widget _buildRecommendationCard(
    BuildContext context,
    ProductModel product,
    GroceryProvider groceryProvider,
  ) {
    final inCartQty = groceryProvider.getQuantity(product.id);
    final heroTag = 'hero_cart_rec_${product.id}';

    return InkWell(
      onTap: () {
        AppRoutes.navigateToProduct(context, product, heroTag: heroTag);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 145,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image thumbnail with Discount & Rating Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Container(
                    height: 104,
                    width: double.infinity,
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
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

                // Rating pill
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF7C415),
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${product.rating}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF19251B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Discount badge
                if (product.offPercentage > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.offPercentage}% OFF',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF19251B),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          product.unit,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    // Price & ADD Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF19251B),
                              ),
                            ),
                            if (product.mrp > product.price)
                              Text(
                                '₹${product.mrp.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[400],
                                ),
                              ),
                          ],
                        ),

                        // Interactive ADD / Incrementer Button
                        if (inCartQty == 0)
                          GestureDetector(
                            onTap: () {
                              groceryProvider.addToCart(product.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7C415),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF7C415,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'ADD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF19251B),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF19251B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => groceryProvider.removeFromCart(
                                    product.id,
                                  ),
                                  child: const Icon(
                                    Icons.remove,
                                    color: Color(0xFFF7C415),
                                    size: 14,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    '$inCartQty',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      groceryProvider.addToCart(product.id),
                                  child: const Icon(
                                    Icons.add,
                                    color: Color(0xFFF7C415),
                                    size: 14,
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
