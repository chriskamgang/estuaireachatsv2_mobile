import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/notification_service.dart';
import '../main.dart' show navigatorKey;
import '../providers/auth_provider.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';
import 'search/search_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeIn)),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _controller.forward();

    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    final authProvider = context.read<AuthProvider>();

    // Load user session and wait minimum 3 seconds for splash animation
    await Future.wait([
      authProvider.loadUser(),
      Future.delayed(const Duration(seconds: 3)),
    ]);

    if (!mounted) return;

    Widget destination;
    if (authProvider.isAuthenticated) {
      destination = const MainScreen();
      // Verifier s'il y a des nouveaux produits pour la derniere recherche
      _checkSearchNotifications();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
      if (onboardingSeen) {
        destination = const MainScreen();
      } else {
        destination = const OnboardingScreen();
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  /// Verifie les notifications de recherche et configure le callback de navigation.
  void _checkSearchNotifications() {
    // Configure le callback pour naviguer vers la recherche au clic sur la notification
    NotificationService.onNotificationTap = (payload) {
      if (payload.startsWith('search:')) {
        final query = payload.substring(7);
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => SearchScreen(initialQuery: query),
          ),
        );
      }
    };

    // Lancer la verification en arriere-plan (fire-and-forget)
    NotificationService().checkSearchNotification();
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.white, Color(0xFFFFF0F0)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo image
                Image.asset(
                  'assets/images/logo.png',
                  width: 220,
                ),
                const SizedBox(height: 16),
                Text(
                  'Achetez partout en Afrique',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
