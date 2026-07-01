import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/core/services/push_notification_service.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    // Register listener for auth status to trigger push device token registration
    ref.listen(authControllerProvider, (previous, next) {
      if (next.user != null) {
        // User logged in, initialize push notification service and register token
        ref.read(pushNotificationServiceProvider).initialize();
      }
    });

    final authState = ref.watch(authControllerProvider);
    if (authState.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pushNotificationServiceProvider).initialize();
      });
    }

    return MaterialApp.router(
      title: 'AW-Dux',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
