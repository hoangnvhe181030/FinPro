import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/utils/formatters.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/chat/conversations/$userId');
      setState(() {
        _conversations = List<Map<String, dynamic>>.from(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading conversations: $e');
    }
  }

  void _startNewChat() async {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return;

    try {
      final api = context.read<ApiService>();
      final response = await api.get('/chat/users/$userId');
      final users = List<Map<String, dynamic>>.from(response.data);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _buildUserList(users),
      );
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('New Conversation', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = (user['fullName'] as String?)?.isNotEmpty == true
                  ? user['fullName']
                  : user['username'];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (name as String)[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('@${user['username']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _openChat(
                    (user['userId'] as num).toInt(),
                    user['username'] as String,
                    user['fullName'] as String?,
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _openChat(int otherUserId, String username, String? fullName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: otherUserId,
          otherUsername: username,
          otherFullName: fullName,
        ),
      ),
    );
    _loadConversations(); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Messages', style: Theme.of(context).textTheme.displayMedium),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_rounded, color: AppColors.accent, size: 20),
                    ),
                    onPressed: _startNewChat,
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_conversations.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text('No conversations yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _startNewChat,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Start a chat'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final conv = _conversations[index];
                  final name = (conv['otherFullName'] as String?)?.isNotEmpty == true
                      ? conv['otherFullName'] as String
                      : conv['otherUsername'] as String;
                  final unread = (conv['unreadCount'] as num?)?.toInt() ?? 0;
                  final content = conv['content'] as String? ?? '';
                  final createdAt = conv['createdAt'] as String?;
                  final timeStr = createdAt != null
                      ? Formatters.formatRelativeTime(DateTime.parse(createdAt))
                      : '';

                  return InkWell(
                    onTap: () => _openChat(
                      (conv['otherUserId'] as num).toInt(),
                      conv['otherUsername'] as String,
                      conv['otherFullName'] as String?,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: unread > 0 ? AppColors.accent : AppColors.primary.withOpacity(0.3),
                            child: Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                color: unread > 0 ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(timeStr, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        content,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: unread > 0 ? AppColors.textSecondary : AppColors.textMuted,
                                          fontSize: 13,
                                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    if (unread > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$unread',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _conversations.length,
              ),
            ),
        ],
      ),
    );
  }
}
