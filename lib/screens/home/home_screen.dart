import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/grocery_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/floating_cart_bar.dart';
import '../../widgets/notification_drawer.dart';
import '../cart/cart_screen.dart';
import '../categories/categories_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../update/app_update_blocked_screen.dart';
import 'home_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Request notification permission smoothly after user arrives and UI settles on Home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          NotificationService.instance.requestNotificationPermission();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final grocery = ref.watch(groceryProvider);

    // Block app immediately if version is outdated
    if (grocery.isAppOutdated) {
      return AppUpdateBlockedScreen(
        currentVersion: grocery.currentAppVersion,
        minVersion: grocery.minAppVersion,
        updateUrl: grocery.appUpdateUrl,
        message: grocery.appUpdateMessage,
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentBottomNavIndex,
            children: [
              const HomeTab(),
              CategoriesScreen(
                onSelectCategory: () {
                  setState(() {
                    _currentBottomNavIndex =
                        0; // Filter applied, switch back to home
                  });
                },
              ),
              CartScreen(
                onExploreGroceries: () {
                  setState(() {
                    _currentBottomNavIndex = 0;
                  });
                },
              ),
              const OrdersScreen(),
              const ProfileScreen(),
            ],
          ),
          if (_currentBottomNavIndex != 2)
            FloatingCartBar(
              onTap: () {
                setState(() {
                  _currentBottomNavIndex = 2; // Open Cart Tab
                });
              },
            ),
        ],
      ),
      endDrawer: const NotificationEndDrawer(),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() {
            _currentBottomNavIndex = index;
          });
        },
      ),
    );
  }
}
