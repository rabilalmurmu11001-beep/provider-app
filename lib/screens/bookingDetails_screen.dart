import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider_app/services/bookingServices.dart';
import 'package:provider_app/stores/bookingProviders.dart';
import '../theme.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  final Map<String, dynamic>? initialBookingData;

  const BookingDetailScreen({
    super.key,
    this.bookingId,
    this.initialBookingData,
  });

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  Map<String, dynamic>? _bookingData;
  bool _isLoading = false;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.initialBookingData;
    _fetchBookingDetails();
  }

  String? get _resolvedBookingId {
    if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
      return widget.bookingId;
    }
    final booking = _bookingData?['booking'] as Map<String, dynamic>?;
    return booking?['id']?.toString() ?? _bookingData?['id']?.toString();
  }

  Future<void> _fetchBookingDetails() async {
    final id = _resolvedBookingId;
    if (id == null || id.isEmpty) return;

    setState(() {
      _isLoading = _bookingData == null;
    });

    try {
      final service = ref.read(providerBookingServiceProvider);
      final details = await service.getBookingById(id);
      if (mounted && details != null) {
        setState(() {
          _bookingData = details;
        });
      }
    } catch (e) {
      if (mounted && _bookingData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load booking details: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
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

  void _refreshAllBookings() {
    ref.invalidate(availableBookingsProvider);
    ref.invalidate(providerAssignedBookingsProvider('accepted'));
    ref.invalidate(providerAssignedBookingsProvider('in_progress'));
    ref.invalidate(providerAssignedBookingsProvider('completed'));
    ref.invalidate(providerAssignedBookingsProvider(null));
    final id = _resolvedBookingId;
    if (id != null) {
      ref.invalidate(providerBookingDetailProvider(id));
    }
  }

  Future<void> _handleAccept() async {
    final id = _resolvedBookingId;
    if (id == null) return;

    setState(() => _isActionInProgress = true);
    try {
      final service = ref.read(providerBookingServiceProvider);
      await service.acceptBooking(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Booking accepted successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshAllBookings();
        await _fetchBookingDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting booking: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleStart() async {
    final id = _resolvedBookingId;
    if (id == null) return;

    setState(() => _isActionInProgress = true);
    try {
      final service = ref.read(providerBookingServiceProvider);
      await service.startBooking(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Service started! State updated to IN PROGRESS.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshAllBookings();
        await _fetchBookingDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting booking: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleComplete() async {
    final id = _resolvedBookingId;
    if (id == null) return;

    setState(() => _isActionInProgress = true);
    try {
      final service = ref.read(providerBookingServiceProvider);
      await service.completeBooking(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Booking completed! Payout settled into ledger.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshAllBookings();
        await _fetchBookingDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing booking: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel Job Assignment',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please specify the reason for cancelling this booking:',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                validator: (val) =>
                    (val == null || val.trim().isEmpty)
                        ? 'Cancellation reason is required'
                        : null,
                decoration: InputDecoration(
                  hintText: 'e.g., Equipment malfunction, emergency schedule conflict',
                  hintStyle: GoogleFonts.inter(fontSize: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final id = _resolvedBookingId;
      if (id == null) return;

      setState(() => _isActionInProgress = true);
      try {
        final service = ref.read(providerBookingServiceProvider);
        await service.cancelBooking(id, reasonController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Booking cancelled.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _refreshAllBookings();
          await _fetchBookingDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel booking: $e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isActionInProgress = false);
      }
    }
  }

  Widget _buildWorkflowNode(String currentStatus) {
    final status = currentStatus.toLowerCase();

    if (_isActionInProgress) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    switch (status) {
      case 'requested':
        return Column(
          children: [
            ElevatedButton(
              onPressed: _handleAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Accept Job Assignment',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      case 'accepted':
        return Column(
          children: [
            ElevatedButton(
              onPressed: _handleStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Initialize Transit & Start Job',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _showCancelDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel Job Assignment',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      case 'in_progress':
        return Column(
          children: [
            ElevatedButton(
              onPressed: _handleComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Complete Job Assignment Manifest',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _showCancelDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel Active Service',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      case 'completed':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '✓ Complete Process Lifecycle Finalized & Settled',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        );
      case 'cancelled':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '⚠️ Job Assignment Cancelled',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final data = _bookingData ?? {};
    final booking = data['booking'] as Map<String, dynamic>? ?? {};
    final service = data['service'] as Map<String, dynamic>? ?? {};
    final category = data['category'] as Map<String, dynamic>? ?? {};
    final address = data['address'] as Map<String, dynamic>? ?? {};
    final customer = data['customer'] as Map<String, dynamic>? ?? {};

    final bookingId = booking['id']?.toString() ?? widget.bookingId ?? 'N/A';
    final serviceName = service['name']?.toString() ?? 'Service Details';
    final categoryName = category['name']?.toString() ?? 'Category';
    final customerName = customer['username']?.toString() ?? 'Customer';
    final customerEmail = customer['email']?.toString() ?? '';
    final customerMobile = customer['mobile']?.toString() ?? '';
    final customerInitial =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C';

    final scheduledDate = _formatDate(booking['scheduledDate']);
    final scheduledTime = booking['scheduledTime']?.toString() ?? 'Not specified';
    final paymentMode = (booking['paymentMode']?.toString() ?? 'cash').toUpperCase();
    final paymentStatus = (booking['paymentStatus']?.toString() ?? 'pending').toUpperCase();
    final bookingStatus = (booking['bookingStatus']?.toString() ?? 'requested').toUpperCase();

    final originalAmount = booking['originalAmount'] ?? service['basePrice'] ?? 0;
    final discountAmount = booking['discountAmount'] ?? 0;
    final totalAmount = booking['totalAmount'] ?? originalAmount;

    final fullAddress = [
      address['house_number'],
      address['street_no_or_name'],
      address['city'],
      address['state'],
      address['pin_code'],
      address['country'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

    final latitude = address['latitude'];
    final longitude = address['longitude'];
    final notes = booking['notes']?.toString();
    final cancellationReason = booking['cancellationReason']?.toString();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Screen Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/bookings');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Manifest Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _fetchBookingDetails,
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Refresh details',
                  ),
                ],
              ),
            ),

            // Scrollable specifications
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    customerInitial,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        customerMobile.isNotEmpty
                                            ? customerMobile
                                            : customerEmail,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => context.push(
                              '/chat',
                              extra: {
                                'roomId': bookingId,
                                'recipientName': customerName,
                                'recipientPhoto': customer['photo']?.toString(),
                                'recipientId': customer['id']?.toString(),
                                'bookingId': bookingId,
                              },
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 0,
                            ),
                            child: const Text(
                              'Open Chat',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Service & Schedule Info Card
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
                                'SERVICE & SCHEDULE SPECIFICATIONS',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyMedium?.color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  categoryName.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: AppColors.secondary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                          if (service['description'] != null &&
                              service['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              service['description'].toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 10,
                                height: 1.3,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildReceiptRow('Scheduled Date:', scheduledDate, false),
                          const SizedBox(height: 6),
                          _buildReceiptRow('Time Slot:', scheduledTime, false),
                          const SizedBox(height: 6),
                          _buildReceiptRow('Payment Method:', paymentMode, false),
                          const SizedBox(height: 6),
                          _buildReceiptRow('Payment Status:', paymentStatus, false),
                          if (notes != null && notes.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Text(
                              'CLIENT NOTES:',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notes,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (cancellationReason != null &&
                              cancellationReason.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Text(
                              'CANCELLATION REASON:',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cancellationReason,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 10,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Address Coordinates Card
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
                          Text(
                            'SERVICE LOCATION COORDINATES',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📍', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      address['title']?.toString() ?? 'Target Destination',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fullAddress.isNotEmpty
                                          ? fullAddress
                                          : 'Address details not provided',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontSize: 10),
                                    ),
                                    if (latitude != null && longitude != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Lat: $latitude, Long: $longitude',
                                        style: GoogleFonts.inter(
                                          fontSize: 8.5,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Financial Receipt Card
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
                          Text(
                            'FINANCIAL RECEIPT ALLOCATION',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildReceiptRow(
                            'Base Rate / Original:',
                            '\$$originalAmount.00',
                            false,
                          ),
                          if (discountAmount > 0) ...[
                            const SizedBox(height: 6),
                            _buildReceiptRow(
                              'Coupon Discount:',
                              '-\$$discountAmount.00',
                              false,
                            ),
                          ],
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          _buildReceiptRow(
                            'Calculated Net Payout:',
                            '\$$totalAmount.00',
                            true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Workflow Control Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
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
                              Text(
                                'WORKFLOW CONTROL NODE',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'ID: ${bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId}',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              text: 'Current Process Allocation: ',
                              style: GoogleFonts.inter(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 11,
                              ),
                              children: [
                                TextSpan(
                                  text: bookingStatus,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildWorkflowNode(bookingStatus),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : null,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }
}
