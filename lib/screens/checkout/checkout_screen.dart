import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sabpaisa/sabpaisa.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/location_utils.dart';
import 'order_success_screen.dart';
import 'sabpaisa_webview_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _couponController = TextEditingController();

  // SabPaisa PG 3.0 Client (Always freshly configured with clean trimmed keys)
  SabPaisaClient get _sabpaisa => SabPaisaClient(
    SabPaisaConfig(
      apiKey: PaymentConfig.apiKey.trim(),
      merchantId: PaymentConfig.merchantId.trim(),
      secretKey: PaymentConfig.secretKey.trim(),
      clientCode: PaymentConfig.clientCode.trim(),
      env: PaymentConfig.isProduction
          ? Environment.production
          : Environment.staging,
    ),
  );

  AddressModel? _selectedAddress;
  String _selectedPaymentMethod = 'COD'; // 'COD' or 'ONLINE'
  bool _isProcessing = false;
  String _processingMessage = 'Processing Order...';
  bool _isItemsExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    final user = auth.user;
    if (user != null && user.addresses.isNotEmpty) {
      final primaryId = user.primaryAddressId;
      _selectedAddress = user.addresses.firstWhere(
        (a) => a.id == primaryId,
        orElse: () => user.addresses.first,
      );
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Generates 6-digit random delivery OTP (e.g. 482910)
  String _generateDeliveryOtp() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  // Generates unique order ID format ORD-XXXXXX-XXX
  String _generateOrderId() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(900) + 100;
    return 'ORD-${nowMs.toString().substring(7)}-$rand';
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${hour.toString().padLeft(2, '0')}:$min $ampm';
  }

  // Time-based delivery slot evaluation
  bool get _isNextMorningDelivery {
    final now = DateTime.now();
    return now.hour >= 21 || now.hour < 9;
  }

  String get _deliverySlotText {
    return _isNextMorningDelivery
        ? 'Next Morning (9:00 AM - 12:00 PM)'
        : 'Standard (15-min Express Delivery)';
  }

  void _showAddressSelectorModal() {
    final auth = ref.read(authProvider);
    final user = auth.user;
    final addresses = user?.addresses ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Delivery Address',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF19251B),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.savedAddresses);
                    },
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Color(0xFF19251B),
                    ),
                    label: const Text(
                      'Manage',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF19251B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (addresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_off_rounded,
                          size: 40,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No saved addresses found',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.savedAddresses,
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Address'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF19251B),
                            foregroundColor: const Color(0xFFF7C415),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      final isSel = _selectedAddress?.id == addr.id;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedAddress = addr);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFF19251B)
                                  : const Color(0xFFEEEEEE),
                              width: isSel ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFFFFF4B8)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  addr.type.toLowerCase() == 'home'
                                      ? Icons.home_rounded
                                      : Icons.business_center_rounded,
                                  color: const Color(0xFF19251B),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          addr.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            color: Color(0xFF19251B),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF19251B),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            addr.type.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFF7C415),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${addr.street}, ${addr.locality}, Baharagora - ${addr.pincode}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Phone: ${addr.phone}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isSel
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSel
                                    ? const Color(0xFF15803D)
                                    : Colors.grey[400],
                                size: 22,
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
      },
    );
  }

  void _showNonServiceableDialog(ServiceabilityResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delivery Unavailable',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected address is ${result.distanceKm} km away from The Grocery Hub.',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'We deliver strictly within ${result.radiusLimitKm.toStringAsFixed(1)} km of our Baharagora store to guarantee 10-15 minute grocery freshness.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please select or add an address within 5.0 km of Baharagora Hub.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.amber[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showAddressSelectorModal();
            },
            child: const Text(
              'Change Address',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF19251B),
              foregroundColor: const Color(0xFFF7C415),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAvailableCouponsSheet(GroceryProvider grocery) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Offers & Coupons',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF19251B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap "APPLY" to get instant discounts',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildCouponItem(
                code: 'FRESH100',
                title: 'Get ₹100 OFF on order above ₹399',
                minOrderText: 'Min. cart value ₹399',
                grocery: grocery,
              ),
              const SizedBox(height: 10),
              _buildCouponItem(
                code: 'GROCERY50',
                title: 'Get ₹50 OFF on order above ₹199',
                minOrderText: 'Min. cart value ₹199',
                grocery: grocery,
              ),
              const SizedBox(height: 10),
              _buildCouponItem(
                code: 'WELCOME',
                title: 'Flat 15% OFF for new customers',
                minOrderText: 'Max discount up to ₹75',
                grocery: grocery,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponItem({
    required String code,
    required String title,
    required String minOrderText,
    required GroceryProvider grocery,
  }) {
    final isApplied = grocery.appliedCouponCode == code;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isApplied ? const Color(0xFFF0FDF4) : const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApplied ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF19251B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: Color(0xFFF7C415),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF19251B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  minOrderText,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (isApplied) {
                grocery.removeCoupon();
              } else {
                _couponController.text = code;
                grocery.applyCoupon(code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApplied
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFF19251B),
              foregroundColor: isApplied
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFF7C415),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Text(isApplied ? 'REMOVE' : 'APPLY'),
          ),
        ],
      ),
    );
  }

  // --- Order Execution Flow ---
  Future<void> _processCheckout() async {
    final auth = ref.read(authProvider);
    final grocery = ref.read(groceryProvider);
    final user = auth.user;

    // 1. Validate Login
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place your order')),
      );
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }

    // 2. Validate Cart
    if (grocery.cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }

    // 3. Validate Address
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a delivery address'),
        ),
      );
      _showAddressSelectorModal();
      return;
    }

    // 3b. Validate 5.0 km Delivery Boundary from Baharagora Hub
    final double? addrLat = _selectedAddress!.lat;
    final double? addrLng = _selectedAddress!.lng;
    if (addrLat != null && addrLng != null) {
      final serviceability = LocationUtils.checkDeliveryServiceable(
        addrLat,
        addrLng,
      );
      if (!serviceability.isServiceable) {
        _showNonServiceableDialog(serviceability);
        return;
      }
    }

    // Prepare Items List (Safe resolution without falling back to diapers!)
    final List<OrderItemModel> orderItems = [];
    grocery.cartItems.forEach((prodId, qty) {
      ProductModel? product;
      try {
        product = grocery.products.firstWhere((p) => p.id == prodId);
      } catch (_) {
        try {
          product = FirestoreService.fallbackProducts.firstWhere(
            (fp) => fp.id == prodId,
          );
        } catch (_) {
          product = null;
        }
      }

      if (product != null) {
        orderItems.add(
          OrderItemModel(
            id: product.id,
            name: product.title,
            quantity: qty,
            price: product.price,
            image: product.imageUrl,
            unit: product.unit,
          ),
        );
      }
    });

    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid products found in your cart.')),
      );
      return;
    }

    final orderId = _generateOrderId();
    final deliveryOtp = _generateDeliveryOtp();
    final now = DateTime.now();
    final formattedTime = _formatDateTime(now);

    final addressStr =
        '${_selectedAddress!.street}, ${_selectedAddress!.locality}, ${_selectedAddress!.city} ${_selectedAddress!.pincode}';

    if (_selectedPaymentMethod == 'COD') {
      // --- CASH ON DELIVERY PIPELINE ---
      setState(() {
        _isProcessing = true;
        _processingMessage = 'Placing your order...';
      });

      final order = OrderModel(
        id: orderId,
        orderId: orderId,
        userId: user.uid,
        customerName: user.fullName.isNotEmpty
            ? user.fullName
            : _selectedAddress!.name,
        customerEmail: user.email,
        customerPhone: user.phone.isNotEmpty
            ? user.phone
            : _selectedAddress!.phone,
        address: addressStr,
        deliveryAddress: addressStr,
        deliveryAddressObject: _selectedAddress!.toMap(),
        lat: _selectedAddress!.lat ?? 22.2811,
        lng: _selectedAddress!.lng ?? 86.7110,
        items: orderItems,
        totalAmount: grocery.finalPayableAmount,
        subTotal: grocery.cartTotalAmount,
        deliveryFee: grocery.deliveryFee,
        discountAmount: grocery.couponDiscount,
        couponApplied: grocery.appliedCouponCode,
        status: 'Order Received',
        isCurrent: true,
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'Pending (COD)',
        orderTime: formattedTime,
        createdAt: now,
        updatedAt: now,
        deliveryOtp: deliveryOtp,
        isNextMorningDelivery: _isNextMorningDelivery,
        deliverySlot: _deliverySlotText,
      );

      final success = await _firestoreService.createOrder(order);
      if (mounted) {
        if (success) {
          _navigateToOrderSuccess(order);
        } else {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to place order. Please try again.'),
            ),
          );
        }
      }
    } else {
      // --- ONLINE PAYMENT (SabPaisa PG 3.0) PIPELINE ---
      _triggerOnlineSabPaisaPayment(
        orderId: orderId,
        deliveryOtp: deliveryOtp,
        orderItems: orderItems,
        addressStr: addressStr,
        user: user,
        now: now,
        formattedTime: formattedTime,
        grocery: grocery,
      );
    }
  }

  void _navigateToOrderSuccess(OrderModel order) {
    FocusScope.of(context).unfocus();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OrderSuccessScreen(),
        settings: RouteSettings(name: AppRoutes.orderSuccess, arguments: order),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );

    // Silently clear cart on next frame to prevent heavy layout recomputations during route transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final grocery = ref.read(groceryProvider);
        grocery.clearCart();
      }
    });
  }

  /// Polls SabPaisa transaction enquiry up to [maxRetries] times, waiting
  /// [retryDelay] between each attempt. Needed because SabPaisa may still show
  /// PENDING for a few seconds right after the WebView closes.
  Future<dynamic> _enquiryWithRetry(
    String merchantTxnId, {
    int maxRetries = 5,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      final txn = await _sabpaisa.transactions.enquiry(
        merchantTxnId: merchantTxnId,
      );
      final status = txn.data.status;
      // Terminal statuses — stop retrying
      if (status == 'SUCCESS' ||
          status == 'FAILED' ||
          status == 'EXPIRED' ||
          status == 'CANCELLED') {
        return txn;
      }
      // PENDING / PROCESSING — wait and retry
      if (i < maxRetries - 1) {
        await Future.delayed(retryDelay);
      }
    }
    // Return last known result even if still pending
    return await _sabpaisa.transactions.enquiry(merchantTxnId: merchantTxnId);
  }

  /// Opens SabPaisa payment inside the app (WebView Flutter screen).
  /// Order is only committed to Firestore AFTER enquiry confirms SUCCESS.
  Future<void> _triggerOnlineSabPaisaPayment({
    required String orderId,
    required String deliveryOtp,
    required List<OrderItemModel> orderItems,
    required String addressStr,
    required UserModel user,
    required DateTime now,
    required String formattedTime,
    required GroceryProvider grocery,
  }) async {
    if (!PaymentConfig.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Online payment is temporarily unavailable. Please select Cash on Delivery.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Opening secure payment...';
    });

    try {
      // Amount is in paise (1 rupee = 100 paise)
      final int amountPaise = (grocery.finalPayableAmount * 100).round();

      final rawName = user.fullName.isNotEmpty
          ? user.fullName
          : _selectedAddress!.name;
      final customerName = rawName.trim().isNotEmpty
          ? rawName.trim()
          : 'GroceryHub Customer';

      final rawPhone = user.phone.isNotEmpty
          ? user.phone
          : _selectedAddress!.phone;
      final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
      final customerMobile = digitsOnly.length >= 10
          ? digitsOnly.substring(digitsOnly.length - 10)
          : (digitsOnly.isNotEmpty ? digitsOnly : '9876543210');

      final customerEmail = (user.email.isNotEmpty && user.email.contains('@'))
          ? user.email.trim()
          : 'customer.${digitsOnly.length >= 6 ? digitsOnly.substring(digitsOnly.length - 6) : "user"}@thegroceryhub.in';

      // Step 1 — Create payment session → get checkout URL
      final payment = await _sabpaisa.payments.createSession(
        CreatePaymentRequest(
          merchantTxnId: orderId,
          amount: amountPaise,
          customerName: customerName,
          customerEmail: customerEmail,
          customerMobile: customerMobile,
          udfFields: {'udf1': orderId, 'udf2': user.uid},
        ),
        options: RequestOptions(idempotencyKey: 'order-$orderId'),
      );

      final checkoutUrl = payment.checkoutUrl;

      if (!mounted) return;

      // Keep _isProcessing = true and pre-set message so when WebView pops,
      // the user immediately sees the verification loader instead of the checkout form.
      setState(() {
        _isProcessing = true;
        _processingMessage = 'Verifying payment with bank...';
      });

      // Step 2 — Push the in-app WebView payment screen (user stays inside the app)
      final webResult = await Navigator.push<SabPaisaWebViewResult>(
        context,
        MaterialPageRoute(
          builder: (_) => SabPaisaWebViewScreen(checkoutUrl: checkoutUrl),
        ),
      );

      if (!mounted) return;

      // User cancelled or closed without paying
      if (webResult == null || !webResult.success) {
        setState(() => _isProcessing = false);
        final msg = webResult?.errorMessage ?? 'Payment cancelled by user.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF19251B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Step 3 — Payment WebView closed with success signal.
      // Keep full-screen loader visible while verifying transaction with bank.
      setState(() {
        _isProcessing = true;
        _processingMessage = 'Verifying payment with bank...';
      });

      final txn = await _enquiryWithRetry(orderId);

      if (!mounted) return;

      if (txn.data.status == 'SUCCESS') {
        setState(() {
          _processingMessage = 'Payment confirmed! Placing your order...';
        });

        // ✅ Payment confirmed — now commit order to Firestore
        final order = OrderModel(
          id: orderId,
          orderId: orderId,
          userId: user.uid,
          customerName: customerName,
          customerEmail: user.email,
          customerPhone: customerMobile,
          address: addressStr,
          deliveryAddress: addressStr,
          deliveryAddressObject: _selectedAddress!.toMap(),
          lat: _selectedAddress!.lat ?? 22.2811,
          lng: _selectedAddress!.lng ?? 86.7110,
          items: orderItems,
          totalAmount: grocery.finalPayableAmount,
          subTotal: grocery.cartTotalAmount,
          deliveryFee: grocery.deliveryFee,
          discountAmount: grocery.couponDiscount,
          couponApplied: grocery.appliedCouponCode,
          status: 'Order Received',
          isCurrent: true,
          paymentMethod: 'Online Payment (SabPaisa)',
          paymentStatus: 'Paid (SabPaisa PG 3.0)',
          sabpaisaTxnId: txn.data.bankTxnId,
          paymentResponse: {
            'txnId': txn.data.bankTxnId,
            'bankRrn': txn.data.bankRrn,
            'paymentMode': txn.data.paymentMode,
            'amountPaise': txn.data.amountPaise,
            'status': txn.data.status,
            'merchantTxnId': orderId,
          },
          orderTime: formattedTime,
          createdAt: now,
          updatedAt: now,
          deliveryOtp: deliveryOtp,
          isNextMorningDelivery: _isNextMorningDelivery,
          deliverySlot: _deliverySlotText,
        );

        final success = await _firestoreService.createOrder(order);
        if (mounted) {
          if (success) {
            _navigateToOrderSuccess(order);
            return;
          } else {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Payment captured, but order could not be saved. Contact support.',
                ),
              ),
            );
          }
        }
      } else {
        // ❌ Payment failed/pending — zero ghost orders, cart preserved
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment ${txn.data.status.toLowerCase()}. Please try again.',
            ),
            backgroundColor: const Color(0xFF19251B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ValidationError catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation error: ${e.field} — ${e.message}'),
          ),
        );
      }
    } on ApiError catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SabPaisa error: ${e.message} (HTTP ${e.statusCode})',
            ),
            backgroundColor: const Color(0xFF19251B),
          ),
        );
      }
    } on SabPaisaError catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.message}'),
            backgroundColor: const Color(0xFF19251B),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grocery = ref.watch(groceryProvider);
    final cartItemsList = _buildCartProductsList(grocery);

    return PopScope(
      canPop: !_isProcessing,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              backgroundColor: const Color(0xFFFFF4B8),
              elevation: 0,
              scrolledUnderElevation: 0,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Color(0xFFFFF4B8),
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFF4B8), // Soft yellow header gradient
                      Color(0xFFFFF9E0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              leading: Center(
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: Color(0xFF19251B),
                    ),
                  ),
                ),
              ),
              titleSpacing: 0,
              title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Checkout',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF19251B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isNextMorningDelivery
                            ? 'Next Morning Slot • Baharagora Hub'
                            : '15-Min Express Delivery • Baharagora Hub',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Delivery Address & Timing Card
                  _buildDeliverySection(),
                  const SizedBox(height: 14),

                  // B. Cart Items Preview
                  if (cartItemsList.isNotEmpty) ...[
                    _buildItemsPreviewSection(grocery, cartItemsList),
                    const SizedBox(height: 14),
                  ],

                  // C. Promo Code / Coupons
                  _buildCouponInputSection(grocery),
                  const SizedBox(height: 14),

                  // D. Payment Method Selection
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 14),

                  // E. Bill Summary
                  _buildBillDetailsSection(grocery),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            bottomSheet: _buildBottomPayBar(grocery),
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  // --- 1. DELIVERY ADDRESS & TIMING SECTION ---
  Widget _buildDeliverySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Color(0xFF19251B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFF7C415),
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        const Text(
                          'Delivery to',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF19251B),
                          ),
                        ),
                        if (_selectedAddress != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4B8),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFF7C415),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              _selectedAddress!.type.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF19251B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: _showAddressSelectorModal,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF19251B),
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: Color(0xFF19251B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: _selectedAddress != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _selectedAddress!.name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF19251B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  ${_selectedAddress!.phone}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedAddress!.street}, ${_selectedAddress!.locality}, Baharagora - ${_selectedAddress!.pincode}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[800],
                          height: 1.35,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'No delivery address selected',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.savedAddresses,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF19251B),
                          foregroundColor: const Color(0xFFF7C415),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Add Address'),
                      ),
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFDF5),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: Color(0xFFFEF3C7))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4B8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _isNextMorningDelivery
                        ? Icons.wb_twilight_rounded
                        : Icons.bolt_rounded,
                    size: 15,
                    color: const Color(0xFF19251B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isNextMorningDelivery
                        ? 'Next Morning Slot (9:00 AM - 12:00 PM)'
                        : 'Guaranteed 15-Min Fresh Express Delivery',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF19251B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRIORITY',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15803D),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. ORDER ITEMS PREVIEW SECTION ---
  Widget _buildItemsPreviewSection(
    GroceryProvider grocery,
    List<_CartItemDetail> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4B8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF19251B),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF19251B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF19251B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${grocery.cartCount}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF7C415),
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    setState(() => _isItemsExpanded = !_isItemsExpanded);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isItemsExpanded ? 'Hide' : 'View all',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF19251B),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isItemsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: const Color(0xFF19251B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          if (!_isItemsExpanded)
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 38,
                            height: 38,
                            color: Colors.white,
                            child: item.product.imageUrl.isNotEmpty
                                ? Image.network(
                                    item.product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  )
                                : const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 86,
                              child: Text(
                                item.product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF19251B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF19251B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'x${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: Color(0xFFF7C415),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF19251B),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 14, color: Color(0xFFF3F4F6)),
              itemBuilder: (ctx, i) {
                final item = items[i];
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 42,
                        height: 42,
                        color: const Color(0xFFF9FAFB),
                        child: item.product.imageUrl.isNotEmpty
                            ? Image.network(
                                item.product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF19251B),
                            ),
                          ),
                          Text(
                            item.product.unit,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4B8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF19251B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF19251B),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // --- 3. COUPONS & OFFERS SECTION ---
  Widget _buildCouponInputSection(GroceryProvider grocery) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4B8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.discount_outlined,
                      color: Color(0xFF19251B),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Coupons & Offers',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF19251B),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showAvailableCouponsSheet(grocery),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Coupons',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF19251B),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: Color(0xFF19251B),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (grocery.appliedCouponCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code "${grocery.appliedCouponCode}" Applied',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                        ),
                        Text(
                          'You save ₹${grocery.couponDiscount.toStringAsFixed(0)} on this order!',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => grocery.removeCoupon(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF19251B),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter coupon code',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_couponController.text.trim().isNotEmpty) {
                        grocery.applyCoupon(_couponController.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19251B),
                      foregroundColor: const Color(0xFFF7C415),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Text(
                      'APPLY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (grocery.couponError != null) ...[
            const SizedBox(height: 6),
            Text(
              grocery.couponError!,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. PAYMENT METHOD SECTION ---
  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4B8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF19251B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF19251B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Option 1: Pay Online
          _buildPaymentOption(
            id: 'ONLINE',
            title: 'Pay Online',
            subtitle: 'UPI, Credit/Debit Cards, Net Banking',
            icon: Icons.flash_on_rounded,
            badgeText: 'FASTEST',
            iconBgColor: const Color(0xFFFFF4B8),
            iconColor: const Color(0xFF19251B),
          ),

          const SizedBox(height: 10),

          // Option 2: Cash on Delivery
          _buildPaymentOption(
            id: 'COD',
            title: 'Cash on Delivery',
            subtitle: 'Pay via cash or UPI directly at doorstep',
            icon: Icons.payments_rounded,
            badgeText: 'DOORSTEP',
            iconBgColor: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF15803D),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = id);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF19251B)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF7C415).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF19251B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF4B8)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: isSelected
                                ? const Color(0xFF19251B)
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF19251B)
                      : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFF19251B)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7C415),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. BILL DETAILS SECTION ---
  Widget _buildBillDetailsSection(GroceryProvider grocery) {
    final savings =
        grocery.couponDiscount + (grocery.deliveryFee == 0 ? 25 : 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4B8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF19251B),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Bill Summary',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF19251B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                _buildBillRow(
                  'Item Total',
                  '₹${grocery.cartTotalAmount.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                _buildBillRow(
                  'Delivery Fee',
                  grocery.deliveryFee == 0
                      ? 'FREE'
                      : '₹${grocery.deliveryFee.toStringAsFixed(0)}',
                  isGreen: grocery.deliveryFee == 0,
                  strikeOriginal: grocery.deliveryFee == 0 ? '₹25' : null,
                ),
                const SizedBox(height: 8),
                _buildBillRow('Handling & Packaging', 'FREE', isGreen: true),
                if (grocery.couponDiscount > 0) ...[
                  const SizedBox(height: 8),
                  _buildBillRow(
                    'Coupon Savings',
                    '-₹${grocery.couponDiscount.toStringAsFixed(0)}',
                    isGreen: true,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: _DashedDivider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Payable',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF19251B),
                          ),
                        ),
                        Text(
                          'Incl. all taxes',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${grocery.finalPayableAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF19251B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (savings > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Color(0xFFFDE68A))),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 16,
                    color: Color(0xFF19251B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🎉 You are saving ₹${savings.toStringAsFixed(0)} on this order!',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF19251B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- 6. BOTTOM PAY BAR ---
  Widget _buildBottomPayBar(GroceryProvider grocery) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL TO PAY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '₹${grocery.finalPayableAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF19251B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF19251B),
                    foregroundColor: const Color(0xFFF7C415),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF7C415),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedPaymentMethod == 'COD'
                                  ? 'Place Order'
                                  : 'Proceed to Pay',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Color(0xFFF7C415),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Material(
      color: Colors.black.withValues(alpha: 0.65),
      child: PopScope(
        canPop: false,
        child: SizedBox.expand(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF19251B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _processingMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF19251B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please wait, do not close the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    String value, {
    bool isGreen = false,
    String? strikeOriginal,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey[700])),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (strikeOriginal != null) ...[
              Text(
                strikeOriginal,
                style: TextStyle(
                  fontSize: 11.5,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isGreen
                    ? const Color(0xFF15803D)
                    : const Color(0xFF19251B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<_CartItemDetail> _buildCartProductsList(GroceryProvider grocery) {
    final List<_CartItemDetail> items = [];
    grocery.cartItems.forEach((prodId, qty) {
      ProductModel? prod;
      try {
        prod = grocery.products.firstWhere((p) => p.id == prodId);
      } catch (_) {
        try {
          prod = FirestoreService.fallbackProducts.firstWhere(
            (fp) => fp.id == prodId,
          );
        } catch (_) {
          prod = null;
        }
      }
      if (prod != null) {
        items.add(_CartItemDetail(product: prod, quantity: qty));
      }
    });
    return items;
  }
}

class _CartItemDetail {
  final ProductModel product;
  final int quantity;

  _CartItemDetail({required this.product, required this.quantity});
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return SizedBox(
          width: boxWidth,
          height: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFE5E7EB)),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
