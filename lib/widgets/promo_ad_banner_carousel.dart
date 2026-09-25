import 'dart:async';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'fast_cached_image.dart';

class PromoAdBannerItem {
  final String title;
  final String subtitle;
  final String brandBadge;
  final String buttonText;
  final String imageUrl;
  final List<Color> gradientColors;
  final String targetTitle;
  final String sectionType;
  final String? categoryId;
  final String? searchTerm;

  const PromoAdBannerItem({
    required this.title,
    required this.subtitle,
    required this.brandBadge,
    required this.buttonText,
    required this.imageUrl,
    required this.gradientColors,
    required this.targetTitle,
    required this.sectionType,
    this.categoryId,
    this.searchTerm,
  });
}

class PromoAdBannerCarousel extends StatefulWidget {
  const PromoAdBannerCarousel({super.key});

  @override
  State<PromoAdBannerCarousel> createState() => _PromoAdBannerCarouselState();
}

class _PromoAdBannerCarouselState extends State<PromoAdBannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 1;
  Timer? _autoScrollTimer;

  static const List<PromoAdBannerItem> _banners = [
    PromoAdBannerItem(
      title: 'Surf Excel\nMatic',
      subtitle: 'Tough stain removal\nin 1 single wash',
      brandBadge: 'Surf\nexcel',
      buttonText: 'Shop now',
      imageUrl:
          'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=600&auto=format&fit=crop',
      gradientColors: [
        Color(0xFF0D47A1),
        Color(0xFF092E6B),
        Color(0xFF04193E),
      ],
      targetTitle: 'Surf & Detergent Cleaners',
      sectionType: 'all',
      searchTerm: 'surf',
      categoryId: 'cat_cleaning',
    ),
    PromoAdBannerItem(
      title: 'Cadbury\nbrownie',
      subtitle: 'Gooey, fudgy &\nchocolatey',
      brandBadge: 'Cadbury\nBROWNIE',
      buttonText: 'Shop now',
      imageUrl:
          'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600&auto=format&fit=crop',
      gradientColors: [
        Color(0xFF5B1082),
        Color(0xFF3F0B5C),
        Color(0xFF28033E),
      ],
      targetTitle: 'Cadbury Brownies & Chocolates',
      sectionType: 'all',
      searchTerm: 'brownie',
      categoryId: 'cat_bakery',
    ),
    PromoAdBannerItem(
      title: 'Save Up To 30%\nThis Weekend',
      subtitle: 'Mega grocery sale on\nfresh daily essentials',
      brandBadge: 'WEEKEND\nDEAL',
      buttonText: 'Explore all products',
      imageUrl:
          'https://cdn.pixabay.com/photo/2018/01/25/08/14/beverages-3105631_960_720.jpg',
      gradientColors: [
        Color(0xFF8B2500),
        Color(0xFF6E1800),
        Color(0xFF4A0E00),
      ],
      targetTitle: 'All Products & Categories',
      sectionType: 'all',
      searchTerm: null,
    ),
    PromoAdBannerItem(
      title: 'Dairy Milk\nSilk',
      subtitle: 'Have you felt the\nrichness yet?',
      brandBadge: 'Cadbury\nSILK',
      buttonText: 'Explore now',
      imageUrl:
          'https://images.unsplash.com/photo-1548741487-18d968602274?w=600&auto=format&fit=crop',
      gradientColors: [
        Color(0xFF7B1144),
        Color(0xFF53092C),
        Color(0xFF35041A),
      ],
      targetTitle: 'Cadbury Silk & Chocolates',
      sectionType: 'all',
      searchTerm: 'dairy milk',
      categoryId: 'cat_bakery',
    ),
    PromoAdBannerItem(
      title: 'Farm Fresh\nDairy',
      subtitle: 'Pure milk, butter &\nartisanal paneer',
      brandBadge: 'Amul\nDAIRY',
      buttonText: 'Order now',
      imageUrl:
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=600&auto=format&fit=crop',
      gradientColors: [
        Color(0xFF0F766E),
        Color(0xFF115E59),
        Color(0xFF134E4A),
      ],
      targetTitle: 'Fresh Dairy & Milk',
      sectionType: 'all',
      searchTerm: 'dairy',
      categoryId: 'cat_dairy_bread',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Start carousel at the 2nd card (index 1) so left & right cards peek into view
    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: 1,
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_pageController.hasClients &&
          _pageController.positions.isNotEmpty &&
          _pageController.position.haveDimensions) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (idx) {
              setState(() {
                _currentPage = idx;
              });
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: _buildBannerCard(banner),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4.5,
              width: _currentPage == index ? 20 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF19251B)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(PromoAdBannerItem banner) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.catalog,
          arguments: {
            'title': banner.targetTitle,
            'sectionType': banner.sectionType,
            'categoryId': banner.categoryId,
            'searchTerm': banner.searchTerm,
          },
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: banner.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Right Side Product Photo with smooth gradient blend
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              width: 175,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FastCachedImage(
                      imageUrl: banner.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            banner.gradientColors.first,
                            banner.gradientColors.first.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top Right Circular Brand Badge
            Positioned(
              top: 14,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  banner.brandBadge,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // Left Content: Title, Subtitle, "Shop now" button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 140, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        banner.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),

                  // "Shop now" Pill Button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      banner.buttonText,
                      style: const TextStyle(
                        color: Color(0xFF19251B),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Right "Ad" Badge
            Positioned(
              bottom: 12,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Ad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
