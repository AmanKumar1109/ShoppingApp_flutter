import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/complaint_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import 'seed_data.dart';

class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // In-memory cache to prevent repeated server requests
  static List<ProductModel>? _cachedProducts;
  static List<CategoryModel>? _cachedCategories;
  static DateTime? _lastProductsFetchTime;

  // Fallback Categories & Products ensuring instant, flicker-free rendering
  static List<CategoryModel> get fallbackCategories =>
      SeedData.fallbackCategories;
  static List<ProductModel> get fallbackProducts => SeedData.fallbackProducts;

  // 1. Real-time Stream of Categories with In-Memory Caching
  Stream<List<CategoryModel>> streamCategories() {
    return _firestore
        .collection('categories')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            _cachedCategories = fallbackCategories;
            return fallbackCategories;
          }
          final loaded = snapshot.docs.map((doc) {
            return CategoryModel.fromMap(doc.data(), doc.id);
          }).toList();
          _cachedCategories = loaded;
          return loaded;
        })
        .handleError((error) {
          debugPrint('Firestore Categories stream error: $error');
          return _cachedCategories ?? fallbackCategories;
        });
  }

  // 2. Real-time Stream of Items/Products with Lazy In-Memory Caching
  Stream<List<ProductModel>> streamProducts() {
    return _firestore
        .collection('items')
        .snapshots()
        .asyncMap((snapshot) async {
          List<DocumentSnapshot> docs = List.from(snapshot.docs);

          if (docs.isEmpty) {
            try {
              final productsSnap = await _firestore
                  .collection('products')
                  .get();
              if (productsSnap.docs.isNotEmpty) {
                docs = productsSnap.docs;
              }
            } catch (_) {}
          }

          if (docs.isEmpty) {
            _cachedProducts = fallbackProducts;
            return fallbackProducts;
          }

          final items = docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                return ProductModel.fromMap(data, doc.id);
              })
              .where((item) => item.isVisible)
              .toList();

          items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final finalItems = items.isEmpty ? fallbackProducts : items;
          _cachedProducts = finalItems;
          _lastProductsFetchTime = DateTime.now();
          return finalItems;
        })
        .handleError((error) {
          debugPrint('Firestore Items stream error: $error');
          return _cachedProducts ?? fallbackProducts;
        });
  }

  // Cached one-time getter with 5-minute TTL to reduce unnecessary network calls
  Future<List<ProductModel>> getCachedOrFetchProducts() async {
    if (_cachedProducts != null &&
        _lastProductsFetchTime != null &&
        DateTime.now().difference(_lastProductsFetchTime!).inMinutes < 5) {
      return _cachedProducts!;
    }
    return getProducts();
  }

  Future<List<CategoryModel>> getCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;
    try {
      final snap = await _firestore.collection('categories').get();
      if (snap.docs.isNotEmpty) {
        _cachedCategories = snap.docs
            .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
            .toList();
        return _cachedCategories!;
      }
    } catch (e) {
      debugPrint('Error getting categories: $e');
    }
    return fallbackCategories;
  }

  Future<List<ProductModel>> getProducts() async {
    try {
      final snap = await _firestore.collection('items').get();
      List<DocumentSnapshot> docs = List.from(snap.docs);
      if (docs.isEmpty) {
        final prodsSnap = await _firestore.collection('products').get();
        if (prodsSnap.docs.isNotEmpty) {
          docs = prodsSnap.docs;
        }
      }

      if (docs.isNotEmpty) {
        final items = docs
            .map(
              (doc) => ProductModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .where((item) => item.isVisible)
            .toList();
        items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _cachedProducts = items;
        _lastProductsFetchTime = DateTime.now();
        return items;
      }
    } catch (e) {
      debugPrint('Error getting products: $e');
    }
    _cachedProducts = fallbackProducts;
    return fallbackProducts;
  }

  // --- Complaints Management ---
  Future<bool> createComplaint(ComplaintModel complaint) async {
    try {
      await _firestore.collection('complaints').add(complaint.toMap());
      return true;
    } catch (e) {
      debugPrint('Error creating complaint: $e');
      return false;
    }
  }

  Stream<List<ComplaintModel>> streamUserComplaints(String userId) {
    return _firestore
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return ComplaintModel.fromMap(doc.data(), doc.id);
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((error) {
          debugPrint('Error streaming complaints: $error');
          return <ComplaintModel>[];
        });
  }

  // --- Orders Management ---
  Future<bool> createOrder(OrderModel order) async {
    try {
      await _firestore
          .collection('orders')
          .doc(order.orderId)
          .set(order.toMap());

      // Enqueue order confirmation email
      await enqueueOrderMail(order);
      return true;
    } catch (e) {
      debugPrint('Error creating order in Firestore: $e');
      return false;
    }
  }

  Stream<List<OrderModel>> streamUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((error) {
          debugPrint('Error streaming user orders: $error');
          return <OrderModel>[];
        });
  }

  /// Streams real-time live document snapshot for a single order by orderId
  Stream<OrderModel?> streamOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return OrderModel.fromMap(doc.data()!, doc.id);
        })
        .handleError((error) {
          debugPrint('Error streaming live order $orderId: $error');
          return null;
        });
  }

  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists || doc.data() == null) return null;
      return OrderModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error getting order $orderId: $e');
      return null;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'Cancelled',
        'isCurrent': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return false;
    }
  }

  // 3. Real-time Stream of Mobile App Banners (Top Carousel)
  // Returns null if collection doesn't exist yet, or list of active banners.
  Stream<List<Map<String, dynamic>>?> streamAppBanners() {
    return _firestore
        .collection('app_banners')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          final items = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .where((data) => data['isActive'] != false)
              .toList();
          items.sort(
            (a, b) =>
                ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num),
          );
          return items;
        })
        .handleError((error) {
          debugPrint('Firestore App Banners stream error: $error');
          return null;
        });
  }

  // 4. Real-time Stream of Mobile App Category Covers / Quick Tiles
  Stream<List<Map<String, dynamic>>> streamCategoryCovers() {
    return _firestore
        .collection('app_category_covers')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        })
        .handleError((error) {
          debugPrint('Firestore Category Covers stream error: $error');
          return <Map<String, dynamic>>[];
        });
  }

  // 5. Real-time Stream of Mobile App Home Layout Sections
  Stream<List<Map<String, dynamic>>?> streamHomeSections() {
    return _firestore
        .collection('app_home_sections')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          final items = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .where((data) => data['isActive'] != false)
              .toList();
          items.sort(
            (a, b) =>
                ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num),
          );
          return items;
        })
        .handleError((error) {
          debugPrint('Firestore Home Sections stream error: $error');
          return null;
        });
  }

  Future<void> enqueueOrderMail(OrderModel order) async {
    try {
      if (order.customerEmail.isEmpty) return;
      await _firestore.collection('mail').add({
        'to': order.customerEmail,
        'from': '"The Grocery Hub" <ghoshabhijit1295@gmail.com>',
        'message': {
          'subject': 'Order Confirmation - ${order.orderId}',
          'html':
              '<h2>Thank you for ordering with The Grocery Hub!</h2>'
              '<p>Your order <strong>${order.orderId}</strong> has been received.</p>'
              '<p>Delivery OTP: <strong>${order.deliveryOtp}</strong></p>'
              '<p>Total Amount: ₹${order.totalAmount.toStringAsFixed(0)}</p>'
              '<p>Delivery Address: ${order.deliveryAddress}</p>',
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error enqueuing order mail: $e');
    }
  }
}
