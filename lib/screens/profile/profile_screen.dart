import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_bar_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your Grocery Hub account?',
          style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(authProvider).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
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
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final addressesCount = user?.addresses.length ?? 0;
    final wishlistCount = user?.wishlist.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Soft Yellow Header matching Home Screen
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeAppBarWidget(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF19251B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFFF7C415),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'My Account & Dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF19251B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          // Dashboard Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                children: [
                  // 1. User Hero Profile Card
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
                    child: Row(
                      children: [
                        // Avatar with Tap to Edit
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.editProfile,
                          ),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: const Color(0xFFFFF4B8),
                                backgroundImage:
                                    (user?.photoURL != null &&
                                        user!.photoURL!.isNotEmpty)
                                    ? CachedNetworkImageProvider(user.photoURL!)
                                    : null,
                                child:
                                    (user?.photoURL == null ||
                                        user!.photoURL!.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Color(0xFF19251B),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF19251B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 12,
                                    color: Color(0xFFF7C415),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Name, Email, Phone
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Guest User',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF152C1E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? 'Not logged in',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (user?.phone != null && user!.phone.isNotEmpty)
                                Text(
                                  '+91 ${user.phone}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF19251B),
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.editProfile,
                                  ),
                                  child: const Text(
                                    '+ Add phone number',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Edit Arrow Icon Button
                        IconButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.editProfile,
                          ),
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFF19251B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Metrics Summary Row (Addresses, Wishlist, Referral Code)
                  Row(
                    children: [
                      // Addresses Metric
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          icon: Icons.location_on_outlined,
                          title: '$addressesCount Addresses',
                          subtitle: 'Delivery Loc',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.savedAddresses,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Wishlist Metric
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          icon: Icons.favorite_border_rounded,
                          title: '$wishlistCount Items',
                          subtitle: 'Saved Wishlist',
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.wishlist),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Referral Metric
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          icon: Icons.card_giftcard_rounded,
                          title: 'Refer & Earn',
                          subtitle: 'Get ₹100',
                          isHighlighted: true,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.referEarn),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // 3. Category: Account & Personal
                  _buildSectionHeader('Account & Personal'),
                  _buildMenuContainer([
                    _buildMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile Information',
                      subtitle: 'Name, phone number, and avatar',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.editProfile),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Delivery Addresses',
                      subtitle: user?.addresses.isNotEmpty == true
                          ? '${user!.addresses.first.locality}, Baharagora'
                          : 'Manage shipping locations',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.savedAddresses,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // 4. Category: Shopping & Rewards
                  _buildSectionHeader('Shopping & Rewards'),
                  _buildMenuContainer([
                    _buildMenuItem(
                      icon: Icons.favorite_border_rounded,
                      title: 'My Wishlist',
                      subtitle: '$wishlistCount saved favorite items',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.wishlist),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.card_giftcard_rounded,
                      title: 'Refer & Earn Program',
                      subtitle:
                          'Code: ${user?.myReferralCode ?? "GROCERY100"} • Earn ₹100',
                      badge: '₹100 BONUS',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.referEarn),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // 5. Category: Help & Support
                  _buildSectionHeader('Customer Support'),
                  _buildMenuContainer([
                    _buildMenuItem(
                      icon: Icons.support_agent_rounded,
                      title: 'Tickets & Complaints',
                      subtitle: 'File issues and track resolution status',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.complaints),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help, FAQs & WhatsApp Care',
                      subtitle: 'Instant WhatsApp chat & hotline support',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.helpSupport),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'In-App Support Chat',
                      subtitle: 'Chat live with Grocery Hub assistant',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.chat),
                    ),
                  ]),

                  // 6. Logout Button
                  if (user != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF2F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFFEF4444),
                        ),
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF758578),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF4B8),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF19251B), size: 18),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF19251B),
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF9CA3AF),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFFF7C415)
                : const Color(0xFFEEEEEE),
            width: isHighlighted ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? const Color(0xFFF7C415).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isHighlighted
                  ? const Color(0xFFD97706)
                  : const Color(0xFF19251B),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isHighlighted
                    ? const Color(0xFF92400E)
                    : const Color(0xFF19251B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
