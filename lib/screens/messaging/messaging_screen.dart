import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'chat_screen.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  static final refreshNotifier = ValueNotifier<int>(0);

  static void refresh() {
    refreshNotifier.value++;
  }

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();
  String _query = '';

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
    MessagingScreen.refreshNotifier.addListener(_onRefresh);
  }

  void _onRefresh() {
    _loadConversations();
  }

  @override
  void dispose() {
    MessagingScreen.refreshNotifier.removeListener(_onRefresh);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() {
        _loading = false;
        _error = 'auth';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService().get('/chat/conversations');
      final List data = res.data['data'] ?? [];
      final conversations = <Map<String, dynamic>>[];

      for (final conv in data) {
        final otherUser = conv['otherUser'] as Map<String, dynamic>? ?? {};
        final shop = conv['shop'] as Map<String, dynamic>? ?? {};
        final lastMessage = conv['lastMessage'] as Map<String, dynamic>? ?? {};
        final firstName = otherUser['firstName'] ?? '';
        final lastName = otherUser['lastName'] ?? '';
        final name = '$firstName $lastName'.trim();
        final company = shop['name'] ?? '';
        final content = lastMessage['content'] ?? '';
        final createdAt = lastMessage['createdAt'] ?? '';
        final unreadCount = conv['unreadCount'] ?? 0;

        // Format date
        String dateStr = '';
        if (createdAt.isNotEmpty) {
          try {
            final dt = DateTime.parse(createdAt);
            dateStr = '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
          } catch (_) {
            dateStr = createdAt;
          }
        }

        conversations.add({
          'id': conv['id']?.toString() ?? '',
          'name': name.isNotEmpty ? name : 'Utilisateur',
          'company': company,
          'message': content,
          'date': dateStr,
          'unread': unreadCount > 99 ? '99+' : '$unreadCount',
          'shopId': shop['id']?.toString() ?? '',
        });
      }

      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les conversations';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredConversations {
    if (_query.isEmpty) return _conversations;
    return _conversations.where((conv) {
      final name = (conv['name'] ?? '').toString().toLowerCase();
      final company = (conv['company'] ?? '').toString().toLowerCase();
      return name.contains(_query.toLowerCase()) || company.contains(_query.toLowerCase());
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated && _error == 'auth') {
      _loadConversations();
    } else if (!auth.isAuthenticated && !auth.isLoading && _error != 'auth') {
      setState(() {
        _loading = false;
        _error = 'auth';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher une conversation...',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.gray3),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 15),
              )
            : const Text('Messagerie', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          _searching
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _searching = false;
                    _query = '';
                    _searchController.clear();
                  }),
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _searching = true),
                ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error == 'auth') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 72, color: AppColors.gray4),
            const SizedBox(height: 16),
            const Text('Connectez-vous pour voir vos messages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray2)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(fontSize: 14, color: AppColors.gray2)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadConversations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_filteredConversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 72, color: AppColors.gray4),
            const SizedBox(height: 16),
            const Text('Aucune conversation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray2)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredConversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final conv = _filteredConversations[i];
        final unread = conv['unread'] ?? '0';
        final hasUnread = unread != '0';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.gray5,
            child: Text(
              (conv['name'] as String).isNotEmpty ? (conv['name'] as String)[0] : '?',
              style: const TextStyle(color: AppColors.gray2, fontWeight: FontWeight.w700),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  conv['name'] as String,
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                conv['date'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: hasUnread ? AppColors.orange : AppColors.gray3,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conv['company'] as String,
                style: const TextStyle(fontSize: 11, color: AppColors.gray3),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      conv['message'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasUnread ? AppColors.dark : AppColors.gray3,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unread,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatScreen(
                contactName: conv['name'] as String,
                company: conv['company'] as String,
                conversationId: conv['id'] as String,
              ),
            ));
          },
        );
      },
    );
  }
}
