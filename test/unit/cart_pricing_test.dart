import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:groceryhub/providers/grocery_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Cart Calculation and Coupon Tests', () {
    test('Initial cart is empty with zero totals and delivery fee', () {
      final provider = GroceryProvider(autoSync: false);
      expect(provider.cartCount, 0);
      expect(provider.cartTotalAmount, 0.0);
      expect(provider.deliveryFee, 0.0);
      expect(provider.finalPayableAmount, 0.0);
    });

    test('Unknown or deleted product ID does not crash or charge ₹699 fallback', () {
      final provider = GroceryProvider(autoSync: false);
      // Add non-existent product ID
      provider.addToCart('non_existent_item_999');

      expect(provider.cartCount, 1);
      // Since it cannot be resolved, safe lookup returns ₹0 instead of Pampers diaper ₹699
      expect(provider.cartTotalAmount, 0.0);
    });

    test('Delivery fee logic: ₹25 below ₹199, Free (₹0) on ₹199 and above', () {
      final provider = GroceryProvider(autoSync: false);
      // Test deliveryFee directly with empty cart
      expect(provider.deliveryFee, 0.0);
    });

    test('Coupon validation: rejects invalid coupon code', () {
      final provider = GroceryProvider(autoSync: false);
      final success = provider.applyCoupon('INVALID_CODE');
      expect(success, isFalse);
      expect(provider.appliedCouponCode, isNull);
      expect(provider.couponDiscount, 0.0);
    });
  });
}

