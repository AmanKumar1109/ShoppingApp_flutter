import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grocery_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    // Check user persistence and auto-navigate after 2.2 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final grocery = ref.read(groceryProvider);
      if (grocery.isAppOutdated) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.appUpdate);
        return;
      }
      final auth = ref.read(authProvider);
      if (auth.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home).then((_) {
          NotificationService.instance.handlePendingInitialNotification();
        });
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color splashYellow = Color(0xFFF1CA00);

    return Scaffold(
      backgroundColor: splashYellow,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Image.asset(
                  'assets/images/splashScreenlogo.png',
                  width: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
