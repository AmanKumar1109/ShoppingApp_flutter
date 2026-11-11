import 'dart:async';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/firestore_service.dart';
import 'fast_cached_image.dart';

class PromoAdBannerItem {
  final String title;
  final String subtitle;
  final String buttonText;
  final String imageUrl;
  final List<Color> gradientColors;
  final Color accentColor;
  final String targetTitle;
  final String sectionType;
  final String? categoryId;
  final String? searchTerm;

  const PromoAdBannerItem({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.imageUrl,
    required this.gradientColors,
    required this.accentColor,
    required this.targetTitle,
    required this.sectionType,
    this.categoryId,
    this.searchTerm,
  });

  factory PromoAdBannerItem.fromMap(Map<String, dynamic> data) {
    List<Color> parseGradient(dynamic val) {
      if (val is List && val.isNotEmpty) {
        final colors = <Color>[];
        for (final c in val) {
          if (c is int) {
            colors.add(Color(c));
          } else if (c is String) {
            final clean = c.replaceAll('#', '').trim();
            final intVal = int.tryParse(
              clean.length == 6 ? 'FF$clean' : clean,
              radix: 16,
            );
            if (intVal != null) {
              colors.add(Color(intVal));
            }
          }
        }
        if (colors.length >= 2) return colors;
      }
      return const [
        Color(0xFF1E3A8A),
        Color(0xFF1D4ED8),
        Color(0xFF0F172A),
      ];
    }

    Color parseAccent(dynamic val) {
      if (val is int) return Color(val);
      if (val is String) {
        final clean = val.replaceAll('#', '').trim();
        final intVal = int.tryParse(
          clean.length == 6 ? 'FF$clean' : clean,
          radix: 16,
        );
        if (intVal != null) return Color(intVal);
      }
      return const Color(0xFF3B82F6);
    }

    return PromoAdBannerItem(
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      buttonText: (data['buttonText'] ?? 'Shop now').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      gradientColors: parseGradient(data['gradientColors']),
      accentColor: parseAccent(data['accentColor']),
      targetTitle: (data['targetTitle'] ?? 'Products').toString(),
      sectionType: (data['sectionType'] ?? 'all').toString(),
      categoryId: data['categoryId']?.toString(),
      searchTerm: data['searchTerm']?.toString(),
    );
  }
}

class PromoAdBannerCarousel extends StatefulWidget {
  const PromoAdBannerCarousel({super.key});

  @override
  State<PromoAdBannerCarousel> createState() => _PromoAdBannerCarouselState();
}

class _PromoAdBannerCarouselState extends State<PromoAdBannerCarousel> {
  static const int _kLoopFactor = 1000;
  late final PageController _pageController;
  late final int _initialVirtualPage;

  int _currentBannerIndex = 0;
  Timer? _autoScrollTimer;
  StreamSubscription? _bannerSubscription;
  bool _isUserInteracting = false;
  late List<PromoAdBannerItem> _banners;

