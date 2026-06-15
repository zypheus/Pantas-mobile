import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final authService = AuthService();
    final isAuthenticated = await authService.isAuthenticated();
    if (!mounted) return;
    if (isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Image.asset(
                          'assets/d.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.library_books_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: const Text(
                          'PANTAS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Text(
                          'Library Management System',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 64),
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2.5,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
