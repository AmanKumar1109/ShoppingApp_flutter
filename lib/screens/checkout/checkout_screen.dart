import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sabpaisa/sabpaisa.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/firestore_service.dart';
import 'order_success_screen.dart';
import 'sabpaisa_webview_screen.dart';

// ── SabPaisa PG 3.0 Client (Production) ────────────────────────────────────────
// Replace placeholder values with your live SabPaisa production credentials.
final _sabpaisa = SabPaisaClient(
  SabPaisaConfig(
    apiKey: 'sp_NG9CX1P_GTie569c-mQmJt4AgH_XgXn_ts-SEObGD8Y',
    merchantId: 'THEG1',
    secretKey: 'sec_i2gmRNd2zRPgJwgc1-sp5WWK0jZXZgSq8TxlMHhCKVY',
    clientCode: 'THEG1',
    env: Environment.production,
  ),
);

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _couponController = TextEditingController();

  AddressModel? _selectedAddress;
  String _selectedPaymentMethod = 'COD'; // 'COD' or 'ONLINE'
  bool _isProcessing = false;
  String _processingMessage = 'Processing Order...';

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
    super.dispose();
  }

  // Generates 6-digit random delivery OTP (e.g. 482910)
  String _generateDeliveryOtp() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  // Generates order ID format ORD-XXXX
  String _generateOrderId() {
    final rand = Random();
    final num = 1000 + rand.nextInt(9000);
    return 'ORD-$num';
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
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
                      Icons.add,
                      size: 16,
                      color: Color(0xFF19251B),
                    ),
                    label: const Text(
                      'Manage',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
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
                        const Text('No saved addresses found'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.savedAddresses,
                            );
                          },
                          child: const Text('Add Address'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final addr = addresses[index];
                    final isSel = _selectedAddress?.id == addr.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFFFFFBEB)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel
                              ? const Color(0xFFF7C415)
                              : const Color(0xFFEEEEEE),
                          width: isSel ? 1.6 : 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          leading: Icon(
                            addr.type.toLowerCase() == 'home'
                                ? Icons.home_rounded
                                : Icons.business_center_rounded,
                            color: const Color(0xFF19251B),
                          ),
                          title: Text(
                            '${addr.type} - ${addr.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            '${addr.street}, ${addr.locality}, Baharagora',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: isSel
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF15803D),
                                )
                              : null,
                          onTap: () {
                            setState(() => _selectedAddress = addr);
                            Navigator.pop(ctx);
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
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
          padding: const EdgeInsets.all(20),
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
              const Text(
                'Available Promo Coupons',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF19251B),
                ),
              ),
              const SizedBox(height: 14),
              _buildCouponItem(
                code: 'FRESH100',
                title: 'Get ₹100 OFF on orders above ₹399',
                grocery: grocery,
              ),
              const SizedBox(height: 10),
              _buildCouponItem(
                code: 'GROCERY50',
                title: 'Get ₹50 OFF on orders above ₹199',
                grocery: grocery,
              ),
              const SizedBox(height: 10),
              _buildCouponItem(
                code: 'WELCOME',
                title: 'Flat 15% OFF for new customers (up to ₹75)',
                grocery: grocery,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponItem({
    required String code,
    required String title,
    required GroceryProvider grocery,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
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
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF19251B),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _couponController.text = code;
              grocery.applyCoupon(code);
            },
            child: const Text(
              'APPLY',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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

    // Prepare Items List
    final List<OrderItemModel> orderItems = [];
    grocery.cartItems.forEach((prodId, qty) {
      final product = grocery.products.firstWhere(
        (p) => p.id == prodId,
        orElse: () => FirestoreService.fallbackProducts.firstWhere(
          (fp) => fp.id == prodId,
          orElse: () => FirestoreService.fallbackProducts.first,
        ),
      );
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
    });

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
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Opening secure payment...';
    });

    try {
      // Amount is in paise (1 rupee = 100 paise)
      final int amountPaise = (grocery.finalPayableAmount * 100).round();

      final customerName = user.fullName.isNotEmpty
          ? user.fullName
          : _selectedAddress!.name;
      final customerMobile = user.phone.isNotEmpty
          ? user.phone
          : _selectedAddress!.phone;

      // Step 1 — Create payment session → get checkout URL
      final payment = await _sabpaisa.payments.createSession(
        CreatePaymentRequest(
          merchantTxnId: orderId,
          amount: amountPaise,
          customerName: customerName,
          customerEmail: user.email,
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
    return PopScope(
      canPop: !_isProcessing,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              backgroundColor: const Color(0xFFFFF4B8),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF19251B),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Checkout & Order',
                style: TextStyle(
                  color: Color(0xFF19251B),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Delivery Address Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF4B8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF19251B),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF19251B),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _showAddressSelectorModal,
                              child: const Text(
                                'Change',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        if (_selectedAddress != null) ...[
                          Row(
                            children: [
                              Text(
                                _selectedAddress!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _selectedAddress!.type.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedAddress!.street}, ${_selectedAddress!.locality}, Baharagora - ${_selectedAddress!.pincode}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Color(0xFF15803D),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Baharagora 5 km radius service verified',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Text(
                            'No address selected',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.savedAddresses,
                            ),
                            icon: const Icon(
                              Icons.add_location_alt_rounded,
                              size: 16,
                            ),
                            label: const Text('Add Delivery Address'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF19251B),
                              foregroundColor: const Color(0xFFF7C415),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Delivery Time Slot Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isNextMorningDelivery
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isNextMorningDelivery
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isNextMorningDelivery
                              ? Icons.nightlight_round
                              : Icons.flash_on_rounded,
                          color: _isNextMorningDelivery
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _deliverySlotText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: _isNextMorningDelivery
                                      ? const Color(0xFF92400E)
                                      : const Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isNextMorningDelivery
                                    ? 'Late night order: Store opens at 9:00 AM'
                                    : 'Packed fresh at Baharagora Hub & delivered in 15 mins',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _isNextMorningDelivery
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Apply Coupon Code Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Apply Coupon / Promo',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF19251B),
                              ),
                            ),
                            InkWell(
                              onTap: () => _showAvailableCouponsSheet(grocery),
                              child: const Text(
                                'View Coupons',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (grocery.appliedCouponCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF86EFAC),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF16A34A),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Coupon "${grocery.appliedCouponCode}" applied! (Saved ₹${grocery.couponDiscount.toStringAsFixed(0)})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => grocery.removeCoupon(),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: 'Enter code (e.g. FRESH100)',
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  if (_couponController.text
                                      .trim()
                                      .isNotEmpty) {
                                    grocery.applyCoupon(
                                      _couponController.text.trim(),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF19251B),
                                  foregroundColor: const Color(0xFFF7C415),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Apply'),
                              ),
                            ],
                          ),
                        if (grocery.couponError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            grocery.couponError!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Payment Method Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Payment Method',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF19251B),
                            ),
                          ),
                          const SizedBox(height: 12),

                          RadioGroup<String>(
                            groupValue: _selectedPaymentMethod,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPaymentMethod = val);
                              }
                            },
                            child: Column(
                              children: [
                                // Cash on Delivery
                                Material(
                                  color: Colors.transparent,
                                  child: RadioListTile<String>(
                                    value: 'COD',
                                    activeColor: const Color(0xFF19251B),
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text(
                                      'Cash on Delivery (COD)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Pay with cash or UPI directly to rider upon delivery OTP',
                                      style: TextStyle(fontSize: 11.5),
                                    ),
                                    secondary: const Icon(
                                      Icons.money_rounded,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),

                                const Divider(height: 1),

                                // Online Payment (SabPaisa PG 3.0)
                                Material(
                                  color: Colors.transparent,
                                  child: RadioListTile<String>(
                                    value: 'ONLINE',
                                    activeColor: const Color(0xFF19251B),
                                    contentPadding: EdgeInsets.zero,
                                    title: Row(
                                      children: [
                                        const Text(
                                          'Online Payment',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF4B8),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'SABPAISA PG',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: const Text(
                                      'UPI, Google Pay, PhonePe, Debit/Credit Card, NetBanking',
                                      style: TextStyle(fontSize: 11.5),
                                    ),
                                    secondary: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Bill Summary Breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF19251B),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                        ),
                        if (grocery.couponDiscount > 0) ...[
                          const SizedBox(height: 8),
                          _buildBillRow(
                            'Coupon Discount',
                            '-₹${grocery.couponDiscount.toStringAsFixed(0)}',
                            isGreen: true,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildBillRow(
                          'Packaging & Handling',
                          'FREE',
                          isGreen: true,
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Payable Amount',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF19251B),
                              ),
                            ),
                            Text(
                              '₹${grocery.finalPayableAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF152C1E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Checkout Bar
            bottomSheet: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
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
                        const Text(
                          'Total to pay',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          '₹${grocery.finalPayableAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
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
                              borderRadius: BorderRadius.circular(14),
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
                              : Text(
                                  _selectedPaymentMethod == 'COD'
                                      ? 'Place Order (COD)'
                                      : 'Proceed to Payment',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4B8).withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF19251B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _processingMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF19251B),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait, do not close the app or press back.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: Color(0xFF15803D),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Secure Bank Processing',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isGreen ? const Color(0xFF15803D) : const Color(0xFF19251B),
          ),
        ),
      ],
    );
  }
}
