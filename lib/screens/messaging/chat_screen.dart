import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../shop/shop_screen.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String company;
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.contactName,
    required this.company,
    this.conversationId = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _showQuickReplies = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.conversationId.isNotEmpty) {
      _loadMessages();
      _markAsRead();
    } else {
      // No conversation ID: show local placeholder messages
      _messages.addAll([
        _ChatMessage(
          text: 'Bonjour ! Bienvenue chez ${widget.company}. Comment puis-je vous aider ?',
          isMe: false,
          time: '10:00',
          type: _MessageType.text,
        ),
        _ChatMessage(
          text: '',
          isMe: false,
          time: '10:01',
          type: _MessageType.businessCard,
        ),
      ]);
      _loading = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService().get('/chat/messages/${widget.conversationId}');
      final List data = res.data['data'] ?? [];
      final messages = <_ChatMessage>[];

      for (final msg in data) {
        final content = msg['content'] ?? '';
        final createdAt = msg['createdAt'] ?? '';
        String timeStr = '';
        if (createdAt.isNotEmpty) {
          try {
            final dt = DateTime.parse(createdAt);
            timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {
            timeStr = '';
          }
        }

        messages.add(_ChatMessage(
          text: content,
          isMe: msg['isOwn'] == true,
          time: timeStr,
          type: _MessageType.text,
        ));
      }

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _loading = false;
        if (_messages.isNotEmpty) _showQuickReplies = true;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les messages';
      });
    }
  }

  Future<void> _markAsRead() async {
    try {
      await ApiService().post('/chat/mark-read/${widget.conversationId}');
    } catch (_) {
      // Silent fail for mark-read
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final trimmed = text.trim();

    setState(() {
      _messages.add(_ChatMessage(
        text: trimmed,
        isMe: true,
        time: TimeOfDay.now().format(context),
        type: _MessageType.text,
      ));
      _showQuickReplies = false;
    });
    _controller.clear();
    _scrollToBottom();

    if (widget.conversationId.isEmpty) return;

    try {
      await ApiService().post('/chat/send', data: {
        'conversationId': widget.conversationId,
        'content': trimmed,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi du message')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.contactName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.company,
              style: const TextStyle(fontSize: 11, color: AppColors.gray3),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(fontSize: 14, color: AppColors.gray2)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessage(msg);
                        },
                      ),
          ),
          // Quick replies
          if (_showQuickReplies && !_loading && _error == null) _buildQuickReplies(),
          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // --- Messages ---

  Widget _buildMessage(_ChatMessage msg) {
    if (msg.type == _MessageType.businessCard) {
      return _buildBusinessCard();
    }

    final isMe = msg.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.gray5,
              child: Text(
                widget.contactName.isNotEmpty ? widget.contactName[0] : '?',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray2),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: msg.type == _MessageType.file
                      ? const EdgeInsets.all(10)
                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.orange : AppColors.gray6,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: msg.type == _MessageType.file
                      ? _buildFileContent(msg, isMe)
                      : Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? Colors.white : AppColors.dark,
                            height: 1.4,
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  msg.time,
                  style: const TextStyle(fontSize: 10, color: AppColors.gray3),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildFileContent(_ChatMessage msg, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe ? Colors.white24 : AppColors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.description_outlined,
            size: 24,
            color: isMe ? Colors.white : AppColors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : AppColors.dark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'PDF - 2.4 MB',
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : AppColors.gray3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.download_outlined,
          size: 20,
          color: isMe ? Colors.white : AppColors.gray3,
        ),
      ],
    );
  }

  Widget _buildBusinessCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.gray5,
            child: Text(
              widget.contactName.isNotEmpty ? widget.contactName[0] : '?',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.gray5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business, color: AppColors.orange, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.contactName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                            ),
                            Text(
                              widget.company,
                              style: const TextStyle(fontSize: 11, color: AppColors.gray3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _CardInfo(icon: Icons.verified, label: 'Vérifié', color: AppColors.green),
                      const SizedBox(width: 16),
                      _CardInfo(icon: Icons.access_time, label: '5+ ans', color: AppColors.blue),
                      const SizedBox(width: 16),
                      _CardInfo(icon: Icons.star, label: '4.7/5', color: AppColors.orange),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(shopName: widget.company)));
                      },
                      icon: const Icon(Icons.storefront, size: 16),
                      label: const Text('Voir la boutique', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: AppColors.orange),
                        foregroundColor: AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Quick Replies ---

  Widget _buildQuickReplies() {
    final quickReplies = [
      'Demande de commande',
      'Voir options de paiement',
      'Delai de livraison ?',
      'Demander un echantillon',
      'Obtenir un devis',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray5, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions rapides',
            style: TextStyle(fontSize: 11, color: AppColors.gray3, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickReplies.map((text) {
              return GestureDetector(
                onTap: () => _sendMessage(text),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.orange.withAlpha(100)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Input Bar ---

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray5)),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.gray2),
            onPressed: () => _showAttachmentOptions(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.gray6,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message...',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.gray3),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        filled: false,
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(_focusNode);
                    },
                    child: const Icon(Icons.emoji_emotions_outlined, size: 22, color: AppColors.gray3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Send button
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // --- Attachment Options ---

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AttachOption(icon: Icons.camera_alt, label: 'Caméra', color: AppColors.orange, onTap: () => Navigator.pop(ctx)),
                    _AttachOption(icon: Icons.photo_library, label: 'Galerie', color: AppColors.green, onTap: () => Navigator.pop(ctx)),
                    _AttachOption(icon: Icons.description, label: 'Document', color: AppColors.blue, onTap: () => Navigator.pop(ctx)),
                    _AttachOption(icon: Icons.location_on, label: 'Position', color: AppColors.red, onTap: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Chat Settings ---

  void _showChatSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: const Text('Epingler la conversation', style: TextStyle(fontSize: 14)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off_outlined),
                title: const Text('Desactiver les notifications', style: TextStyle(fontSize: 14)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.note_alt_outlined),
                title: const Text('Ajouter une note', style: TextStyle(fontSize: 14)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Rechercher dans la conversation', style: TextStyle(fontSize: 14)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Documents partages', style: TextStyle(fontSize: 14)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.red),
                title: const Text('Effacer la conversation', style: TextStyle(fontSize: 14, color: AppColors.red)),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ====================================================================
// Models & Helper Widgets
// ====================================================================

enum _MessageType { text, file, businessCard }

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final _MessageType type;

  const _ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    required this.type,
  });
}

class _CardInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CardInfo({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray2)),
        ],
      ),
    );
  }
}
