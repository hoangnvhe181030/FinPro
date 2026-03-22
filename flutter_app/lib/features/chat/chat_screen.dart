import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/api/api_service.dart';
import '../../data/providers/auth_provider.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUsername;
  final String? otherFullName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
    this.otherFullName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  StompClient? _stompClient;
  int? _myUserId;

  String get _displayName =>
      (widget.otherFullName?.isNotEmpty == true ? widget.otherFullName! : widget.otherUsername);

  @override
  void initState() {
    super.initState();
    _myUserId = context.read<AuthProvider>().currentUser?.userId;
    _loadMessages();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_myUserId == null) return;

    try {
      final api = context.read<ApiService>();

      // Load messages
      final response = await api.get('/chat/messages/$_myUserId/${widget.otherUserId}');
      setState(() {
        _messages = List<Map<String, dynamic>>.from(response.data);
        _isLoading = false;
      });
      _scrollToBottom();

      // Mark as read
      await api.post('/chat/read', data: {
        'senderId': widget.otherUserId,
        'receiverId': _myUserId,
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading messages: $e');
    }
  }

  void _connectWebSocket() {
    if (_myUserId == null) return;

    _stompClient = StompClient(
      config: StompConfig(
        url: AppConstants.wsUrl,
        onConnect: (frame) {
          debugPrint('Chat WebSocket connected');
          // Subscribe to personal chat queue
          _stompClient?.subscribe(
            destination: '/queue/chat/$_myUserId',
            callback: (frame) {
              if (frame.body != null) {
                final message = Map<String, dynamic>.from(json.decode(frame.body!));
                // Only show messages from the current conversation
                final senderId = (message['senderId'] as num).toInt();
                final receiverId = (message['receiverId'] as num).toInt();
                if ((senderId == widget.otherUserId && receiverId == _myUserId) ||
                    (senderId == _myUserId && receiverId == widget.otherUserId)) {
                  // Avoid duplicates
                  final messageId = message['messageId'];
                  if (!_messages.any((m) => m['messageId'] == messageId)) {
                    setState(() => _messages.add(message));
                    _scrollToBottom();
                  }
                }
              }
            },
          );
        },
        onWebSocketError: (error) => debugPrint('Chat WS error: $error'),
      ),
    );

    _stompClient?.activate();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _myUserId == null) return;

    _messageController.clear();

    try {
      final api = context.read<ApiService>();
      final response = await api.post('/chat/send', data: {
        'senderId': _myUserId,
        'receiverId': widget.otherUserId,
        'content': text,
      });

      final message = Map<String, dynamic>.from(response.data);
      final messageId = message['messageId'];
      if (!_messages.any((m) => m['messageId'] == messageId)) {
        setState(() => _messages.add(message));
      }
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                _displayName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('@${widget.otherUsername}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.waving_hand_rounded, size: 48, color: AppColors.accent.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text('Say hello to $_displayName!', style: const TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                      ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 8, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                      filled: true,
                      fillColor: AppColors.cardDark,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = (message['senderId'] as num).toInt() == _myUserId;
    final content = message['content'] as String? ?? '';
    final createdAt = message['createdAt'] as String?;
    final time = createdAt != null
        ? '${DateTime.parse(createdAt).hour.toString().padLeft(2, '0')}:${DateTime.parse(createdAt).minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withOpacity(0.85) : AppColors.cardDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white.withOpacity(0.6) : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
