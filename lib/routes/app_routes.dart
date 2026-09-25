import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/order_success_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/orders/order_tracking_screen.dart';
import '../screens/product_detail/product_detail_screen.dart';
import '../screens/profile/complaints_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/help_support_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/refer_earn_screen.dart';
import '../screens/profile/saved_addresses_screen.dart';
import '../screens/profile/wishlist_screen.dart';
import '../screens/settings/theme_settings_screen.dart';
import '../screens/splash/splash_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String splash = '/splash';
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String savedAddresses = '/saved-addresses';
  static const String wishlist = '/wishlist';
  static const String referEarn = '/refer-earn';
  static const String complaints = '/complaints';
  static const String helpSupport = '/help-support';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String orderTracking = '/order-tracking';
  static const String productDetail = '/product-detail';

  static const String chat = '/chat';
  static const String themeSettings = '/theme-settings';
  static const String catalog = '/catalog';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        home: (context) => const HomeScreen(),
        onboarding: (context) => const OnboardingScreen(),
        login: (context) => const LoginScreen(),
        signup: (context) => const SignupScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        profile: (context) => const ProfileScreen(),
        editProfile: (context) => const EditProfileScreen(),
        savedAddresses: (context) => const SavedAddressesScreen(),
        wishlist: (context) => const WishlistScreen(),
        referEarn: (context) => const ReferEarnScreen(),
        complaints: (context) => const ComplaintsScreen(),
        helpSupport: (context) => const HelpSupportScreen(),
        checkout: (context) => const CheckoutScreen(),
        orderSuccess: (context) => const OrderSuccessScreen(),
        orderTracking: (context) => const OrderTrackingScreen(),
        productDetail: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is ProductModel) {
            return ProductDetailScreen(
              product: args,
              heroTag: 'hero_product_${args.id}',
            );
          } else if (args is Map<String, dynamic>) {
            return ProductDetailScreen(
              product: args['product'] as ProductModel,
              heroTag: args['heroTag'] as String?,
            );
          }
          return const HomeScreen();
        },

        chat: (context) => const ChatScreen(),
        themeSettings: (context) => const ThemeSettingsScreen(),
        catalog: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return CatalogScreen(
            title: args['title'] ?? 'Products Catalogue',
            categoryId: args['categoryId'],
            sectionType: args['sectionType'],
            searchTerm: args['searchTerm'] as String? ?? args['searchQuery'] as String?,
          );
        },
      };

  /// Smooth 300ms Hero-optimized transition to Product Detail Screen
  static Future<T?> navigateToProduct<T>(
    BuildContext context,
    ProductModel product, {
    String? heroTag,
  }) {
    final effectiveHeroTag = heroTag ?? 'hero_product_${product.id}';
    return Navigator.push<T>(
      context,
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductDetailScreen(
              product: product,
              heroTag: effectiveHeroTag,
            ),
        settings: RouteSettings(
          name: productDetail,
          arguments: {
            'product': product,
            'heroTag': effectiveHeroTag,
          },
        ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curveAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curveAnimation,
            child: child,
          );
        },
      ),
    );
  }

  /// Silky smooth 280ms Fade + Micro-Slide transition to Order Tracking
  static Future<T?> navigateToTracking<T>(
    BuildContext context,
    OrderModel order, {
    bool replace = false,
  }) {
    final route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const OrderTrackingScreen(),
      settings: RouteSettings(name: orderTracking, arguments: order),
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curveAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curveAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0.0),
              end: Offset.zero,
            ).animate(curveAnimation),
            child: child,
          ),
        );
      },
    );

    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }
}
