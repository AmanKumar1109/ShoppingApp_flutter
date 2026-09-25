import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Result returned after the WebView payment flow completes.
class SabPaisaWebViewResult {
  final bool success;
  final Map<String, String> queryParams;
  final String? errorMessage;

  const SabPaisaWebViewResult({
    required this.success,
    this.queryParams = const {},
    this.errorMessage,
  });
}

/// Opens the SabPaisa checkout page as a full-screen Flutter screen.
/// The user never leaves the app — payment page is embedded inside the app.
class SabPaisaWebViewScreen extends StatefulWidget {
  final String checkoutUrl;

  const SabPaisaWebViewScreen({super.key, required this.checkoutUrl});

  @override
  State<SabPaisaWebViewScreen> createState() => _SabPaisaWebViewScreenState();
}

class _SabPaisaWebViewScreenState extends State<SabPaisaWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasPopped = false;
  int _loadProgress = 0;

  // SabPaisa sends the user to these URL patterns when payment is done.
  static const List<String> _successPatterns = [
    'status=SUCCESS',
    'txnStatus=SUCCESS',
    'paymentStatus=SUCCESS',
  ];

  static const List<String> _terminalPatterns = [
    'status=FAILED',
    'status=CANCELLED',
    'status=EXPIRED',
    'txnStatus=FAILED',
    'txnStatus=CANCELLED',
    'payment-callback',
    'paymentCallback',
    'returnUrl',
    '/response',
    '/return',
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      );

    if (_controller.platform is AndroidWebViewController) {
      final android = _controller.platform as AndroidWebViewController;
      android.setMixedContentMode(MixedContentMode.alwaysAllow);
      android.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _checkCallbackUrl(url);
          },
          onProgress: (progress) {
            setState(() => _loadProgress = progress);
            if (progress >= 100) setState(() => _isLoading = false);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkCallbackUrl(url);
          },
          onNavigationRequest: (request) {
            final url = request.url;

            // 1. Intercept terminal/callback URLs before loading
            if (_isTerminalUrl(url)) {
              _handleCallbackUrl(url);
              return NavigationDecision.prevent;
            }

            // 2. Allow normal web URLs (cards, netbanking, bank OTP pages, etc.)
            // to load seamlessly inside the in-app WebView
            final lower = url.toLowerCase();
            if (lower.startsWith('http://') ||
                lower.startsWith('https://') ||
                lower.startsWith('about:') ||
                lower.startsWith('data:') ||
                lower.startsWith('javascript:')) {
              return NavigationDecision.navigate;
            }

            // 3. For UPI app intents & custom schemes (upi://, intent://, tez://, phonepe://, paytmmp://)
            // Prevent WebView from loading the unknown scheme (which causes net::ERR_UNKNOWN_URL_SCHEME)
            // and trigger the external payment app instead.
            _launchExternalPaymentApp(url);
            return NavigationDecision.prevent;
          },
          // DO NOT pop on web resource errors — SabPaisa pages have many
          // sub-resource loads (fonts, trackers, ads) that may fail.
          // Only log errors, never pop based on them.
          onWebResourceError: (error) {
            debugPrint(
              '[SabPaisa WebView] Resource error: '
              '${error.description} (mainFrame: ${error.isForMainFrame})',
            );
            // Do NOT call _popWithResult here — let the page keep loading
          },
          onHttpError: (error) {
            debugPrint(
              '[SabPaisa WebView] HTTP error ${error.response?.statusCode} '
              'on ${error.request?.uri}',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  /// Handles opening external UPI apps (GPay, PhonePe, Paytm, etc.) when the user
  /// clicks on a UPI payment option inside the embedded SabPaisa page.
  Future<void> _launchExternalPaymentApp(String url) async {
    try {
      Uri? uriToLaunch;

      if (url.startsWith('intent://') || url.startsWith('intent:')) {
        // Extract scheme if present in Android intent (e.g. scheme=upi or scheme=phonepe)
        final schemeMatch = RegExp(r'scheme=([^;]+)').firstMatch(url);
        final scheme = schemeMatch?.group(1) ?? 'upi';

        // Strip the #Intent;...;end portion
        final base = url.split('#Intent').first;
        final cleaned = base
            .replaceFirst(RegExp(r'^intent://'), '$scheme://')
            .replaceFirst(RegExp(r'^intent:'), '$scheme:');

        uriToLaunch = Uri.tryParse(cleaned);
      } else {
        uriToLaunch = Uri.tryParse(url);
      }

      if (uriToLaunch != null) {
        final canLaunch = await canLaunchUrl(uriToLaunch);
        if (canLaunch) {
          await launchUrl(uriToLaunch, mode: LaunchMode.externalApplication);
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selected payment app is not installed. You can also pay via Card, NetBanking, or enter a UPI ID directly on the page.',
            ),
            backgroundColor: Color(0xFF19251B),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[SabPaisa WebView] Error launching payment app: $e');
    }
  }

  bool _isTerminalUrl(String url) {
    final lower = url.toLowerCase();
    return [
      ..._successPatterns,
      ..._terminalPatterns,
    ].any((p) => lower.contains(p.toLowerCase()));
  }

  void _checkCallbackUrl(String url) {
    if (_isTerminalUrl(url)) {
      _handleCallbackUrl(url);
    }
  }

  void _handleCallbackUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final params = <String, String>{};
      uri.queryParameters.forEach((k, v) => params[k] = v);

      final status =
          (params['status'] ??
                  params['txnStatus'] ??
                  params['paymentStatus'] ??
                  '')
              .toUpperCase();

      final isSuccess =
          status == 'SUCCESS' || _successPatterns.any((p) => url.contains(p));

      _popWithResult(
        SabPaisaWebViewResult(
          success: isSuccess,
          queryParams: params,
          errorMessage: isSuccess ? null : 'Payment $status',
        ),
      );
    } catch (_) {
      _popWithResult(const SabPaisaWebViewResult(success: false));
    }
  }

  void _popWithResult(SabPaisaWebViewResult result) {
    if (_hasPopped || !mounted) return;
    _hasPopped = true;
    Navigator.pop(context, result);
  }

  Future<bool> _onWillPop() async {
    // Check if WebView can go back first
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }

    // Otherwise show cancel confirmation
    if (!mounted) return false;
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Cancel Payment?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Are you sure? Your cart will be preserved and you can retry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Paying'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF19251B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      _popWithResult(
        const SabPaisaWebViewResult(
          success: false,
          errorMessage: 'Payment cancelled by user.',
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF19251B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Cancel Payment',
            onPressed: _onWillPop,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7C415),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SabPaisa',
                  style: TextStyle(
                    color: Color(0xFF19251B),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Secure Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          actions: [
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.lock_rounded,
                color: Color(0xFF4ADE80),
                size: 20,
              ),
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _loadProgress < 100 ? _loadProgress / 100 : null,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFF7C415)),
                    minHeight: 3,
                  ),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
