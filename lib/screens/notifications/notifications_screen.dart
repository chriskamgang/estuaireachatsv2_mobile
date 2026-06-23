import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:estuaire_achats/core/theme.dart';
import '../../providers/notification_provider.dart';

// =============================================================================
// Types API → tabs
// =============================================================================

enum _TabCategory { all, orders, promos, system }

_TabCategory _categoryFromType(String? type) {
  switch (type?.toUpperCase()) {
    case 'ORDER':
    case 'PAYMENT':
    case 'DELIVERY':
      return _TabCategory.orders;
    case 'PROMOTION':
      return _TabCategory.promos;
    case 'SYSTEM':
    case 'MESSAGE':
    default:
      return _TabCategory.system;
  }
}

Color _colorFromType(String? type) {
  switch (type?.toUpperCase()) {
    case 'ORDER':
    case 'DELIVERY':
      return AppColors.green;
    case 'PAYMENT':
      return AppColors.blue;
    case 'PROMOTION':
      return AppColors.orange;
    case 'MESSAGE':
      return AppColors.primary;
    case 'SYSTEM':
    default:
      return AppColors.blue;
  }
}

IconData _iconFromType(String? type) {
  switch (type?.toUpperCase()) {
    case 'ORDER':
      return Icons.shopping_bag_outlined;
    case 'DELIVERY':
      return Icons.local_shipping_outlined;
    case 'PAYMENT':
      return Icons.payment_outlined;
    case 'PROMOTION':
      return Icons.local_offer_outlined;
    case 'MESSAGE':
      return Icons.chat_bubble_outline;
    case 'SYSTEM':
    default:
      return Icons.info_outline;
  }
}

// =============================================================================
// Screen
// =============================================================================

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Charge les donnees reelles au premier affichage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.fetchNotifications(page: 1);
      provider.fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Pagination : charge plus quand on arrive en bas
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().fetchNextPage();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<NotificationProvider>().fetchNotifications(page: 1);
    await context.read<NotificationProvider>().fetchUnreadCount();
  }

  Future<void> _markAllRead() async {
    await context.read<NotificationProvider>().markAllRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications marquees comme lues'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filteredNotifications(
    List<Map<String, dynamic>> all,
    int tabIndex,
  ) {
    if (tabIndex == 0) return all;
    final category = [
      _TabCategory.all,
      _TabCategory.orders,
      _TabCategory.promos,
      _TabCategory.system,
    ][tabIndex];
    return all
        .where((n) => _categoryFromType(n['type'] as String?) == category)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Tout marquer lu',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.orange,
          unselectedLabelColor: AppColors.gray3,
          indicatorColor: AppColors.orange,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Commandes'),
            Tab(text: 'Promotions'),
            Tab(text: 'Systeme'),
          ],
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: List.generate(4, (tabIndex) {
              final items =
                  _filteredNotifications(provider.notifications, tabIndex);

              if (items.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.orange,
                child: ListView.separated(
                  controller: tabIndex == 0 ? _scrollController : null,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length + (provider.hasMore && tabIndex == 0 ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.gray5,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    // Loader en bas de liste (tab "Toutes")
                    if (tabIndex == 0 && index == items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.orange,
                          ),
                        ),
                      );
                    }

                    final notif = items[index];
                    return _NotificationCard(
                      notification: notif,
                      onTap: () {
                        final id = notif['id'] as String?;
                        if (id != null) {
                          provider.markRead(id);
                        }
                      },
                    );
                  },
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.gray6,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 36,
              color: AppColors.gray3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vous n\'avez aucune notification\ndans cette categorie',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray3,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Notification card
// =============================================================================

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification['isRead'] == true;
    final String? type = notification['type'] as String?;
    final accentColor = _colorFromType(type);
    final icon = _iconFromType(type);
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final createdAt = notification['createdAt'] as String?;
    final time = createdAt != null
        ? DateTime.tryParse(createdAt) ?? DateTime.now()
        : DateTime.now();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isRead ? AppColors.white : AppColors.gray6,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barre coloree gauche
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icone
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          if (!isRead) _buildUnreadDot(accentColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray2,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimeAgo(time),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "A l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }
}