  static const List<PromoAdBannerItem> _defaultBanners = [
    PromoAdBannerItem(
      title: 'Surf Excel\nMatic Liquid',
      subtitle: 'Tough stain removal in 1 wash',
      buttonText: 'Shop now',
      imageUrl:
          'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=700&auto=format&fit=crop',
      gradientColors: [
        Color(0xFF1E3A8A),
        Color(0xFF1D4ED8),
        Color(0xFF0F172A),
      ],
      accentColor: Color(0xFF3B82F6),
      targetTitle: 'Surf & Detergent Cleaners',
      sectionType: 'all',
      searchTerm: 'surf',
      categoryId: 'cat_cleaning',
    ),
    PromoAdBannerItem(
      title: 'Cadbury Rich\nFudge Brownie',
      subtitle: 'Gooey, decadent & fresh baked',
      buttonText: 'Order fresh',
      imageUrl:
          'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=700&auto=format&fit=crop',
      gradientColors: [
        Color(0xFF581C87),
        Color(0xFF3B0764),
        Color(0xFF1E0130),
      ],
      accentColor: Color(0xFFA855F7),
      targetTitle: 'Cadbury Brownies & Chocolates',
      sectionType: 'all',
      searchTerm: 'brownie',
      categoryId: 'cat_bakery',
    ),
    PromoAdBannerItem(
      title: 'Weekend Super\nGrocery Saver',
      subtitle: 'Up to 30% OFF on daily essentials',
      buttonText: 'Explore deals',
      imageUrl:
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=700&auto=format&fit=crop',
      gradientColors: [
        Color(0xFF9A3412),
        Color(0xFF7C2D12),
        Color(0xFF431407),
      ],
      accentColor: Color(0xFFF97316),
      targetTitle: 'All Products & Categories',
      sectionType: 'all',
      searchTerm: null,
    ),
    PromoAdBannerItem(
      title: 'Dairy Milk\nSilk Chocolate',
      subtitle: 'Silky smooth, velvety pure delight',
      buttonText: 'Shop treat',
      imageUrl:
          'https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=700&auto=format&fit=crop',
      gradientColors: [
        Color(0xFF831843),
        Color(0xFF701A75),
        Color(0xFF3B0764),
      ],
      accentColor: Color(0xFFEC4899),
      targetTitle: 'Cadbury Silk & Chocolates',
      sectionType: 'all',
      searchTerm: 'dairy milk',
      categoryId: 'cat_bakery',
    ),
    PromoAdBannerItem(
      title: 'Farm Fresh\nDaily Dairy',
      subtitle: 'Pure cow milk, butter & paneer',
      buttonText: 'Order now',
      imageUrl:
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=700&auto=format&fit=crop',
      gradientColors: [
        Color(0xFF065F46),
        Color(0xFF044E3A),
        Color(0xFF022C22),
      ],
      accentColor: Color(0xFF10B981),
      targetTitle: 'Fresh Dairy & Milk',
      sectionType: 'all',
      searchTerm: 'dairy',
      categoryId: 'cat_dairy_bread',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _banners = List.from(_defaultBanners);
    _initialVirtualPage = (_kLoopFactor ~/ 2) * _banners.length;
    _pageController = PageController(
      viewportFraction: 0.90,
      initialPage: _initialVirtualPage,
    );
    _startAutoScroll();

    _bannerSubscription =
        FirestoreService().streamAppBanners().listen((rawList) {
      if (!mounted) return;
      if (rawList == null) {
        // Firestore collection not created yet, keep default banners
        return;
      }
      final parsed =
          rawList.map((m) => PromoAdBannerItem.fromMap(m)).toList();
      setState(() {
        _banners = parsed;
        if (_banners.isNotEmpty) {
          _currentBannerIndex = _currentBannerIndex % _banners.length;
        } else {
          _currentBannerIndex = 0;
        }
      });
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 4200), (timer) {
      if (!mounted || _isUserInteracting) return;
      if (_pageController.hasClients &&
          _pageController.positions.isNotEmpty &&
          _pageController.position.haveDimensions) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _pauseAutoScroll() {
    _isUserInteracting = true;
    _autoScrollTimer?.cancel();
  }

  void _resumeAutoScroll() {
    _isUserInteracting = false;
    _startAutoScroll();
  }

  void _animateToBanner(int targetIndex) {
    if (!_pageController.hasClients) return;
    final currentVirtual = _pageController.page?.round() ?? _initialVirtualPage;
    final currentMod = currentVirtual % _banners.length;
    final diff = targetIndex - currentMod;
    _pageController.animateToPage(
      currentVirtual + diff,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _bannerSubscription?.cancel();
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 3D PARALLAX CAROUSEL VIEWPORT ──
        SizedBox(
          height: 195,
          child: Listener(
            onPointerDown: (_) => _pauseAutoScroll(),
            onPointerUp: (_) => _resumeAutoScroll(),
            onPointerCancel: (_) => _resumeAutoScroll(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length * _kLoopFactor,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (virtualIndex) {
                final realIndex = virtualIndex % _banners.length;
                if (_currentBannerIndex != realIndex) {
                  setState(() {
                    _currentBannerIndex = realIndex;
                  });
                }
              },
              itemBuilder: (context, index) {
                final banner = _banners[index % _banners.length];

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double pageOffset = 0.0;
                    if (_pageController.position.haveDimensions) {
                      pageOffset = index - (_pageController.page ?? _initialVirtualPage.toDouble());
                    } else {
                      pageOffset = (index == _initialVirtualPage) ? 0.0 : 1.0;
                    }

                    // Smooth subtle depth scaling for inactive adjacent cards
                    final double scale = (1.0 - (pageOffset.abs() * 0.07)).clamp(0.92, 1.0);
                    final double opacity = (1.0 - (pageOffset.abs() * 0.25)).clamp(0.80, 1.0);

                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: _buildBannerCard(banner),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── AESTHETIC EXPANDED PILL INDICATORS ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) {
              final isCurrent = _currentBannerIndex == index;
              final activeColor = _banners[_currentBannerIndex].accentColor;

              return GestureDetector(
                onTap: () => _animateToBanner(index),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    height: 5,
                    width: isCurrent ? 26 : 6,
                    decoration: BoxDecoration(
                      gradient: isCurrent
                          ? LinearGradient(
                              colors: [
                                activeColor,
                                const Color(0xFFF7C415),
                              ],
                            )
                          : null,
                      color: isCurrent ? null : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 1.5),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(PromoAdBannerItem banner) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: banner.accentColor.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
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
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Unified Rich Card Gradient Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: banner.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
              ),

              // 2. Ambient Lighting Halo Behind Product Showcase Pod
              Positioned(
                right: 8,
                top: 15,
                bottom: 15,
                width: 150,
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          banner.accentColor.withValues(alpha: 0.50),
                          banner.accentColor.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Subtle background geometric ambient ring for depth
              Positioned(
                top: -35,
                right: 75,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 24,
                    ),
                  ),
                ),
              ),

              // 4. CLEAN 3D FLOATING PRODUCT SHOWCASE POD
              Positioned(
                right: 18,
                top: 20,
                bottom: 20,
                width: 130,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: banner.accentColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FastCachedImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                      ),
                      // Gentle top-down ambient gloss
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.18),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.20),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.40, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Clean, Editorial Left Content Area (No Clutter, High Legibility)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 160, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Headings: Title & Subtitle with plenty of breathing room
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          banner.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),

                    // Modern Floating CTA Pill with Arrow Badge
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            banner.buttonText,
                            style: const TextStyle(
                              color: Color(0xFF19251B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF19251B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 10,
                              color: Color(0xFFF7C415),
                            ),
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
      ),
    );
  }
}
