import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../routes/app_routes.dart';
import '../services/firestore_service.dart';

class NotificationEndDrawer extends ConsumerWidget {
  const NotificationEndDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);
    final notifications = notifState.notifications;
    final isLoading = notifState.isLoading;
    final unreadCount = notifState.unreadCount;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.88,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4B8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFFB88600),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF19251B),
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7C415),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadCount New',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF19251B),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearAll(context, ref),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // 2. Notification Items List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF7C415)),
                      ),
                    )
                  : notifications.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: notifications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = notifications[index];
                            return _buildDismissibleNotificationCard(
                              context,
                              ref,
                              item,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State when user has no active notifications
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 36,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF19251B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You're all caught up! Orders status, exclusive discounts, and referral rewards will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Notification item wrapped with smooth Swipe-to-Delete (Dismissible)
  Widget _buildDismissibleNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationModel item,
  ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        ref.read(notificationProvider).dismiss(item);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed: "${item.title}"'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF19251B),
          ),
        );
      },
      child: _buildNotificationCard(context, ref, item),
    );
  }

  /// Individual Card Display
  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationModel item,
  ) {
    final style = _resolveNotificationStyle(item);

    return InkWell(
      onTap: () => _handleNotificationTap(context, ref, item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFFFFDF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFEEEEEE)
                : const Color(0xFFFDE68A),
            width: item.isRead ? 1 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Icon Container
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: style.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.iconColor, size: 18),
            ),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                item.isRead ? FontWeight.w700 : FontWeight.w900,
                            color: const Color(0xFF19251B),
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.timeAgo,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey[700],
                      height: 1.35,
                    ),
                  ),

                  // Optional Image Banner
                  if (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl!.trim(),
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],

                  // Action Pill (e.g. Order Tracking or Referral)
                  if (item.orderId != null && item.orderId!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Order #${item.orderId}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 9,
                            color: Color(0xFF334155),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Unread Dot Indicator
            if (!item.isRead) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7C415),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Resolves icon & colors based on notification type and status
  _NotificationStyle _resolveNotificationStyle(NotificationModel item) {
    final status = (item.status ?? '').toLowerCase();
    final type = item.type.toLowerCase();
    final title = item.title.toLowerCase();

    if (status.contains('cancel') || title.contains('cancel')) {
      return _NotificationStyle(
        icon: Icons.cancel_rounded,
        iconColor: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEE2E2),
      );
    }

    if (status.contains('deliver') || title.contains('delivered')) {
      return _NotificationStyle(
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF16A34A),
        bgColor: const Color(0xFFDCFCE7),
      );
    }

    if (status.contains('out for delivery') || title.contains('on the way')) {
      return _NotificationStyle(
        icon: Icons.delivery_dining_rounded,
        iconColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
      );
    }

    if (type == 'referral' || title.contains('referral') || title.contains('reward')) {
      return _NotificationStyle(
        icon: Icons.card_giftcard_rounded,
        iconColor: const Color(0xFF9333EA),
        bgColor: const Color(0xFFF3E8FF),
      );
    }

    if (type == 'broadcast' || title.contains('sale') || title.contains('discount')) {
      return _NotificationStyle(
        icon: Icons.campaign_rounded,
        iconColor: const Color(0xFFB88600),
        bgColor: const Color(0xFFFFF4B8),
      );
    }

    return _NotificationStyle(
      icon: Icons.shopping_bag_rounded,
      iconColor: const Color(0xFF0284C7),
      bgColor: const Color(0xFFE0F2FE),
    );
  }

  /// Handles user tapping on a notification in the drawer
  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel item,
  ) async {
    ref.read(notificationProvider).markAsRead(item);

    // Close drawer first
    Navigator.pop(context);

    // If order notification with orderId, navigate directly to live order tracking
    if (item.orderId != null && item.orderId!.isNotEmpty) {
      try {
        final order = await FirestoreService().getOrder(item.orderId!);
        if (order != null && context.mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.orderTracking,
            arguments: order,
          );
          return;
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

    // Route-based Navigation
    final route = (item.route ?? '').trim();
    if (route == '/orders' || item.type == 'order') {
      Navigator.pushNamed(context, AppRoutes.orders);
    } else if (route == '/coupons' || item.type == 'referral') {
      Navigator.pushNamed(context, AppRoutes.referEarn);
    } else if (route == '/cart') {
      Navigator.pushNamed(context, AppRoutes.cart);
    } else if (route == '/complaints') {
      Navigator.pushNamed(context, AppRoutes.complaints);
    } else if (route == '/catalog') {
      Navigator.pushNamed(context, AppRoutes.catalog);
    }
  }

  /// Dialog confirmation to Clear All notifications
  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Clear All Notifications?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF19251B),
            ),
          ),
          content: const Text(
            'Are you sure you want to remove all notifications? This action cannot be undone.',
            style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                ref.read(notificationProvider).clearAll();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationStyle {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  _NotificationStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
