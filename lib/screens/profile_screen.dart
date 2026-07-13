import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Section (Profile details)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'JH',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'John Hanson Professional',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vetted Elite Security Grade',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Profile metrics & options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metrics row
                    Row(
                      children: [
                        _buildMetricItem(theme, 'FULFILLED', '452', null),
                        const SizedBox(width: 10),
                        _buildMetricItem(
                          theme,
                          'AGG SCORING',
                          '★ 4.9',
                          AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        _buildMetricItem(
                          theme,
                          'RESPONSE',
                          '12m',
                          AppColors.secondary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Ledger access banner
                    InkWell(
                      onTap: () => context.go('/earnings'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ledger Balance Assets',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Withdraw funds or view receipts ledger',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '\$1,250.00',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Theme toggle card for mobile
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDark
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Interface Theme',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isDark
                                        ? 'Dark Mode Active'
                                        : 'Light Mode Active',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeModeNotifier,
                            builder: (context, currentMode, _) {
                              return Switch(
                                value: currentMode == ThemeMode.dark,
                                activeColor: Colors.white,
                                activeTrackColor: AppColors.primary,
                                onChanged: (val) {
                                  themeModeNotifier.value = val
                                      ? ThemeMode.dark
                                      : ThemeMode.light;
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Verification checklist card
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
                            'Verification Checklist Tokens',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildChecklistItem(
                            theme,
                            'Identity Verification Baseline Approved',
                          ),
                          const SizedBox(height: 8),
                          _buildChecklistItem(
                            theme,
                            '256-bit Encrypted Banking Nodes Bonded',
                          ),
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

  Widget _buildMetricItem(
    ThemeData theme,
    String label,
    String value,
    Color? valueColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(ThemeData theme, String text) {
    return Row(
      children: [
        const Icon(Icons.check, size: 14, color: AppColors.success),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
