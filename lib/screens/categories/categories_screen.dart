import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/fast_cached_image.dart';

class CategoriesScreen extends ConsumerWidget {
  final VoidCallback? onSelectCategory;

  const CategoriesScreen({super.key, this.onSelectCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grocery = ref.watch(groceryProvider);
    final categories = grocery.categories
        .where((c) => c.id != 'all')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Explore All Categories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF19251B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${categories.length} Categories • Delivered in 10 mins',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF555555),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const CircleAvatar(
                          backgroundColor: Color(0xFF19251B),
                          child: Icon(
                            Icons.category_rounded,
                            color: Color(0xFFF7C415),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomSearchField(
                      hintText: 'Search categories or products...',
                      onChanged: (query) {
                        ref.read(groceryProvider).setSearchQuery(query);
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
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Categories Grid with Full-Bleed Cover Images & Bottom Shadow Scrim
          Expanded(
            child: categories.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF19251B),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.80,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final hasImage = category.imageUrl != null &&
                          category.imageUrl!.trim().isNotEmpty;

                      return GestureDetector(
                        onTap: () {
                          ref.read(groceryProvider).selectCategory(category.id);
                          if (onSelectCategory != null) {
                            onSelectCategory!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2D24),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // 1. Full-Bleed Cover Image (Spans 100% of Container)
                              Positioned.fill(
                                child: hasImage
                                    ? FastCachedImage(
                                        imageUrl: category.imageUrl!.trim(),
                                        fit: BoxFit.cover,
                                        errorWidget: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF2C3E30),
                                                Color(0xFF19251B),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              category.iconData,
                                              size: 32,
                                              color: const Color(0xFFF7C415),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF2C3E30),
                                              Color(0xFF19251B),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            category.iconData,
                                            size: 32,
                                            color: const Color(0xFFF7C415),
                                          ),
                                        ),
                                      ),
                              ),

                              // 2. Smooth Shadow Scrim at Bottom (for 100% Text Readability)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.0, 0.35, 0.65, 1.0],
                                      colors: [
                                        Colors.black.withValues(alpha: 0.0),
                                        Colors.black.withValues(alpha: 0.15),
                                        Colors.black.withValues(alpha: 0.70),
                                        Colors.black.withValues(alpha: 0.95),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 3. Crisp White Text Labels Positioned at Bottom
                              Positioned(
                                left: 6,
                                right: 6,
                                bottom: 8,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      category.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.15,
                                        letterSpacing: 0.1,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      category.itemCount,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFFF4B8),
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 4. Optional Dynamic Tag Badge (HOT, NEW, SALE)
                              if (category.tag != null &&
                                  category.tag!.trim().isNotEmpty)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7C415),
                                      borderRadius: BorderRadius.circular(5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      category.tag!.trim().toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF19251B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
