import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen un-dismissible block screen shown when the user's
/// mobile app version is older than the required minimum version set in the admin dashboard.
class AppUpdateBlockedScreen extends StatelessWidget {
  final String currentVersion;
  final String minVersion;
  final String updateUrl;
  final String? message;
  final VoidCallback? onCheckAgain;

  const AppUpdateBlockedScreen({
    super.key,
    required this.currentVersion,
    required this.minVersion,
    required this.updateUrl,
    this.message,
    this.onCheckAgain,
  });

  Future<void> _handleOpenUpdateUrl(BuildContext context) async {
    final effectiveUrl = updateUrl.trim().isNotEmpty
        ? updateUrl.trim()
        : 'https://play.google.com/store/apps/details?id=com.thegroceryhub.app';

    try {
      final uri = Uri.parse(effectiveUrl);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open update link: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFF7C415);
    const darkSlate = Color(0xFF19251B);

    return PopScope(
      canPop: false, // Prevent physical/gesture back button from dismissing
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated/Sleek Icon Container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFE885), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: brandYellow.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.system_update_rounded,
                          size: 58,
                          color: darkSlate,
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Version comparison pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Current: v$currentVersion',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4B8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: brandYellow),
                      ),
                      child: Text(
                        'Required: v$minVersion',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: darkSlate,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Headline
                const Text(
                  'App Update Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: darkSlate,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Description message
                Text(
                  (message != null && message!.trim().isNotEmpty)
                      ? message!.trim()
                      : 'A new version of The Grocery Hub is available with faster 10-minute delivery, new discounts, and essential fixes. Please update your app to continue shopping.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // Update Now Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _handleOpenUpdateUrl(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandYellow,
                      foregroundColor: darkSlate,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 20, color: darkSlate),
                        SizedBox(width: 8),
                        Text(
                          'Update App Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary Check Again Button
                if (onCheckAgain != null)
                  TextButton(
                    onPressed: onCheckAgain,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                    child: const Text(
                      'Check Again',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

