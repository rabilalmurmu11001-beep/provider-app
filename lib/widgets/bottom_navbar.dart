import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class ProviderBottomNavbar extends StatelessWidget {
  final String activeTab;

  const ProviderBottomNavbar({
    super.key,
    required this.activeTab,
  });

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String tabName,
    required String routePath,
  }) {
    final isActive = activeTab == tabName;
    final color = isActive ? AppColors.primary : AppColors.lightTextSecondary;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isActive) {
            context.go(routePath);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.analytics_outlined,
            label: 'Dashboard',
            tabName: 'dashboard',
            routePath: '/dashboard',
          ),
          _buildNavItem(
            context: context,
            icon: Icons.list_alt_outlined,
            label: 'Bookings',
            tabName: 'bookings',
            routePath: '/bookings',
          ),
          _buildNavItem(
            context: context,
            icon: Icons.inventory_2_outlined,
            label: 'Services',
            tabName: 'services',
            routePath: '/services',
          ),
          _buildNavItem(
            context: context,
            icon: Icons.account_circle_outlined,
            label: 'Account',
            tabName: 'profile',
            routePath: '/profile',
          ),
        ],
      ),
    );
  }
}
