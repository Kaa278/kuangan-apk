import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kuangan/features/auth/auth_provider.dart';
import 'package:kuangan/features/auth/login_screen.dart';
import 'package:kuangan/features/auth/register_screen.dart';
import 'package:kuangan/features/auth/forgot_password_screen.dart';
import 'package:kuangan/features/auth/verify_email_screen.dart';
import 'package:kuangan/features/splash/splash_screen.dart';
import 'package:kuangan/features/dashboard/dashboard_screen.dart';
import 'package:kuangan/features/transactions/transactions_screen.dart';
import 'package:kuangan/features/ai_scan/ai_scan_screen.dart';
import 'package:kuangan/features/reports/reports_screen.dart';
import 'package:kuangan/features/settings/settings_screen.dart';
import 'navigation_shell.dart';
import 'theme.dart';

CustomTransitionPage<void> _buildAnimatedPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final isSplash = state.matchedLocation == '/';

      final isAuth = status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-email';

      if (isSplash) {
        return null;
      }

      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return null;
      }

      if (isAuth && isLoggingIn) {
        return '/dashboard';
      }

      if (!isAuth && !isLoggingIn) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildAnimatedPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildAnimatedPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildAnimatedPage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _buildAnimatedPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _buildAnimatedPage(
            key: state.pageKey,
            child: VerifyEmailScreen(
              email: (extra['email'] as String?) ?? '',
              name: (extra['name'] as String?) ?? '',
            ),
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => _buildAnimatedPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) => _buildAnimatedPage(
              key: state.pageKey,
              child: const TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: '/ai-scan',
            pageBuilder: (context, state) => _buildAnimatedPage(
              key: state.pageKey,
              child: const AiScanScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => _buildAnimatedPage(
              key: state.pageKey,
              child: const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _buildAnimatedPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );

  ref.listen(authProvider, (previous, next) {
    if (previous?.status != next.status) {
      router.refresh();
    }
  });

  return router;
});

class KuanganApp extends ConsumerWidget {
  const KuanganApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Kuangan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        platform: TargetPlatform.android, // Force Poco M3 behavior
      ),
      scrollBehavior: const MobileLikeScrollBehavior(),
      routerConfig: router,
    );
  }
}

/// Custom scroll behavior to allow mouse dragging (like on a mobile device)
class MobileLikeScrollBehavior extends MaterialScrollBehavior {
  const MobileLikeScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
