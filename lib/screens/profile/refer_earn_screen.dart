import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grocery_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/share_service.dart';

class ReferEarnScreen extends ConsumerStatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  ConsumerState<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends ConsumerState<ReferEarnScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _copyToClipboard(BuildContext context, String code, {String? label}) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFFF7C415),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(label ?? 'Referral code "$code" copied!'),
          ],
        ),
        backgroundColor: const Color(0xFF19251B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareReferral(BuildContext context, String code, {Rect? origin}) {
    ShareService.shareReferral(code, sharePositionOrigin: origin);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final grocery = ref.watch(groceryProvider);

    final referralCode =
        (user?.myReferralCode != null && user!.myReferralCode.trim().isNotEmpty)
            ? user.myReferralCode.trim()
            : 'GROCERY100';

    final userId = user?.uid ?? '';
    final int rewardAmount = grocery.referrerRewardAmount.toInt();
    final int friendRewardAmount = grocery.referredUserRewardAmount.toInt();
    final int minOrderValue = grocery.referralMinOrderValue.toInt();

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
          'Refer & Earn ₹$rewardAmount',
          style: const TextStyle(
            color: Color(0xFF19251B),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Dynamic Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFF4B8),
                    Color(0xFFFFF9E0),
                    Color(0xFFF9FAFB),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF19251B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF7C415).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      size: 40,
                      color: Color(0xFFF7C415),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    grocery.referralBannerTitle.isNotEmpty
                        ? grocery.referralBannerTitle
                        : 'Invite Friends & Earn Rewards!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF19251B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share your code! When your friend places their first order above ₹$minOrderValue and it is delivered, BOTH of you unlock ₹$rewardAmount discount reward coupons!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Unique Referral Code Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF7C415),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF7C415).withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'YOUR UNIQUE REFERRAL CODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFF758578),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFDE68A),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            referralCode,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Color(0xFF19251B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _copyToClipboard(context, referralCode),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF19251B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.copy_rounded,
                                size: 15,
                                color: Color(0xFFF7C415),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _copyToClipboard(context, referralCode),
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            label: const Text('Copy Code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF19251B),
                              foregroundColor: const Color(0xFFF7C415),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Builder(
                            builder: (btnContext) {
                              return ElevatedButton.icon(
                                onPressed: () {
                                  final box = btnContext.findRenderObject() as RenderBox?;
                                  final origin = box != null
                                      ? box.localToGlobal(Offset.zero) & box.size
                                      : null;
                                  _shareReferral(context, referralCode, origin: origin);
                                },
                                icon: const Icon(Icons.share_rounded, size: 15),
                                label: const Text('Share Code'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF19251B),
                                  foregroundColor: const Color(0xFFF7C415),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  elevation: 0,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 3. Live Referral Performance Dashboard (Synced from Firestore)
            if (userId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.streamUserReferrals(userId),
                  builder: (context, snapshot) {
                    final referrals = snapshot.data ?? [];
                    final totalInvited = referrals.length;
                    final rewardedCount = referrals
                        .where((r) => r['status'] == 'REWARDED')
                        .length;
                    final pendingCount = referrals
                        .where((r) => r['status'] == 'REGISTERED')
                        .length;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
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
                              const Text(
                                'My Referral Activity',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF19251B),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFBBF7D0),
                                  ),
                                ),
                                child: Text(
                                  '₹${rewardedCount * rewardAmount} Won',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildMetricTile(
                                label: 'Friends Joined',
                                value: '$totalInvited',
                                color: const Color(0xFF19251B),
                                bg: const Color(0xFFF3F4F6),
                              ),
                              const SizedBox(width: 8),
                              _buildMetricTile(
                                label: 'Coupons Won',
                                value: '$rewardedCount',
                                color: const Color(0xFF15803D),
                                bg: const Color(0xFFECFDF5),
                              ),
                              const SizedBox(width: 8),
                              _buildMetricTile(
                                label: '1st Order Pending',
                                value: '$pendingCount',
                                color: const Color(0xFFB45309),
                                bg: const Color(0xFFFFFBEB),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 18),

            // 4. Live Unlocked Reward Coupons Section
            if (userId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.streamUserCoupons(userId),
                  builder: (context, snapshot) {
                    final coupons = snapshot.data ?? [];
                    final referralCoupons = coupons
                        .where((c) => c['isReferralCoupon'] == true)
                        .toList();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.confirmation_number_rounded,
                                size: 18,
                                color: Color(0xFFB88600),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'My Unlocked Reward Coupons',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF19251B),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${referralCoupons.length} Available',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF758578),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (referralCoupons.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF1F3F5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.card_giftcard_rounded,
                                    size: 28,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'No reward coupons unlocked yet',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Coupons appear here automatically after your invited friend receives their first grocery order!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: referralCoupons.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final c = referralCoupons[idx];
                                final code = (c['code'] ?? c['id'] ?? '').toString();
                                final discountVal = ((c['discountValue'] ??
                                        c['discount'] ??
                                        rewardAmount) as num)
                                    .toInt();
                                final minOrd = ((c['minOrderValue'] ?? 100) as num).toInt();

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFDE68A),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF19251B),
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Flat ₹$discountVal OFF',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF19251B),
                                              ),
                                            ),
                                            Text(
                                              'Min order ₹$minOrd',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _copyToClipboard(
                                          context,
                                          code,
                                          label: 'Coupon "$code" copied! Apply in checkout.',
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF19251B),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'COPY',
                                            style: TextStyle(
                                              color: Color(0xFFF7C415),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 18),

            // 5. How It Works Steps (Synchronized with Delivery Flow)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How Referral Rewards Work',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF19251B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildStep(
                      number: '1',
                      title: 'Share Your Code',
                      description:
                          'Send your referral code or invite link to friends and family.',
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      number: '2',
                      title: 'Friend Places Order Above ₹$minOrderValue',
                      description:
                          'They register using your code and place their first qualifying order.',
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      number: '3',
                      title: 'Both Earn Reward Coupons!',
                      description:
                          'As soon as their order is delivered, you get a ₹$rewardAmount OFF coupon and your friend gets a ₹$friendRewardAmount OFF coupon automatically!',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF4B8),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF19251B),
              ),
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF19251B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
