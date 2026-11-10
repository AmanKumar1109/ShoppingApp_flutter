import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../providers/grocery_provider.dart';
import '../routes/app_routes.dart';
import 'fast_cached_image.dart';

class GroceryGrandDealsSection extends ConsumerWidget {
  const GroceryGrandDealsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grocery = ref.watch(groceryProvider);

    // Find a real high-value deal product from grocery provider or use fallback
    ProductModel? featuredProduct;
    if (grocery.products.isNotEmpty) {
      featuredProduct = grocery.products.firstWhere(
        (p) => p.isDeal && p.offPercentage >= 20,
        orElse: () => grocery.products.first,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFF9F2),
              Color(0xFFF9EFE2),
              Color(0xFFF5E6D3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: const Color(0xFFECD8C1),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SECTION HEADER: "THE Grocery DEALS"
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'THE ',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4A3427),
                      letterSpacing: 3.0,
                    ),
                  ),
                  Text(
                    'Grocery',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8B1E3F),
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    ' DEALS',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4A3427),
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. MAIN 2-COLUMN SECTION (Tall Left Card + 2x2 Right Grid)
            SizedBox(
              height: 290,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- LEFT TALL FEATURED TOP DEAL CARD ---
                  Expanded(
                    flex: 42,
                    child: _buildTallFeaturedCard(
                      context,
                      featuredProduct,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // --- RIGHT 2x2 CATEGORY DEALS GRID ---
                  Expanded(
                    flex: 58,
                    child: Column(
                      children: [
                        // Row 1: Dry Fruits & Oils/Ghee
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSmallDealCard(
                                  context: context,
                                  discountTag: 'Up to 50% OFF',
                                  title: 'Dry Fruits\n& Nuts',
                                  imageUrl:
                                      'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&auto=format&fit=crop',
                                  targetCategory: 'cat_snacks_munchies',
                                  targetTitle: 'Dry Fruits & Nuts',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSmallDealCard(
                                  context: context,
                                  discountTag: 'Up to 45% OFF',
                                  title: 'Oils, Ghee\n& Spices',
                                  imageUrl:
                                      'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&auto=format&fit=crop',
                                  targetCategory: 'cat_oil_masala',
                                  targetTitle: 'Oil, Ghee & Masala',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Row 2: Breakfast Cereals & Best Brand Offers
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSmallDealCard(
                                  context: context,
                                  discountTag: 'Up to 40% OFF',
                                  title: 'Breakfast\n& Cereals',
                                  imageUrl:
                                      'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=400&auto=format&fit=crop',
                                  targetCategory: 'cat_snacks_munchies',
                                  targetTitle: 'Breakfast & Cereals',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildBestBrandOffersCard(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. BOTTOM 2 HORIZONTAL DEAL PILLS
            Row(
              children: [
                Expanded(
                  child: _buildBottomDealPill(
                    context: context,
                    leadingWidget: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: FastCachedImage(
                          imageUrl:
                              'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=200&auto=format&fit=crop',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: 'BUY 2 AT ₹299',
                    subtitle: 'on Dry Fruits & Snacks',
                    targetTitle: 'Buy 2 Specials',
                    sectionType: 'trending',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBottomDealPill(
                    context: context,
                    leadingWidget: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    title: 'Min 40% OFF',
                    subtitle: 'on Gourmet Essentials',
                    targetTitle: 'Gourmet Essentials',
                    sectionType: 'deals',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TALL LEFT FEATURED TOP DEAL CARD ---
  Widget _buildTallFeaturedCard(
    BuildContext context,
    ProductModel? product,
  ) {
    const defaultImg =
        'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&auto=format&fit=crop';
    final title = product?.title ?? 'Royal Basmati Rice & Ghee';
    final price = product?.price ?? 549.0;
    final mrp = product?.mrp ?? 899.0;
    final imageUrl = product?.imageUrl ?? defaultImg;

    return InkWell(
      onTap: () {
        if (product != null) {
          AppRoutes.navigateToProduct(
            context,
            product,
            heroTag: 'hero_grand_deals_${product.id}',
          );
        } else {
          Navigator.pushNamed(
            context,
            AppRoutes.catalog,
            arguments: {
              'title': 'Top Grocery Deals',
              'sectionType': 'deals',
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3E7D8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE8D4BE),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "TOP DEALS" Heading Badge
            const Text(
              'TOP\nDEALS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                color: Color(0xFF7A1832),
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Price Tag Pill: Strikethrough MRP + Sale Price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4E3D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${mrp.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Short Product Title
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B1F17),
                height: 1.15,
              ),
            ),

            const Spacer(),

            // Product Image at Bottom
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 110,
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(6),
                child: Hero(
                  tag: 'hero_grand_deals_${product?.id ?? "featured"}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: FastCachedImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SMALL 2x2 DEAL CARD ---
  Widget _buildSmallDealCard({
    required BuildContext context,
    required String discountTag,
    required String title,
    required String imageUrl,
    required String targetCategory,
    required String targetTitle,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.catalog,
          arguments: {
            'title': targetTitle,
            'categoryId': targetCategory,
            'sectionType': 'deals',
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3E7D8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8D4BE),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Discount Tag Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4A3427),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                discountTag,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
            ),

            const SizedBox(height: 3),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B1F17),
                height: 1.1,
              ),
            ),

            const Spacer(),

            // Image Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 54,
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(4),
                child: FastCachedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BEST BRAND OFFERS CARD ---
  Widget _buildBestBrandOffersCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.catalog,
          arguments: {
            'title': 'Best Brand Offers',
            'sectionType': 'deals',
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEADBCA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE0CDB8),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'BEST BRAND',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B4E3D),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'OFFERS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7A1832),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: const Color(0xFF7A1832).withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BOTTOM HORIZONTAL DEAL PILL ---
  Widget _buildBottomDealPill({
    required BuildContext context,
    required Widget leadingWidget,
    required String title,
    required String subtitle,
    required String targetTitle,
    required String sectionType,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.catalog,
          arguments: {
            'title': targetTitle,
            'sectionType': sectionType,
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFB58E6B),
              Color(0xFFA17855),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            leadingWidget,
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
