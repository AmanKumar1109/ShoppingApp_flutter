import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../services/share_service.dart';
import '../../utils/location_utils.dart';
import '../../widgets/fast_cached_image.dart';
import '../../widgets/order_live_map.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isCancelling = false;

  void _confirmCancelOrder(BuildContext context, OrderModel order) {
    final elapsedSeconds = DateTime.now().difference(order.createdAt).inSeconds;
    if (elapsedSeconds >= 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order cannot be cancelled. 5-minute cancellation window has passed.',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text(
              'Cancel Order',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel order ${order.orderId}? If already paid, the amount will be refunded to your wallet or source account.',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Keep Order',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _isCancelling = true);
              final success = await _firestoreService.cancelOrder(
                order.orderId,
              );
              setState(() => _isCancelling = false);

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order has been cancelled successfully.'),
                      backgroundColor: Color(0xFF19251B),
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to cancel order.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _callRider(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not place call to $phoneNumber')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error calling rider: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialOrder =
        ModalRoute.of(context)?.settings.arguments as OrderModel?;

    if (initialOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return StreamBuilder<OrderModel?>(
      stream: _firestoreService.streamOrder(initialOrder.orderId),
      initialData: initialOrder,
      builder: (context, snapshot) {
        final order = snapshot.data ?? initialOrder;

        final isCancelled = order.status.toLowerCase() == 'cancelled';
        final isDelivered = order.status.toLowerCase() == 'delivered';
        final isOutForDelivery =
            order.status.toLowerCase() == 'out for delivery';
        final isPacked = order.status.toLowerCase() == 'packed & dispatched' ||
            order.status.toLowerCase() == 'packed' ||
            order.status.toLowerCase() == 'preparing';

        final distanceKm = LocationUtils.calculateDistanceKm(
          BaharagoraHub.lat,
          BaharagoraHub.lng,
          order.lat,
          order.lng,
        );
        final etaMins = LocationUtils.calculateETA(distanceKm);

        // Progress bar value (0.0 to 1.0)
        double progressValue = 0.25;
        if (isCancelled) {
          progressValue = 0.0;
        } else if (isDelivered) {
          progressValue = 1.0;
        } else if (isOutForDelivery) {
          progressValue = 0.75;
        } else if (isPacked) {
          progressValue = 0.50;
        }

        return Scaffold(
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
            title: Text(
              'Track ${order.orderId}',
              style: const TextStyle(
                color: Color(0xFF19251B),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              Builder(
                builder: (btnCtx) {
                  return IconButton(
                    tooltip: 'Share Live Tracking',
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFF19251B),
                      size: 20,
                    ),
                    onPressed: () {
                      final box = btnCtx.findRenderObject() as RenderBox?;
                      final origin = box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null;
                      ShareService.shareOrder(order, sharePositionOrigin: origin);
                    },
                  );
                },
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF19251B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Google Maps Live Route & Rider Tracking Widget
                OrderLiveMap(
                  destinationLat: order.lat,
                  destinationLng: order.lng,
                  orderStatus: order.status,
                  destinationAddress: order.deliveryAddress,
                  liveRiderLat: order.riderLat,
                  liveRiderLng: order.riderLng,
                  height: 270,
                ),

                const SizedBox(height: 16),

                // 2. Live Status & ETA Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Delivery',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDelivered
                                    ? 'Delivered'
                                    : (isCancelled
                                        ? 'Cancelled'
                                        : '$etaMins Minutes'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF19251B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isCancelled
                                  ? const Color(0xFFFEE2E2)
                                  : (isDelivered
                                      ? const Color(0xFFDCFCE7)
                                      : (isOutForDelivery
                                          ? const Color(0xFFDBEAFE)
                                          : const Color(0xFFFFF4B8))),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isCancelled
                                    ? const Color(0xFFDC2626)
                                    : (isDelivered
                                        ? const Color(0xFF15803D)
                                        : (isOutForDelivery
                                            ? const Color(0xFF1D4ED8)
                                            : const Color(0xFF19251B))),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: const Color(0xFFF3F4F6),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDelivered
                                ? const Color(0xFF15803D)
                                : const Color(0xFFF7C415),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. 6-Digit Delivery OTP Card
                if (!isCancelled && !isDelivered)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFF7C415),
                        width: 1.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF19251B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pin_rounded,
                            color: Color(0xFFF7C415),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Verification OTP',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.deliveryOtp,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4.0,
                                  color: Color(0xFF19251B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Tooltip(
                          message: 'Share this with the rider at your door',
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFB45309),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // 4. Live Progress Stepper
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Status Tracker',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF19251B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStepRow(
                        title: 'Order Received',
                        subtitle:
                            'Confirmed at Baharagora Hub (${order.orderTime})',
                        isDone: true,
                        isCurrent: order.status == 'Order Received' ||
                            order.status == 'Pending',
                      ),
                      _buildStepConnector(
                        isDone: isPacked || isOutForDelivery || isDelivered,
                      ),
                      _buildStepRow(
                        title: 'Packing & Preparing',
                        subtitle:
                            'Quality checked & sealed in tamper-proof bags',
                        isDone: isPacked || isOutForDelivery || isDelivered,
                        isCurrent: isPacked,
                      ),
                      _buildStepConnector(
                        isDone: isOutForDelivery || isDelivered,
                      ),
                      _buildStepRow(
                        title: 'Out for Delivery',
                        subtitle: 'Rider on the way to ${order.deliveryAddress}',
                        isDone: isOutForDelivery || isDelivered,
                        isCurrent: isOutForDelivery,
                      ),
                      _buildStepConnector(isDone: isDelivered),
                      _buildStepRow(
                        title: 'Delivered',
                        subtitle: 'Verified with 6-digit OTP',
                        isDone: isDelivered,
                        isCurrent: isDelivered,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Live Assigned Delivery Partner Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: (order.assignedPartnerName != null &&
                                order.assignedPartnerName!.isNotEmpty &&
                                order.assignedPartnerName != 'Unassigned')
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFFF4B8),
                        child: Icon(
                          Icons.two_wheeler_rounded,
                          color: (order.assignedPartnerName != null &&
                                  order.assignedPartnerName!.isNotEmpty &&
                                  order.assignedPartnerName != 'Unassigned')
                              ? const Color(0xFF15803D)
                              : const Color(0xFF19251B),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (order.assignedPartnerName != null &&
                                      order.assignedPartnerName!.isNotEmpty &&
                                      order.assignedPartnerName != 'Unassigned')
                                  ? order.assignedPartnerName!
                                  : 'Assigning Express Rider...',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF19251B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (order.assignedPartnerName != null &&
                                      order.assignedPartnerName!.isNotEmpty &&
                                      order.assignedPartnerName != 'Unassigned')
                                  ? 'Grocery Hub Express Partner ⭐ 4.9'
                                  : 'Our Baharagora Hub is dispatching your partner',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF758578),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (order.assignedPartnerPhone != null &&
                          order.assignedPartnerPhone!.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.phone_rounded,
                            color: Color(0xFF15803D),
                          ),
                          tooltip: 'Call Assigned Rider',
                          onPressed: () =>
                              _callRider(order.assignedPartnerPhone!),
                        )
                      else
                        const Tooltip(
                          message: 'Partner will be assigned upon dispatch',
                          child: Icon(
                            Icons.access_time_filled_rounded,
                            color: Color(0xFFF7C415),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 6. Items in Order
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items (${order.items.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF19251B),
                        ),
                      ),
                      const Divider(height: 16),
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: item.image.isNotEmpty
                                      ? FastCachedImage(
                                          imageUrl: item.image,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: const Color(0xFFFFF4B8),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${item.name} (${item.unit})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                'x${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Cancel Order Action with 5-minute live timer directly on the button
                if (!isCancelled && !isDelivered) ...[
                  const SizedBox(height: 24),
                  _CancelOrderCountdownButton(
                    order: order,
                    isCancelling: _isCancelling,
                    onCancelTap: () => _confirmCancelOrder(context, order),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepRow({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF15803D) : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isDone ? Icons.check_rounded : Icons.circle,
              size: 14,
              color: Colors.white,
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
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isCurrent
                      ? const Color(0xFF15803D)
                      : const Color(0xFF19251B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isDone}) {
    return Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: isDone ? const Color(0xFF15803D) : const Color(0xFFE5E7EB),
    );
  }
}

/// Dedicated isolated widget for the 5-minute countdown ticker so the parent screen doesn't rebuild every second
class _CancelOrderCountdownButton extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onCancelTap;
  final bool isCancelling;

  const _CancelOrderCountdownButton({
    required this.order,
    required this.onCancelTap,
    required this.isCancelling,
  });

  @override
  State<_CancelOrderCountdownButton> createState() =>
      _CancelOrderCountdownButtonState();
}

class _CancelOrderCountdownButtonState
    extends State<_CancelOrderCountdownButton> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsedSeconds =
        DateTime.now().difference(widget.order.createdAt).inSeconds;
    const int maxCancelWindowSeconds = 300; // 5 minutes = 300 seconds
    final remainingSeconds =
        (maxCancelWindowSeconds - elapsedSeconds).clamp(
          0,
          maxCancelWindowSeconds,
        );
    final bool canCancel = remainingSeconds > 0;
    final mins = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (remainingSeconds % 60).toString().padLeft(2, '0');

    if (canCancel) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: widget.isCancelling ? null : widget.onCancelTap,
          icon: const Icon(
            Icons.timer_outlined,
            color: Color(0xFFEF4444),
            size: 18,
          ),
          label: widget.isCancelling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFEF4444),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Cancel This Order ($mins:$secs)',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(
            Icons.lock_clock_rounded,
            color: Colors.grey,
            size: 18,
          ),
          label: const Text(
            'Cancellation Window Expired (5 Mins Over)',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            backgroundColor: const Color(0xFFF9FAFB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }
  }
}
