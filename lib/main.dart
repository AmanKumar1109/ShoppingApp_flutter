import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register top-level FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service non-blockingly
  NotificationService.instance.initialize();

  runApp(const ProviderScope(child: GroceryHubApp()));
}

class GroceryHubApp extends ConsumerWidget {
  const GroceryHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'GroceryHub',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRoutes.navigatorKey,
      theme: AppTheme.getTheme(currentTheme.currentThemeType),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
