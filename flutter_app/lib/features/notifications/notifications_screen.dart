import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Sample local notifications (will be replaced by backend)
  final List<Map<String, dynamic>> _notifications = [
    {'type': 'bid', 'title': 'Outbid!', 'body': 'Someone placed a higher bid', 'time': DateTime.now().subtract(const Duration(minutes: 5)), 'isRead': false},
    {'type': 'won', 'title': 'You won!', 'body': 'Congratulations! You won the auction', 'time': DateTime.now().subtract(const Duration(hours: 1)), 'isRead': false},
    {'type': 'ending', 'title': 'Ending Soon', 'body': 'An auction you are watching ends in 30 minutes', 'time': DateTime.now().subtract(const Duration(hours: 3)), 'isRead': true},
    {'type': 'deposit', 'title': 'Deposit Successful', 'body': '500,000đ has been added to your wallet', 'time': DateTime.now().subtract(const Duration(days: 1)), 'isRead': true},
  ];

  IconData _getIcon(String type) {
    switch (type) {
      case 'bid':
        return Icons.gavel;
      case 'won':
        return Icons.emoji_events;
      case 'ending':
        return Icons.timer;
      case 'deposit':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'bid':
        return AppColors.error;
      case 'won':
        return AppColors.accent;
      case 'ending':
        return AppColors.auctionEnding;
      case 'deposit':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
                  Text('Notifications', style: Theme.of(context).textTheme.displayMedium),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (final n in _notifications) {
                          n['isRead'] = true;
                        }
                      });
                    },
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
          ),

          if (_notifications.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(icon: Icons.notifications_off, title: 'No notifications', subtitle: 'You\'re all caught up!'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final n = _notifications[index];
                    final isRead = n['isRead'] as bool;
                    final type = n['type'] as String;
                    final color = _getColor(type);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isRead ? AppColors.cardDark : AppColors.cardDark.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: isRead ? null : Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getIcon(type), color: color, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      n['title'],
                                      style: TextStyle(
                                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                        fontSize: 14,
                                        color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8, height: 8,
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n['body'],
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatTime(n['time']),
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _notifications.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
