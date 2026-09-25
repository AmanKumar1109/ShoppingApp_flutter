import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_textfield.dart';

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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore All Categories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF19251B),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Fresh groceries delivered in 10 mins',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF555555),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
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

          const SizedBox(height: 8),

          // Categories Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.76,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
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
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF4B8),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              category.iconData,
                              size: 26,
                              color: const Color(0xFF19251B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
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
                        const SizedBox(height: 3),
                        Text(
                          category.itemCount,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFB88600),
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
