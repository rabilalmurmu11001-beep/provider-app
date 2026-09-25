import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../stores/bookingProviders.dart';
import '../theme.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'Settled';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final asyncCompleted = ref.watch(
      providerAssignedBookingsProvider('completed'),
    );
    final completedList = asyncCompleted.value ?? [];

    double totalSettledEarnings = 0;
    for (final c in completedList) {
      final b = c['booking'] as Map<String, dynamic>? ?? {};
      final amount = b['totalAmount'] ?? b['originalAmount'] ?? 0;
      if (amount is num) {
        totalSettledEarnings += amount.toDouble();
      }
    }

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
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ledger Capital Balance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Main Ledger Section
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(providerAssignedBookingsProvider('completed'));
                  await ref.read(
                    providerAssignedBookingsProvider('completed').future,
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Withdrawable Balance Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1D4ED8), Color(0xFF312E81)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WITHDRAWABLE BALANCE ASSETS',
                              style: GoogleFonts.inter(
                                color: Colors.blue.shade100,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${totalSettledEarnings.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${completedList.length} total completed settlements',
                              style: TextStyle(
                                color: Colors.blue.shade200,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: totalSettledEarnings <= 0
                                    ? null
                                    : () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '⚡ Settlement Dispatched. Assets pending bank clearance.',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                child: Text(
                                  'Instant Settlement to Bank',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Historical records header
                      Text(
                        'HISTORICAL DEPOSIT RECORDS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (completedList.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 36,
                                color: AppColors.lightTextSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No completed settlements yet',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Complete dispatch orders to generate ledger payouts.',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...completedList.map((c) {
                          final b = c['booking'] as Map<String, dynamic>? ?? {};
                          final s = c['service'] as Map<String, dynamic>? ?? {};
                          final serviceName =
                              s['name']?.toString() ?? 'Service Settlement';
                          final dateStr = _formatDate(
                            b['scheduledDate'] ?? b['updatedAt'],
                          );
                          final bookingId = b['id']?.toString() ?? '82910';
                          final shortRef = bookingId.length > 8
                              ? bookingId.substring(0, 8).toUpperCase()
                              : bookingId.toUpperCase();
                          final amountNum =
                              b['totalAmount'] ?? b['originalAmount'] ?? 0;
                          final amount =
                              amountNum is num
                                  ? amountNum.toDouble()
                                  : double.tryParse(amountNum.toString()) ?? 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.dividerColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.03,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        serviceName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$dateStr • Ref #$shortRef',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(fontSize: 9.5),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+₹${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
