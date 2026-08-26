import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kuangan/features/auth/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _minimumSplashDuration = Duration(milliseconds: 3000);
  static const _nativeLikeIconSize = 112.0;

  late final AnimationController _contentController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;

  DateTime? _startedAt;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) {
        _contentController.forward();
      }
    });

    ref.listenManual<AuthState>(authProvider, (previous, next) {
      _handleNavigation(next);
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation(AuthState authState) async {
    if (_hasNavigated) return;
    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      return;
    }

    final startedAt = _startedAt;
    if (startedAt != null) {
      final elapsed = DateTime.now().difference(startedAt);
      final remaining = _minimumSplashDuration - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
    }

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    if (authState.status == AuthStatus.authenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const _SplashBackdrop(),
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _contentController,
                      _pulseController,
                    ]),
                    builder: (context, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(0, _slideAnimation.value * 0.35),
                            child: ScaleTransition(
                              scale: _pulseAnimation,
                              child: Transform.scale(
                                scale: 1.0 - (_fadeAnimation.value * 0.02),
                                child: Image.asset(
                                  'assets/images/app_launcher_icon.png',
                                  width: _nativeLikeIconSize,
                                  height: _nativeLikeIconSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Opacity(
                            opacity: _fadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Kuangan',
                                      style: TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Kelola cerdas, hidup bebas.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    SizedBox(height: 28),
                                    _SplashLoader(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -78,
          right: -54,
          child: Container(
            width: 224,
            height: 224,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF6F7FB),
            ),
          ),
        ),
        Positioned(
          bottom: -86,
          left: -62,
          child: Container(
            width: 196,
            height: 196,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF7F8FC),
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashLoader extends StatefulWidget {
  const _SplashLoader();

  @override
  State<_SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<_SplashLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final progress =
                (_controller.value - (index * 0.18)).clamp(0.0, 1.0);
            final opacity = 0.25 +
                ((1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.75);

            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
