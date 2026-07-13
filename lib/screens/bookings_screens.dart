import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _activeTab = 'upcoming'; // upcoming, active, completed

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
                  Text(
                    'Job Dispatch Terminal',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
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
                        _buildTabButton('upcoming', 'Upcoming'),
                        _buildTabButton('active', 'Active'),
                        _buildTabButton('completed', 'Completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Panel List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [_buildTabContent()],
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
                      color: Colors.black.withOpacity(0.05),
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

  Widget _buildTabContent() {
    final theme = Theme.of(context);

    if (_activeTab == 'upcoming') {
      return Container(
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
                  'Sophia Rodriguez Suite',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AWAITING WINDOW',
                    style: GoogleFonts.inter(
                      color: AppColors.warning,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Deep Lounge sanitization process allocation assigned for tomorrow morning.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 10,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Base Price: ',
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 9,
                    ),
                    children: const [
                      TextSpan(
                        text: '\$85.00',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Scheduled May 26',
                  style: GoogleFonts.inter(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_activeTab == 'active') {
      return GestureDetector(
        onTap: () => context.go('/bookings/detail'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MANIFEST ALLOCATED',
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
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'STATE: ACCEPTED',
                        style: GoogleFonts.inter(
                          color: AppColors.warning,
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
                'Sofa Deep Chemical Wash',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Client Target: Emma Watson • 821 West End Dr',
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
                        fontSize: 9,
                      ),
                      children: const [
                        TextSpan(
                          text: '\$54.00',
                          style: TextStyle(
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
    } else {
      // Completed Tab
      return Opacity(
        opacity: 0.7,
        child: Container(
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
                    'Liam G. Residential Wash',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SETTLED',
                      style: GoogleFonts.inter(
                        color: AppColors.success,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Completed May 24. Funds verified inside system financial ledgers.',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }
  }
}
