import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../routes/app_routes.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<Map<String, String>> faqs = [
    {
      'question': 'How fast is delivery in Baharagora?',
      'answer':
          'We guarantee express 15-minute grocery delivery across Baharagora town, Main Market, Central Station area, and nearby localities within 5 km of our store hub.',
    },
    {
      'question': 'What is the 6-digit Delivery OTP?',
      'answer':
          'For your security, every order generates a unique 6-digit OTP visible in your Order Details screen. Simply share this OTP with our delivery rider when they hand over your grocery package.',
    },
    {
      'question': 'What is the return & replacement policy for fresh items?',
      'answer':
          'If any fruits, vegetables, dairy, or grocery items arrive damaged or substandard, you can file a quick ticket or message us on WhatsApp within 2 hours of delivery for an instant replacement or full refund to your wallet.',
    },
    {
      'question': 'Which payment methods are accepted?',
      'answer':
          'We accept UPI (Google Pay, PhonePe, Paytm), Credit/Debit Cards, Net Banking, and Cash on Delivery (COD) across all pincodes.',
    },
    {
      'question': 'How does the Refer & Earn program work?',
      'answer':
          'Share your unique referral code with friends. When they place their first grocery order above ₹199, they get ₹50 OFF and you receive ₹100 instant Grocery Hub credits!',
    },
  ];

  void _copySupportContact(BuildContext context, String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
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
            Text('$type copied to clipboard: $text'),
          ],
        ),
        backgroundColor: const Color(0xFF19251B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Help & Customer Support',
          style: TextStyle(
            color: Color(0xFF19251B),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Contact Header Cards
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    context: context,
                    icon: Icons.chat_rounded,
                    iconBg: const Color(0xFF25D366),
                    title: 'WhatsApp Chat',
                    subtitle: 'Instant response',
                    onTap: () => _copySupportContact(
                      context,
                      '+91 98765 43210',
                      'WhatsApp Number',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactCard(
                    context: context,
                    icon: Icons.phone_in_talk_rounded,
                    iconBg: const Color(0xFF19251B),
                    title: 'Customer Care',
                    subtitle: '+91 98765 43210',
                    onTap: () => _copySupportContact(
                      context,
                      '+91 98765 43210',
                      'Customer Care Hotline',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // File Ticket Shortcut Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4B8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF7C415)),
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
                      Icons.receipt_long_rounded,
                      color: Color(0xFFF7C415),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Have an issue with an order?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF19251B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'File a complaint ticket for rapid resolution',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.complaints);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19251B),
                      foregroundColor: const Color(0xFFF7C415),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tickets',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // FAQ Section Header
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF19251B),
              ),
            ),
            const SizedBox(height: 14),

            // FAQ Accordion
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: const Color(0xFF19251B),
                      collapsedIconColor: Colors.grey[600],
                      title: Text(
                        faq['question']!,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF19251B),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            faq['answer']!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4B5563),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF19251B),
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
    );
  }
}
