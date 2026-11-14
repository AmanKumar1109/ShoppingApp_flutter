import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'notification_drawer.dart';

class HomeAppBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAppBarWidget({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    String deliveryAddressText = 'Baharagora, Jharkhand';
    String addressLabel = 'Delivering to';

    if (user != null && user.addresses.isNotEmpty) {
      final primary = user.addresses.firstWhere(
        (a) => a.id == user.primaryAddressId,
        orElse: () => user.addresses.first,
      );
      if (primary.location.trim().isNotEmpty) {
        deliveryAddressText = primary.location.trim();
        addressLabel = '${primary.type} - Delivering to';
      } else if (primary.street.trim().isNotEmpty) {
        deliveryAddressText = '${primary.street}, ${primary.city}';
        addressLabel = '${primary.type} - Delivering to';
      }
    }

    return Container(
      padding: const EdgeInsets.only(top: 48, left: 20, right: 20, bottom: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFF4B8), // Soft pale yellow header background
            Color(0xFFFFF9E0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Location Display
          Expanded(
            child: InkWell(
              onTap: () {
                _showAddressSelectionSheet(context, user, ref);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        addressLabel,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF19251B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          deliveryAddressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF152C1E),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Bell Notification Button
          Builder(
            builder: (context) {
              final notifState = ref.watch(notificationProvider);
              final unreadCount = notifState.unreadCount;

              return GestureDetector(
                onTap: () {
                  final scaffold = Scaffold.maybeOf(context);
                  if (scaffold != null && scaffold.hasEndDrawer) {
                    scaffold.openEndDrawer();
                  } else {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Notifications',
                      barrierColor: Colors.black.withValues(alpha: 0.35),
                      pageBuilder: (ctx, _, __) => const Align(
                        alignment: Alignment.centerRight,
                        child: NotificationEndDrawer(),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF152C1E),
                          size: 22,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            constraints: const BoxConstraints(
                              minWidth: 15,
                              minHeight: 15,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7C415),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Color(0xFF19251B),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
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
        ],
      ),
    );
  }

  void _showAddressSelectionSheet(
    BuildContext context,
    UserModel? user,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final addresses = user?.addresses ?? [];
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_city_rounded, color: Color(0xFFF7C415)),
                  SizedBox(width: 10),
                  Text(
                    'Select Delivery Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF19251B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (addresses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Delivering to: Baharagora, Jharkhand (Default Zone)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF19251B),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...addresses.map<Widget>((addr) {
                  final isSelected = addr.id == user?.primaryAddressId;
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        addr.type == 'Home'
                            ? Icons.home_rounded
                            : Icons.work_rounded,
                        color: const Color(0xFFF7C415),
                      ),
                      title: Text(
                        addr.name.isNotEmpty ? addr.name : addr.type,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(addr.location),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                            )
                          : null,
                      onTap: () {
                        ref.read(authProvider).setPrimaryAddress(addr.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
