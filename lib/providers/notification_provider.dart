import 'package:flutter/material.dart';
import '../core/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  int unreadCount = 0;
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _perPage = 20;

  bool get hasMore => _hasMore;

  // ---------------------------------------------------------------------------
  // Charge la premiere page (ou recharge)
  // ---------------------------------------------------------------------------

  Future<void> fetchNotifications({int page = 1}) async {
    if (page == 1) {
      loading = true;
      notifications = [];
      _hasMore = true;
      _currentPage = 1;
      notifyListeners();
    }

    try {
      final response = await ApiService().get(
        '/notifications',
        params: {'page': page, 'perPage': _perPage},
      );

      final data = response.data['data'] as List? ?? [];
      final meta = response.data['meta'] as Map<String, dynamic>?;

      final items = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (page == 1) {
        notifications = items;
      } else {
        notifications = [...notifications, ...items];
      }

      _currentPage = page;

      // Determine s'il y a encore des pages
      final totalPages = (meta?['totalPages'] as num?)?.toInt() ?? 1;
      _hasMore = page < totalPages;
    } catch (e) {
      print('fetchNotifications error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Charge la page suivante (pagination)
  // ---------------------------------------------------------------------------

  Future<void> fetchNextPage() async {
    if (!_hasMore || loading) return;
    await fetchNotifications(page: _currentPage + 1);
  }

  // ---------------------------------------------------------------------------
  // Compte non lus
  // ---------------------------------------------------------------------------

  Future<void> fetchUnreadCount() async {
    // Ne pas appeler si pas de token (utilisateur non connecte)
    final token = await ApiService().getToken();
    if (token == null) return;
    try {
      final response = await ApiService().get('/notifications/unread-count');
      unreadCount = (response.data['data']['count'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (e) {
      // Silence 401 errors for unauthenticated users
    }
  }

  // ---------------------------------------------------------------------------
  // Marque une notif comme lue
  // ---------------------------------------------------------------------------

  Future<void> markRead(String id) async {
    try {
      await ApiService().post('/notifications/mark-read/$id');

      // Mise a jour locale immediate
      final index = notifications.indexWhere((n) => n['id'] == id);
      if (index != -1 && notifications[index]['isRead'] == false) {
        notifications[index] = {...notifications[index], 'isRead': true};
        if (unreadCount > 0) unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      print('markRead error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Marque tout comme lu
  // ---------------------------------------------------------------------------

  Future<void> markAllRead() async {
    try {
      await ApiService().post('/notifications/mark-all-read');

      // Mise a jour locale immediate
      notifications = notifications
          .map((n) => {...n, 'isRead': true})
          .toList();
      unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('markAllRead error: $e');
    }
  }
}
