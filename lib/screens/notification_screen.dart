import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await NotificationService.getHistory();
    if (mounted) setState(() { _notifications = list; _isLoading = false; });
    await NotificationService.markAllRead();
  }

  Future<void> _clear() async {
    await NotificationService.clearHistory();
    if (mounted) setState(() => _notifications = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('알림'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _clear,
              child: const Text('전체 삭제', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = _notifications[i];
                    return Dismissible(
                      key: Key(n.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await NotificationService.deleteOne(n.id);
                        setState(() => _notifications.removeAt(i));
                      },
                      child: _NotificationCard(notification: n),
                    );
                  },
                ),
    );
  }

  Future<void> _addTestNotification() async {
    await NotificationService.showBudgetAlert(
      category: '식비',
      spent: 85000,
      limit: 100000,
    );
    await _load();
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 12),
          const Text('알림 내역이 없습니다', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _addTestNotification,
            icon: const Icon(Icons.notifications_outlined, size: 16),
            label: const Text('테스트 알림 추가', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  const _NotificationCard({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.budget:  return Icons.account_balance_wallet_outlined;
      case NotificationType.anomaly: return Icons.search_outlined;
      case NotificationType.report:  return Icons.summarize_outlined;
    }
  }

  Color get _color {
    switch (notification.type) {
      case NotificationType.budget:  return AppTheme.dangerRed;
      case NotificationType.anomaly: return AppTheme.primaryTeal;
      case NotificationType.report:  return AppTheme.primaryBlue;
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1)   return '${diff.inMinutes}분 전';
    if (diff.inDays < 1)    return '${diff.inHours}시간 전';
    if (diff.inDays < 30)   return '${diff.inDays}일 전';
    return '${notification.createdAt.month}/${notification.createdAt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ),
                    Text(_timeAgo, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
