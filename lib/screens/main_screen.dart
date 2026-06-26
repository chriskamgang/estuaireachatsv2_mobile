import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'categories/categories_screen.dart';
import 'messaging/messaging_screen.dart';
import 'cart/cart_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Timer? _notifTimer;

  final _screens = const [
    HomeScreen(),
    CategoriesScreen(),
    MessagingScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch initial unread count + poll every 30s
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifProvider = context.read<NotificationProvider>();
      notifProvider.fetchUnreadCount();
      _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        notifProvider.fetchUnreadCount();
      });
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final msgBadge = isAuthenticated && unreadCount > 0;
    final msgLabel = unreadCount > 99 ? '99+' : '$unreadCount';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 2) MessagingScreen.refresh();
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: msgBadge,
              label: Text(msgLabel, style: const TextStyle(fontSize: 8)),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: msgBadge,
              label: Text(msgLabel, style: const TextStyle(fontSize: 8)),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Messagerie',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount', style: const TextStyle(fontSize: 8)),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount', style: const TextStyle(fontSize: 8)),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Panier',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Mon EA',
          ),
        ],
      ),
    );
  }
}
