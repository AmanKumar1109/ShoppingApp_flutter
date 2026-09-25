import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/grocery_provider.dart';
import '../utils/constants.dart';

class FloatingCartBar extends ConsumerWidget {
  final VoidCallback onTap;

  const FloatingCartBar({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grocery = ref.watch(groceryProvider);

    if (grocery.cartCount == 0) {
      return const SizedBox.shrink();
    }

    String? firstItemImageUrl;
    if (grocery.cartItems.isNotEmpty) {
      final firstId = grocery.cartItems.keys.first;
      final match = grocery.products.firstWhere(
        (p) => p.id == firstId,
        orElse: () => grocery.products.first,
      );
      firstItemImageUrl = match.imageUrl;
    }

    return Positioned(
      bottom: 20,
      left: 55,
      right: 55,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFACC15), // Soft pastel yellow
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFACC15).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Product thumbnail preview circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: firstItemImageUrl != null
                      ? Image.network(
                          firstItemImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.shopping_bag,
                            color: Color(0xFF19251B),
                            size: 16,
                          ),
                        )
                      : const Icon(
                          Icons.shopping_bag,
                          color: Color(0xFF19251B),
                          size: 16,
                        ),
                ),
              ),
              const SizedBox(width: 8),

              // View Cart & Item Count Text
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'View cart',
                      style: TextStyle(
                        color: Color(0xFF19251B),
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      '${grocery.cartCount} ${grocery.cartCount == 1 ? 'item' : 'items'} • ${AppConstants.currencySymbol}${grocery.cartTotalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: const Color(0xFF19251B).withValues(alpha: 0.75),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron Right Icon
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF19251B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF19251B),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
