import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class ShareService {
  /// Opens the full native system share panel to share a grocery product
  static Future<void> shareProduct(
    ProductModel product, {
    Rect? sharePositionOrigin,
  }) async {
    final discountStr = product.offPercentage > 0
        ? ' (${product.offPercentage}% OFF - Save ₹${(product.mrp - product.price).toStringAsFixed(0)})'
        : '';

    final text = '''
🛒 *${product.title}* on The Grocery Hub!

💰 Price: ₹${product.price.toStringAsFixed(0)} (MRP: ₹${product.mrp.toStringAsFixed(0)}$discountStr)
📦 Unit: ${product.unit}
⭐ Rating: ${product.rating} ★ (${product.reviewsCount}+ reviews)

⚡ Superfast 10-15 minute grocery delivery to your doorstep in Baharagora!
👉 Order here: https://thegroceryhub.in/product/${product.id}
''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Buy ${product.title} on The Grocery Hub',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// Opens the full native system share panel for referral codes
  static Future<void> shareReferral(
    String referralCode, {
    Rect? sharePositionOrigin,
  }) async {
    final cleanCode = referralCode.trim().toUpperCase();
    final text = '''
🎁 Get *₹50 OFF* on your first grocery order with *The Grocery Hub*!

Use my referral code: *$cleanCode*

🚚 Fresh Vegetables, Dairy, Snacks, Atta, Rice & Essentials delivered in 10-15 minutes in Baharagora.
👉 Download and order now: https://thegroceryhub.in/?ref=$cleanCode
''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Get ₹50 OFF on The Grocery Hub',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// Opens the full native system share panel to share live order tracking
  static Future<void> shareOrder(
    OrderModel order, {
    Rect? sharePositionOrigin,
  }) async {
    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    final text = '''
🛍️ My Grocery Hub order (#$shortId) is placed!

📦 Items: ${order.items.length} products
💰 Total Amount: ₹${order.totalAmount.toStringAsFixed(0)}
🛵 Fast 15-minute express delivery to Baharagora.

👉 Track order live: https://thegroceryhub.in/track/${order.id}
''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'My Grocery Hub Order #$shortId',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// Opens the full native system share panel to invite friends
  static Future<void> shareApp({Rect? sharePositionOrigin}) async {
    const text = '''
🛒 *The Grocery Hub* - Superfast 10-15 Minute Grocery Delivery!

Order fresh fruits, vegetables, dairy, snacks, bakery & daily household essentials at the lowest prices in Baharagora.

👉 Download the app now: https://thegroceryhub.in/download
''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'The Grocery Hub - 15 Min Grocery Delivery',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
