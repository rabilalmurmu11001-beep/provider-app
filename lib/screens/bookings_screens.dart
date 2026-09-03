import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider_app/services/bookingServices.dart';
import 'package:provider_app/stores/bookingProviders.dart';
import '../theme.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  // Tabs: available (dispatch), upcoming (accepted), active (in_progress), completed (completed)
  String _activeTab = 'available';
  final Map<String, bool> _acceptingMap = {};

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'Not scheduled';
    try {
      final dt = DateTime.parse(dateVal.toString());
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
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateVal.toString();
    }
  }

  Future<void> _handleAccept(String bookingId) async {
    setState(() {
      _acceptingMap[bookingId] = true;
    });

    try {
      final service = ref.read(providerBookingServiceProvider);
      await service.acceptBooking(bookingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Job successfully accepted and added to your schedule!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Invalidate booking providers to refresh all tabs
        ref.invalidate(availableBookingsProvider);
        ref.invalidate(providerAssignedBookingsProvider('accepted'));
        ref.invalidate(providerAssignedBookingsProvider('in_progress'));
        ref.invalidate(providerAssignedBookingsProvider(null));

        // Switch to upcoming tab to see the accepted booking
        setState(() {
          _activeTab = 'upcoming';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept booking: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _acceptingMap.remove(bookingId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Job Dispatch Terminal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.invalidate(availableBookingsProvider);
                          ref.invalidate(providerAssignedBookingsProvider('accepted'));
                          ref.invalidate(providerAssignedBookingsProvider('in_progress'));
                          ref.invalidate(providerAssignedBookingsProvider('completed'));
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Refresh Bookings',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Segmented Filter Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('available', 'Available'),
                        _buildTabButton('upcoming', 'Upcoming'),
                        _buildTabButton('active', 'Active'),
                        _buildTabButton('completed', 'Completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content List with pull to refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (_activeTab == 'available') {
                    ref.invalidate(availableBookingsProvider);
                    await ref.read(availableBookingsProvider.future);
                  } else if (_activeTab == 'upcoming') {
                    ref.invalidate(providerAssignedBookingsProvider('accepted'));
                    await ref.read(
                      providerAssignedBookingsProvider('accepted').future,
                    );
                  } else if (_activeTab == 'active') {
                    ref.invalidate(providerAssignedBookingsProvider('in_progress'));
                    await ref.read(
                      providerAssignedBookingsProvider('in_progress').future,
                    );
                  } else {
                    ref.invalidate(providerAssignedBookingsProvider('completed'));
                    await ref.read(
                      providerAssignedBookingsProvider('completed').future,
                    );
                  }
                },
                child: _buildTabList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabKey, String label) {
    final isSelected = _activeTab == tabKey;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tabKey;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: theme.dividerColor) : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabList() {
    if (_activeTab == 'available') {
      final asyncBookings = ref.watch(availableBookingsProvider);
      return asyncBookings.when(
        data: (bookings) => _buildBookingCards(bookings, isAvailable: true),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => _buildErrorState(_formatError(err), () {
          ref.invalidate(availableBookingsProvider);
        }),
      );
    } else if (_activeTab == 'upcoming') {
      final asyncBookings = ref.watch(
        providerAssignedBookingsProvider('accepted'),
      );
      return asyncBookings.when(
        data: (bookings) => _buildBookingCards(bookings, statusTag: 'UPCOMING'),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => _buildErrorState(_formatError(err), () {
          ref.invalidate(providerAssignedBookingsProvider('accepted'));
        }),
      );
    } else if (_activeTab == 'active') {
      final asyncBookings = ref.watch(
        providerAssignedBookingsProvider('in_progress'),
      );
      return asyncBookings.when(
        data: (bookings) => _buildBookingCards(bookings, isActiveFlow: true),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => _buildErrorState(_formatError(err), () {
          ref.invalidate(providerAssignedBookingsProvider('in_progress'));
        }),
      );
    } else {
      final asyncBookings = ref.watch(
        providerAssignedBookingsProvider('completed'),
      );
      return asyncBookings.when(
        data: (bookings) => _buildBookingCards(bookings, isCompleted: true),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => _buildErrorState(_formatError(err), () {
          ref.invalidate(providerAssignedBookingsProvider('completed'));
        }),
      );
    }
  }

  Widget _buildBookingCards(
    List<Map<String, dynamic>> items, {
    bool isAvailable = false,
    bool isActiveFlow = false,
    bool isCompleted = false,
    String? statusTag,
  }) {
    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: AppColors.lightTextSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  isAvailable
                      ? 'No available jobs right now'
                      : 'No $_activeTab bookings found',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAvailable
                      ? 'New booking requests will show up here in real time.'
                      : 'Assigned bookings will appear under this tab.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20.0),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        final booking = item['booking'] as Map<String, dynamic>? ?? {};
        final service = item['service'] as Map<String, dynamic>? ?? {};
        final category = item['category'] as Map<String, dynamic>? ?? {};
        final address = item['address'] as Map<String, dynamic>? ?? {};
        final customer = item['customer'] as Map<String, dynamic>? ?? {};

        final bookingId = booking['id']?.toString() ?? '';
        final serviceName = service['name']?.toString() ?? 'Standard Service';
        final categoryName = category['name']?.toString() ?? 'General';
        final customerName = customer['username']?.toString() ?? 'Customer';
        final scheduledDate = _formatDate(booking['scheduledDate']);
        final scheduledTime = booking['scheduledTime']?.toString() ?? 'TBD';
        final totalAmount = booking['totalAmount'] != null
            ? '\$${booking['totalAmount']}'
            : '\$${service['basePrice'] ?? '0.00'}';
        final addressLine =
            '${address['street_no_or_name'] ?? ''} ${address['city'] ?? ''}, ${address['state'] ?? ''}'.trim();
        final bookingStatus = (booking['bookingStatus']?.toString() ?? 'requested').toUpperCase();

        final isAccepting = _acceptingMap[bookingId] == true;

        final theme = Theme.of(context);

        return GestureDetector(
          onTap: () {
            context.go('/bookings/detail', extra: item);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActiveFlow
                    ? AppColors.primary
                    : isAvailable
                    ? AppColors.secondary.withValues(alpha: 0.5)
                    : theme.dividerColor,
                width: isActiveFlow ? 1.5 : 1.0,
              ),
              boxShadow: isActiveFlow
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (isAvailable
                                ? AppColors.secondary
                                : isActiveFlow
                                ? AppColors.primary
                                : isCompleted
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        categoryName.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: isAvailable
                              ? AppColors.secondary
                              : isActiveFlow
                              ? AppColors.primary
                              : isCompleted
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppColors.secondary
                                : isActiveFlow
                                ? AppColors.warning
                                : isCompleted
                                ? AppColors.success
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAvailable
                              ? 'NEW REQUEST'
                              : 'STATE: $bookingStatus',
                          style: GoogleFonts.inter(
                            color: isAvailable
                                ? AppColors.secondary
                                : isActiveFlow
                                ? AppColors.warning
                                : isCompleted
                                ? AppColors.success
                                : AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Service Name & Customer
                Text(
                  serviceName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Client: $customerName ${addressLine.isNotEmpty ? '• $addressLine' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10.5),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Bottom Meta: Schedule & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Est. Payout: ',
                        style: GoogleFonts.inter(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 10,
                        ),
                        children: [
                          TextSpan(
                            text: totalAmount,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$scheduledDate • $scheduledTime',
                      style: GoogleFonts.inter(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Action buttons for available requests
                if (isAvailable) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isAccepting ? null : () => _handleAccept(bookingId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: isAccepting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Claim & Accept Job',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatError(dynamic err) {
    if (err is DioException) {
      if (err.response?.statusCode == 403) {
        return 'Access restricted: Your account must be registered as a Service Provider. Please ensure your account has the Service Provider role.';
      }
      final data = err.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return err.toString();
  }

  Widget _buildErrorState(String errorMsg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              'Failed to load bookings',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
