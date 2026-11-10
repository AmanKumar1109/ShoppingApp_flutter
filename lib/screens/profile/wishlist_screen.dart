import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/fast_cached_image.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final grocery = ref.watch(groceryProvider);
    final user = auth.user;
    final wishlist = user?.wishlist ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF4B8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF19251B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'My Wishlist',
              style: TextStyle(
                color: Color(0xFF19251B),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            if (wishlist.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF19251B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${wishlist.length}',
                  style: const TextStyle(
                    color: Color(0xFFF7C415),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          if (wishlist.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                for (final item in wishlist) {
                  final id = item['id']?.toString() ?? '';
                  if (id.isNotEmpty) {
                    grocery.addToCart(id);
                  }
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${wishlist.length} items to cart!'),
                    backgroundColor: const Color(0xFF19251B),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.shopping_cart_outlined,
                size: 16,
                color: Color(0xFF19251B),
              ),
              label: const Text(
                'Add All',
                style: TextStyle(
                  color: Color(0xFF19251B),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: wishlist.isEmpty
          ? _buildEmptyWishlist(context)
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final item = wishlist[index];
                return _buildWishlistItem(context, item, auth, grocery, index: index);
              },
            ),
    );
  }

  Widget _buildEmptyWishlist(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF4B8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 54,
                color: Color(0xFF19251B),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Wishlist is Empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF19251B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save your favorite grocery items and essentials to easily order them anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.catalog,
                    arguments: {
                      'title': 'Explore Products',
                      'sectionType': 'all',
                    },
                  );
                },
                icon: const Icon(Icons.shopping_basket_outlined, size: 18),
                label: const Text(
                  'Explore Groceries',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
    );
  }

  Widget _buildWishlistItem(
    BuildContext context,
    Map<String, dynamic> item,
    AuthProvider auth,
    GroceryProvider grocery, {
    int? index,
  }) {
    final id = item['id']?.toString() ?? '';
    final name = item['name'] ?? item['title'] ?? 'Product';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final originalPrice = (item['originalPrice'] ?? item['mrp'] as num?)
        ?.toDouble();
    final unit = item['unit']?.toString() ?? '1 unit';
    final imageUrl = item['image'] ?? item['imageUrl'] ?? '';
    final inCartQty = grocery.getQuantity(id);
    final heroTag = index != null
        ? 'hero_wishlist_${id}_$index'
        : 'hero_wishlist_$id';

    return InkWell(
      onTap: () {
        final product = grocery.products.firstWhere(
          (p) => p.id == id,
          orElse: () => ProductModel.fromMap(item, id),
        );
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
          border: Border.all(color: const Color(0xFFEEEEEE)),
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
          // Image & Remove Button
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
                child: Container(
                  height: 110,
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
                      child: imageUrl.isNotEmpty
                          ? FastCachedImage(imageUrl: imageUrl, fit: BoxFit.contain)
                          : Container(color: const Color(0xFFFFF4B8)),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => auth.toggleWishlist(item),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
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
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF152C1E),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unit,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF152C1E),
                            ),
                          ),
                          if (originalPrice != null && originalPrice > price)
                            Text(
                              '₹${originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),

                      if (inCartQty == 0)
                        GestureDetector(
                          onTap: () {
                            if (id.isNotEmpty) grocery.addToCart(id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7C415),
                              borderRadius: BorderRadius.circular(14),
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
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF19251B),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => grocery.removeFromCart(id),
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => grocery.addToCart(id),
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
