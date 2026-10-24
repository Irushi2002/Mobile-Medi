import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_router.dart';
import '../utils/app_colors.dart';

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
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));
    _scaleAnimation =
        Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ));
    _controller.forward();

    // Listen for auth state to settle, then navigate.
    // We wait at minimum 1.5 s so the splash animation is visible,
    // but we do NOT navigate until Firebase has resolved the session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForAuthAndNavigate();
    });
  }

  Future<void> _waitForAuthAndNavigate() async {
    // Ensure splash is shown for at least 1.5 seconds.
    final minimumDelay = Future.delayed(const Duration(milliseconds: 1500));

    // Wait until auth is no longer in an intermediate state.
    // A 10-second timeout is a safety net in case the network is unavailable.
    final authProvider = context.read<AuthProvider>();
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while ((authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.loading) &&
        DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    await minimumDelay;
    _navigate();
  }

  void _navigate() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    final authProvider = context.read<AuthProvider>();
    if (authProvider.status == AuthStatus.authenticated) {
      if (authProvider.needsPrivacyAccept) {
        Navigator.pushReplacementNamed(context, AppRouter.privacyPolicy);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.login);
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
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'MediHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Health, Connected',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}