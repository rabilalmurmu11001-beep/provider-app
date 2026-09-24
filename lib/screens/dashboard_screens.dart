import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider_app/services/authServices.dart';
import 'package:provider_app/services/notification_service.dart';
import 'package:provider_app/services/kyc_service.dart';
import 'package:provider_app/stores/bookingProviders.dart';
import 'package:provider_app/stores/kyc_providers.dart';
import 'package:provider_app/stores/providers.dart';
import '../theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    // Fetch the provider profile and notifications when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.refreshUnreadCount();
      final Map<String, dynamic>? profileState = ref.read(
        providerProfileProvider,
      );
      if (profileState == null) {
        // Fetch the profile data and update the state
        ref
            .read(authServiceProvider)
            .getUserProfile()
            .then((response) {
              ref.read(providerProfileProvider.notifier).state =
                  response.data?['user'];
            })
            .catchError((error) {
              debugPrint('Error fetching profile: $error');
            });
        ref.read(providerProfileProvider.notifier).state = {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Map<String, dynamic>? profileState = ref.watch(
      providerProfileProvider,
    );

    final asyncAvailable = ref.watch(availableBookingsProvider);
    final asyncInProgress = ref.watch(
      providerAssignedBookingsProvider('in_progress'),
    );
    final asyncAccepted = ref.watch(
      providerAssignedBookingsProvider('accepted'),
    );
    final asyncCompleted = ref.watch(
      providerAssignedBookingsProvider('completed'),
    );

    final availableCount = asyncAvailable.value?.length ?? 0;
    final inProgressList = asyncInProgress.value ?? [];
    final acceptedList = asyncAccepted.value ?? [];
    final completedList = asyncCompleted.value ?? [];

    // Prioritize active (in_progress) job, otherwise upcoming accepted job
    final activeJob = inProgressList.isNotEmpty
        ? inProgressList.first
        : (acceptedList.isNotEmpty ? acceptedList.first : null);

    // Calculate total earned from completed jobs
    double totalEarned = 0;
    for (final c in completedList) {
      final b = c['booking'] as Map<String, dynamic>? ?? {};
      final amount = b['totalAmount'] ?? b['originalAmount'] ?? 0;
      if (amount is num) {
        totalEarned += amount.toDouble();
      }
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(availableBookingsProvider);
            ref.invalidate(providerAssignedBookingsProvider('in_progress'));
            ref.invalidate(providerAssignedBookingsProvider('accepted'));
            ref.invalidate(providerAssignedBookingsProvider('completed'));
            await NotificationService.instance.refreshUnreadCount();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Top Header Panel
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.05,
                        ),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Builder(
                                builder: (context) {
                                  final photoUrl =
                                      profileState?['photo']?.toString();
                                  final username =
                                      profileState?['username']?.toString() ??
                                      '';
                                  final initialChar = username.isNotEmpty
                                      ? username[0].toUpperCase()
                                      : 'P';

                                  return InkWell(
                                    onTap: () => context.go('/profile'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.secondary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: (photoUrl != null &&
                                                photoUrl.trim().isNotEmpty)
                                            ? Image.network(
                                                photoUrl.trim(),
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Center(
                                                  child: Text(
                                                    initialChar,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  initialChar,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Operational Console',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyMedium?.color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '${profileState?['username'] ?? 'Service Provider'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Chat Messages Quick Action
                              IconButton(
                                onPressed: () => context.push('/chat'),
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                tooltip: 'Client Messages',
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(36, 36),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Notification Center Quick Action with Badge
                              ValueListenableBuilder<int>(
                                valueListenable: NotificationService
                                    .instance.unreadCountNotifier,
                                builder: (context, unreadCount, _) {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            context.push('/notifications'),
                                        icon: const Icon(
                                          Icons.notifications_outlined,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        tooltip: 'Notification Center',
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          minimumSize: const Size(36, 36),
                                        ),
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          top: -2,
                                          right: -2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.danger,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: theme.cardColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              unreadCount > 9
                                                  ? '9+'
                                                  : '$unreadCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(width: 8),

                              // Online Toggle Button
                              Consumer(
                                builder: (context, ref, _) {
                                  final kycAsync = ref.watch(kycStatusAsyncProvider);
                                  final isVerified = kycAsync.value?['isVerified'] == true;

                                  return GestureDetector(
                                    onTap: () async {
                                      if (!_isOnline && !isVerified) {
                                        showDialog(
                                          context: context,
                                          builder: (dialogCtx) => AlertDialog(
                                            backgroundColor: theme.cardColor,
                                            title: Row(
                                              children: [
                                                const Icon(
                                                  Icons.security_rounded,
                                                  color: AppColors.warning,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'KYC Required',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: Text(
                                              'You must complete and have your KYC verified before you can go online and accept bookings.',
                                              style: GoogleFonts.inter(fontSize: 13),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogCtx),
                                                child: const Text('Later'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(dialogCtx);
                                                  context.push('/kyc');
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('Complete KYC'),
                                              ),
                                            ],
                                          ),
                                        );
                                        return;
                                      }

                                      final targetState = !_isOnline;
                                      setState(() => _isOnline = targetState);

                                      try {
                                        await ref
                                            .read(kycServiceProvider)
                                            .updateProviderStatus(
                                              targetState ? 'available' : 'offline',
                                            );
                                      } catch (_) {
                                        if (mounted) {
                                          setState(() => _isOnline = !targetState);
                                        }
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              _isOnline
                                                  ? '🟢 Operations Status: ONLINE'
                                                  : '🔴 Operations Status: OFFLINE',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isOnline
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.danger.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _isOnline
                                              ? AppColors.success.withValues(alpha: 0.3)
                                              : AppColors.danger.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: _isOnline
                                                  ? AppColors.success
                                                  : AppColors.danger,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _isOnline ? 'ONLINE' : 'OFFLINE',
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: _isOnline
                                                  ? AppColors.success
                                                  : AppColors.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Mini stats grid
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBg
                                    : AppColors.lightBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL SETTLED PAYOUT',
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${totalEarned.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${completedList.length} jobs completed',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBg
                                    : AppColors.lightBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DISPATCH REQUESTS',
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$availableCount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Available for claim',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // KYC Status Action Banner
                Consumer(
                  builder: (context, ref, _) {
                    final kycAsync = ref.watch(kycStatusAsyncProvider);
                    final isVerified = kycAsync.value?['isVerified'] == true;
                    if (isVerified) return const SizedBox.shrink();

                    final status = (kycAsync.value?['status']?.toString() ??
                            'not_submitted')
                        .toLowerCase();
                    final reason =
                        kycAsync.value?['rejectionReason']?.toString() ?? '';

                    Color bannerColor;
                    Color borderColor;
                    IconData bannerIcon;
                    String bannerTitle;
                    String bannerText;
                    String actionText;

                    if (status == 'rejected') {
                      bannerColor = AppColors.danger.withValues(alpha: 0.12);
                      borderColor = AppColors.danger.withValues(alpha: 0.35);
                      bannerIcon = Icons.error_outline_rounded;
                      bannerTitle = 'KYC Verification Rejected';
                      bannerText = reason.isNotEmpty
                          ? 'Reason: $reason. Please update your documents.'
                          : 'Your verification was not approved. Tap to update.';
                      actionText = 'Fix Now';
                    } else if (status == 'pending' || status == 'in_review') {
                      bannerColor = AppColors.warning.withValues(alpha: 0.12);
                      borderColor = AppColors.warning.withValues(alpha: 0.35);
                      bannerIcon = Icons.hourglass_top_rounded;
                      bannerTitle = 'Verification in Progress';
                      bannerText =
                          'Your documents are currently under review by administrators.';
                      actionText = 'View Status';
                    } else {
                      bannerColor = AppColors.primary.withValues(alpha: 0.12);
                      borderColor = AppColors.primary.withValues(alpha: 0.35);
                      bannerIcon = Icons.shield_outlined;
                      bannerTitle = 'KYC Verification Required';
                      bannerText =
                          'Complete your identity verification to accept customer bookings and go online.';
                      actionText = 'Verify Now';
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: InkWell(
                        onTap: () => context.push('/kyc'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: bannerColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(bannerIcon, color: borderColor, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bannerTitle,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      bannerText,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  actionText,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Main Content
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Operational Flow Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ACTIVE OPERATIONAL FLOW',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/bookings'),
                            child: Text(
                              'View Dispatch ($availableCount)',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dynamic Active Booking Flow Card
                      _buildActiveJobSection(activeJob, theme),

                      const SizedBox(height: 24),

                      // Velocity Distribution Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Velocity Distribution',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Activity Log',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 64,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildBar(theme, 32, false),
                                  _buildBar(theme, 48, false),
                                  _buildBar(theme, 64, true),
                                  _buildBar(theme, 40, false),
                                  _buildBar(theme, 56, true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveJobSection(
    Map<String, dynamic>? activeJob,
    ThemeData theme,
  ) {
    if (activeJob == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'No Active Jobs in Progress',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check the Bookings List to claim incoming requests.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/bookings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Open Bookings List',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final booking = activeJob['booking'] as Map<String, dynamic>? ?? {};
    final service = activeJob['service'] as Map<String, dynamic>? ?? {};
    final address = activeJob['address'] as Map<String, dynamic>? ?? {};
    final customer = activeJob['customer'] as Map<String, dynamic>? ?? {};

    final serviceName = service['name']?.toString() ?? 'Service Booking';
    final customerName = customer['username']?.toString() ?? 'Customer';
    final addressText = [
      address['house_number'],
      address['street_no_or_name'],
      address['city'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

    final totalAmount = booking['totalAmount'] != null
        ? '\$${booking['totalAmount']}'
        : '\$${service['basePrice'] ?? '0.00'}';
    final status = (booking['bookingStatus']?.toString() ?? 'ACCEPTED').toUpperCase();
    final isInProgress = status == 'IN_PROGRESS';

    return GestureDetector(
      onTap: () => context.go('/bookings/detail', extra: activeJob),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isInProgress ? 'ACTIVE IN PROGRESS' : 'MANIFEST ALLOCATED',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 8,
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
                        color: isInProgress ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'STATE: $status',
                      style: GoogleFonts.inter(
                        color: isInProgress ? AppColors.success : AppColors.warning,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              serviceName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Client Target: $customerName ${addressText.isNotEmpty ? '• $addressText' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Est. Payout Value: ',
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 9.5,
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
                Row(
                  children: [
                    Text(
                      'Open System Manifest',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(ThemeData theme, double height, bool isPrimary) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : theme.dividerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
    );
  }
}
