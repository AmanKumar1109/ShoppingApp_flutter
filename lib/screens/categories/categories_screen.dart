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
      backgroundColor: Colors.white,
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
                  Colors.white,
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

          // Categories Grid with Real Cover Images & Badges
          Expanded(
            child: categories.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF19251B),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFF0F2F5),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Full-width centered container to ensure 100% mathematical center alignment
                              SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Category Cover Image (Strictly Centered)
                                      Center(
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF9E5),
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: const Color(0xFFFFF0B3),
                                              width: 1,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: hasImage
                                                ? FastCachedImage(
                                                    imageUrl: category.imageUrl!.trim(),
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    errorWidget: Center(
                                                      child: Icon(
                                                        category.iconData,
                                                        size: 26,
                                                        color: const Color(0xFF19251B),
                                                      ),
                                                    ),
                                                  )
                                                : Center(
                                                    child: Icon(
                                                      category.iconData,
                                                      size: 26,
                                                      color: const Color(0xFF19251B),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          category.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF19251B),
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          category.itemCount,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF007A3D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Optional Dynamic Tag Badge (e.g. HOT, NEW, SALE)
                              if (category.tag != null &&
                                  category.tag!.trim().isNotEmpty)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7C415),
                                      borderRadius: BorderRadius.circular(5),
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
