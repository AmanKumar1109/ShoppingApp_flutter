import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/share_service.dart';
import '../../widgets/fast_cached_image.dart';
import '../../widgets/floating_cart_bar.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  final String? heroTag;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.heroTag,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _activeImageIndex = 0;
  bool _isDescriptionExpanded = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grocery = ref.watch(groceryProvider);
    final auth = ref.watch(authProvider);

    // Sync product with latest list if available
    final currentProduct = grocery.products.firstWhere(
      (p) => p.id == widget.product.id,
      orElse: () => widget.product,
    );

    final inCartQty = grocery.getQuantity(currentProduct.id);
    final isWishlisted = auth.user?.isInWishlist(currentProduct.id) ?? false;
    final images = currentProduct.displayImages;

    // Filter Similar Products from same category (excluding active product)
    final similarProducts = grocery.products
        .where((p) =>
            p.id != currentProduct.id &&
            (p.category.toLowerCase() == currentProduct.category.toLowerCase() ||
                (currentProduct.subcategory.isNotEmpty &&
                    p.subcategory.toLowerCase() ==
                        currentProduct.subcategory.toLowerCase())))
        .take(10)
        .toList();

    // Filter Recommended Products from other categories
    final recommendedProducts = grocery.products
        .where((p) =>
            p.id != currentProduct.id &&
            p.category.toLowerCase() != currentProduct.category.toLowerCase())
        .take(10)
        .toList();

    // Best Sellers / Trending Products
    final bestSellers = grocery.products
        .where((p) =>
            p.id != currentProduct.id &&
            (p.isTrending || p.isDeal || p.rating >= 4.7))
        .take(10)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Sleek App Bar with multi-image gallery
              _buildSliverAppBar(currentProduct, images, isWishlisted),

              // 2. Main Details Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title, Unit, Brand & Pricing Card
                      _buildMainProductCard(currentProduct, inCartQty),

                      const SizedBox(height: 12),

                      // Delivery & Assurance Badges
                      _buildDeliveryAssuranceCard(),

                      const SizedBox(height: 12),

                      // Product Details, Highlights & Description
                      _buildDetailsAndHighlightsCard(currentProduct),

                      const SizedBox(height: 16),

                      // Shelf 1: Similar Products in Category
                      if (similarProducts.isNotEmpty) ...[
                        _buildShelfSection(
                          title: 'Similar from ${currentProduct.category}',
                          subtitle: 'Items frequently bought in this category',
                          products: similarProducts,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Shelf 2: Recommended For You
                      if (recommendedProducts.isNotEmpty) ...[
                        _buildShelfSection(
                          title: 'Recommended For You',
                          subtitle: 'Handpicked grocery essentials you might like',
                          products: recommendedProducts,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Shelf 3: Best Sellers
                      if (bestSellers.isNotEmpty) ...[
                        _buildShelfSection(
                          title: 'Best Sellers & Top Rated',
                          subtitle: 'Popular choices loved by customers',
                          products: bestSellers,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Cart Bar when items are in cart
          FloatingCartBar(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.home);
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIVER APP BAR WITH MULTI-IMAGE CAROUSEL & THUMBNAIL STRIP
  // -------------------------------------------------------------
  Widget _buildSliverAppBar(
    ProductModel product,
    List<String> images,
    bool isWishlisted,
  ) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF19251B),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        // Share Button (Opens Full Native Share Sheet)
        Builder(
          builder: (btnContext) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: Color(0xFF19251B),
                  ),
                  onPressed: () {
                    final box = btnContext.findRenderObject() as RenderBox?;
                    final origin = box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null;
                    ShareService.shareProduct(
                      product,
                      sharePositionOrigin: origin,
                    );
                  },
                ),
              ),
            );
          },
        ),

        // Wishlist Heart Toggle Button
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 12.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            child: IconButton(
              icon: Icon(
                isWishlisted
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 22,
                color: isWishlisted
                    ? const Color(0xFFE11D48)
                    : const Color(0xFF19251B),
              ),
              onPressed: () async {
                final auth = ref.read(authProvider);
                if (!auth.isLoggedIn) {
                  Navigator.pushNamed(context, AppRoutes.login);
                  return;
                }
                await auth.toggleWishlist(product.toMap()..['id'] = product.id);
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          child: Stack(
            children: [
              // Swipeable Image Carousel
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    _activeImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final imageWidget = Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 36),
                      child: FastCachedImage(
                        imageUrl: images[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );

                  // Animate the primary image with Hero transition
                  if (index == 0) {
                    return Hero(
                      tag: widget.heroTag ?? 'hero_product_${product.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: imageWidget,
                      ),
                    );
                  }

                  return imageWidget;
                },
              ),

              // Badges overlay (Discount % & BOGO / Trending)
              Positioned(
                top: 76,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.offPercentage > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0C831F), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${product.offPercentage}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    if (product.isBogo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BUY 1 GET 1 FREE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Dots indicator & Thumbnail Strip
              if (images.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      final isActive = index == _activeImageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF19251B)
                              : Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MAIN PRODUCT INFO CARD (PRICE, TITLE, QUANTITY CONTROLLER)
  // -------------------------------------------------------------
  Widget _buildMainProductCard(ProductModel product, int inCartQty) {
    final grocery = ref.read(groceryProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand pill & Rating row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (product.brand.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFF7C415).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    product.brand.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),

              // Rating pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C831F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF0C831F),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.rating}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0C831F),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${product.reviewsCount})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Product Title
          Text(
            product.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 6),

          // Unit / Pack size
          Text(
            product.unit,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),

          // Price & Add to Cart Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price Block
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (product.mrp > product.price) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${product.mrp.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.savingsAmount > 0)
                    Text(
                      'You save ₹${product.savingsAmount.toStringAsFixed(0)} (${product.offPercentage}% OFF)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0C831F),
                      ),
                    )
                  else
                    Text(
                      'Inclusive of all taxes',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),

              // Add to Cart Button or Quantity Controller
              if (inCartQty == 0)
                InkWell(
                  onTap: () {
                    grocery.addToCart(product.id);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF8C616), Color(0xFFF7B900)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF8C616).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 18,
                          color: Color(0xFF111827),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'ADD',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C831F),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0C831F).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          grocery.removeFromCart(product.id);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$inCartQty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        constraints: const BoxConstraints(),
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
    );
  }

  // -------------------------------------------------------------
  // DELIVERY & ASSURANCE BADGES
  // -------------------------------------------------------------
  Widget _buildDeliveryAssuranceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          // 10 Mins Delivery Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF19251B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFF7C415),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '10 MINS SUPERFAST DELIVERY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF19251B),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Direct from GroceryHub local dark store in your area',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // 3 Assurance Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFeaturePill(
                icon: Icons.verified_user_outlined,
                title: '100% Genuine',
              ),
              _buildFeaturePill(
                icon: Icons.eco_outlined,
                title: 'Quality Checked',
              ),
              _buildFeaturePill(
                icon: Icons.published_with_changes_rounded,
                title: 'Easy Replacement',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required String title,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF0C831F)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // PRODUCT HIGHLIGHTS & DESCRIPTION CARD
  // -------------------------------------------------------------
  Widget _buildDetailsAndHighlightsCard(ProductModel product) {
    // Dynamic fallback description handling
    final descText = (product.description.isNotEmpty)
        ? product.description
        : 'Fresh and premium ${product.title} sourced directly and hygienically packed for maximum freshness.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),

          // Description with Read More / Less toggle
          Text(
            descText,
            maxLines: _isDescriptionExpanded ? 100 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.45,
            ),
          ),

          if (descText.length > 120) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                _isDescriptionExpanded ? 'Read Less' : 'Read More',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0C831F),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Category & Subcategory tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTagChip(Icons.category_outlined, product.category),
              if (product.subcategory.isNotEmpty)
                _buildTagChip(Icons.label_outline, product.subcategory),
              _buildTagChip(Icons.scale_outlined, product.unit),
              if (product.tags.isNotEmpty)
                ...product.tags.map((t) => _buildTagChip(Icons.tag, t)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6B7280)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HORIZONTAL SHELF SECTION
  // -------------------------------------------------------------
  Widget _buildShelfSection({
    required String title,
    required String subtitle,
    required List<ProductModel> products,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF152C1E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 245,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Container(
                width: 162,
                margin: const EdgeInsets.only(right: 12),
                child: _buildShelfProductCard(products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShelfProductCard(ProductModel product) {
    final grocery = ref.watch(groceryProvider);
    final inCartQty = grocery.getQuantity(product.id);

    return InkWell(
      onTap: () {
        AppRoutes.navigateToProduct(
          context,
          product,
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.1),
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
            // Image with Discount Tag
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17),
                  ),
                  child: SizedBox(
                    height: 115,
                    width: double.infinity,
                    child: FastCachedImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (product.offPercentage > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.offPercentage}% OFF',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Info & Price & Add button
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(9),
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF152C1E),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.unit,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
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
                              '₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF152C1E),
                              ),
                            ),
                            if (product.mrp > product.price)
                              Text(
                                '₹${product.mrp.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),

                        // Quick +/- or Add button
                        if (inCartQty == 0)
                          GestureDetector(
                            onTap: () {
                              grocery.addToCart(product.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
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
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C831F),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => grocery.removeFromCart(product.id),
                                  child: const Icon(
                                    Icons.remove,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(
                                    '$inCartQty',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => grocery.addToCart(product.id),
                                  child: const Icon(
                                    Icons.add,
                                    size: 13,
                                    color: Colors.white,
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
