import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../stores/notificationProviders.dart';
import '../theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all'; // 'all', 'unread', 'booking', 'chat', 'system'

  @override
  void initState() {
    super.initState();
    // Refresh unread count upon opening screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).refreshUnreadCount();
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(notificationsListFutureProvider);
    await ref.read(notificationServiceProvider).refreshUnreadCount();
    await ref.read(notificationsListFutureProvider.future);
  }

  Future<void> _handleMarkAllRead() async {
    final success =
        await ref.read(notificationServiceProvider).markAllAsRead();
    if (!mounted) return;
    if (success) {
      ref.invalidate(notificationsListFutureProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('All notifications marked as read'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onNotificationTap(NotificationItem notif) async {
    // 1. Mark as read if not already read
    if (!notif.isRead) {
      setState(() {
        notif.isRead = true;
      });
      await ref.read(notificationServiceProvider).markAsRead(notif.id);
    }

    if (!mounted) return;

    // 2. Perform deep link routing
    final data = notif.data;
    if (data != null) {
      // Direct route parameter
      if (data.containsKey('route') &&
          data['route'] is String &&
          (data['route'] as String).isNotEmpty) {
        context.push(data['route'] as String);
        return;
      }

      // Booking route
      final bookingId = data['booking_id'] ?? data['bookingId'] ?? data['id'];
      if ((notif.type == 'booking' || data['type'] == 'booking') &&
          bookingId != null) {
        context.push('/bookings/detail?id=$bookingId');
        return;
      }

      // Chat route
      final roomId = data['roomId'] ?? data['room_id'];
      if ((notif.type == 'chat' || data['type'] == 'chat') && roomId != null) {
        final senderName =
            data['senderName'] ?? data['recipientName'] ?? 'Customer';
        context.push('/chat?roomId=$roomId&recipientName=$senderName');
        return;
      }
    }

    // Default fallback based on type
    if (notif.type == 'booking') {
      context.push('/bookings');
    } else if (notif.type == 'chat') {
      context.push('/chat');
    } else if (notif.type == 'earnings' || notif.type == 'payout') {
      context.push('/earnings');
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.assignment_outlined;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'earnings':
      case 'payout':
        return Icons.account_balance_wallet_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'system':
      case 'alert':
        return Icons.shield_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return AppColors.primary;
      case 'chat':
        return AppColors.secondary;
      case 'earnings':
      case 'payout':
        return AppColors.success;
      case 'promo':
        return Colors.amber.shade700;
      case 'system':
      case 'alert':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return 'Dispatch Order';
      case 'chat':
        return 'Client Message';
      case 'earnings':
      case 'payout':
        return 'Financial Alert';
      case 'promo':
        return 'Special Offer';
      case 'system':
      case 'alert':
        return 'System Alert';
      default:
        return 'Update';
    }
  }

  List<NotificationItem> _filterNotifications(List<NotificationItem> items) {
    switch (_selectedFilter) {
      case 'unread':
        return items.where((i) => !i.isRead).toList();
      case 'booking':
        return items.where((i) => i.type.toLowerCase() == 'booking').toList();
      case 'chat':
        return items.where((i) => i.type.toLowerCase() == 'chat').toList();
      case 'system':
        return items
            .where(
              (i) =>
                  i.type.toLowerCase() == 'system' ||
                  i.type.toLowerCase() == 'earnings' ||
                  i.type.toLowerCase() == 'payout' ||
                  i.type.toLowerCase() == 'alert',
            )
            .toList();
      case 'all':
      default:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncNotifications = ref.watch(notificationsListFutureProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.cardColor,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Center',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable:
                  ref.read(notificationServiceProvider).unreadCountNotifier,
              builder: (context, unreadCount, _) {
                return Text(
                  unreadCount > 0
                      ? '$unreadCount unread ${unreadCount == 1 ? 'alert' : 'alerts'}'
                      : 'All alerts caught up',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: unreadCount > 0
                        ? AppColors.primary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable:
                ref.read(notificationServiceProvider).unreadCountNotifier,
            builder: (context, unreadCount, _) {
              if (unreadCount == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton.icon(
                  onPressed: _handleMarkAllRead,
                  icon: const Icon(
                    Icons.done_all_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Mark read',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Notifications',
          ),
        ],
      ),
      body: SafeArea(
        child: asyncNotifications.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      size: 32,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (allNotifications) {
            final unreadCount =
                allNotifications.where((i) => !i.isRead).length;
            final bookingCount = allNotifications
                .where((i) => i.type.toLowerCase() == 'booking')
                .length;
            final chatCount = allNotifications
                .where((i) => i.type.toLowerCase() == 'chat')
                .length;
            final filteredList = _filterNotifications(allNotifications);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: Column(
                children: [
                  // Filter Chips Row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All',
                            count: allNotifications.length,
                            value: 'all',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Unread',
                            count: unreadCount,
                            value: 'unread',
                            theme: theme,
                            isHighlighted: unreadCount > 0,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Dispatches',
                            count: bookingCount,
                            value: 'booking',
                            icon: Icons.assignment_outlined,
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Messages',
                            count: chatCount,
                            value: 'chat',
                            icon: Icons.chat_bubble_outline_rounded,
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'System',
                            value: 'system',
                            icon: Icons.shield_outlined,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Notifications List or Empty State
                  Expanded(
                    child: filteredList.isEmpty
                        ? _buildEmptyState(theme, isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 14.0,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final notif = filteredList[index];
                              return _buildNotificationCard(
                                notif: notif,
                                theme: theme,
                                isDark: isDark,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required ThemeData theme,
    int? count,
    IconData? icon,
    bool isHighlighted = false,
  }) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isHighlighted
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : theme.scaffoldBackgroundColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isHighlighted
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : theme.dividerColor),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (isHighlighted
                        ? AppColors.primary
                        : theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isHighlighted
                        ? AppColors.primary
                        : theme.textTheme.bodyMedium?.color),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isHighlighted
                          ? AppColors.primary
                          : theme.dividerColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected || isHighlighted
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required NotificationItem notif,
    required ThemeData theme,
    required bool isDark,
  }) {
    final typeColor = _getColorForType(notif.type);
    final typeIcon = _getIconForType(notif.type);
    final typeLabel = _getTypeLabel(notif.type);

    return Dismissible(
      key: Key('notif_${notif.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Read',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        if (!notif.isRead) {
          notif.isRead = true;
          ref.read(notificationServiceProvider).markAsRead(notif.id);
        }
      },
      child: GestureDetector(
        onTap: () => _onNotificationTap(notif),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.isRead
                ? theme.cardColor
                : (isDark
                    ? theme.cardColor
                    : AppColors.primary.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: notif.isRead
                  ? theme.dividerColor
                  : AppColors.primary.withValues(alpha: 0.35),
              width: notif.isRead ? 1.0 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: notif.isRead ? 6 : 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.25),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  typeIcon,
                  size: 22,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 14),

              // Content Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Type chip & time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              notif.timeAgo,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!notif.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),

                    // Notification Title
                    Text(
                      notif.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight:
                            notif.isRead ? FontWeight.w600 : FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Notification Description Body
                    Text(
                      notif.body,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: notif.isRead
                            ? theme.textTheme.bodyMedium?.color
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),

                    // Bottom Action Link (if actionable)
                    if (notif.data != null &&
                        (notif.data!['bookingId'] != null ||
                            notif.data!['booking_id'] != null ||
                            notif.data!['roomId'] != null ||
                            notif.data!['route'] != null ||
                            notif.type == 'booking' ||
                            notif.type == 'chat')) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  notif.type == 'booking'
                                      ? 'View Job Dispatch'
                                      : (notif.type == 'chat'
                                          ? 'Reply in Chat'
                                          : 'Open Details'),
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: typeColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 11,
                                  color: typeColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    IconData emptyIcon;
    String title;
    String desc;

    switch (_selectedFilter) {
      case 'unread':
        emptyIcon = Icons.mark_email_read_outlined;
        title = 'Zero Unread Alerts';
        desc =
            'Great job! All customer requests and dispatch notices have been reviewed.';
        break;
      case 'booking':
        emptyIcon = Icons.assignment_outlined;
        title = 'No Dispatch Alerts';
        desc =
            'New customer bookings and service schedule updates will appear here.';
        break;
      case 'chat':
        emptyIcon = Icons.chat_bubble_outline_rounded;
        title = 'No Chat Messages';
        desc =
            'Direct inquiries and messages from active clients will appear here.';
        break;
      case 'system':
        emptyIcon = Icons.shield_outlined;
        title = 'No System Notices';
        desc = 'Platform announcements, earnings logs, and verification alerts.';
        break;
      case 'all':
      default:
        emptyIcon = Icons.notifications_off_outlined;
        title = 'No Notifications Yet';
        desc =
            'Real-time job requests, chat pings, and payout reports will appear right here.';
        break;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    emptyIcon,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Check for updates'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
