import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/notification_service.dart';

/// Represents an individual notification in the system
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;
  final String timeAgo;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.createdAt,
    required this.timeAgo,
    this.isRead = false,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    final type = map['type']?.toString() ?? 'general';
    DateTime? dt;
    String timeStr = 'Just now';

    if (map['createdAt'] != null) {
      try {
        dt = DateTime.parse(map['createdAt'].toString());
        final now = DateTime.now();
        final diff = now.difference(dt);
        if (diff.inSeconds < 60) {
          timeStr = 'Just now';
        } else if (diff.inMinutes < 60) {
          timeStr = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeStr = '${diff.inHours}h ago';
        } else if (diff.inDays == 1) {
          timeStr = 'Yesterday';
        } else if (diff.inDays < 7) {
          timeStr = '${diff.inDays}d ago';
        } else {
          const months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          timeStr = '${months[dt.month - 1]} ${dt.day}';
        }
      } catch (_) {}
    }

    return NotificationItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Alert',
      body: map['body']?.toString() ?? '',
      type: type,
      data: map['data'] is Map ? Map<String, dynamic>.from(map['data'] as Map) : null,
      createdAt: dt,
      timeAgo: timeStr,
      isRead: map['isRead'] == true,
    );
  }
}

/// Provider for NotificationService instance
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// FutureProvider that fetches list of notifications from backend
final notificationsListFutureProvider =
    FutureProvider<List<NotificationItem>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  final raw = await service.getUserNotifications(page: 1, limit: 50);
  return raw.map((item) => NotificationItem.fromMap(item)).toList();
});

/// Active filter tab state provider ('all', 'unread', 'booking', 'chat', 'system')
final notificationFilterTabProvider = StateProvider<String>((ref) => 'all');
