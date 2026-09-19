import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'bottom_navbar.dart';

class ResponsiveConsoleShell extends StatelessWidget {
  final Widget child;

  const ResponsiveConsoleShell({
    super.key,
    required this.child,
  });

  // Get path description for the UI Inspector
  Map<String, String> _getInspectorSpecs(String path) {
    switch (path) {
      case '/':
        return {
          'title': '1. Splash Gateway',
          'desc': 'Clean minimalist mobile entry framework displaying brand icon and entering animation sequence.',
        };
      case '/onboarding':
        return {
          'title': '2. Operational Carousel',
          'desc': 'Linear multi-step slider introducing providers to platform operations, payout analytics, and live schedules.',
        };
      case '/login':
        return {
          'title': '3. Secure Sign In',
          'desc': 'High density account authentication viewport using structured text inputs and responsive form parameters.',
        };
      case '/signup':
        return {
          'title': '4. Rapid Registration',
          'desc': 'Simplified provider profile mapping template optimized for step-by-step business verification setup.',
        };
      case '/dashboard':
        return {
          'title': '15. Earnings Cockpit',
          'desc': 'Aggregated high-density professional telemetry displaying core operational metrics, active task pipelines, and automated performance charts.',
        };
      case '/bookings':
        return {
          'title': '18. Job Dispatch Engine',
          'desc': 'Segmented tab filters tracking pipeline allocations. Built for rapid assessment of delivery records under time constraints.',
        };
      case '/bookings/detail':
        return {
          'title': '18b. Job Manifest Specs',
          'desc': 'Comprehensive structural operational documentation mapping service locations, detailed breakdown matrices, and active workflow triggers.',
        };
      case '/chat':
        return {
          'title': '12. Live Client Terminal',
          'desc': 'Integrated operational communication interface showcasing real-time location tags and responsive canned macro responses.',
        };
      case '/services':
        return {
          'title': '17. Catalog Directory',
          'desc': 'Granular dashboard list tracking catalog entries, custom package details, and instant marketplace availability controls.',
        };
      case '/services/add':
        return {
          'title': '16. Offer Catalog Creator',
          'desc': 'Input node architected with error boundaries allowing operators to package and price marketplace solutions dynamically.',
        };
      case '/earnings':
        return {
          'title': '19. Financial Ledger Hub',
          'desc': 'Transaction history framework tracking withdrawal logs, operational cash outputs, and instant bank settlements.',
        };
      case '/profile':
        return {
          'title': '20. Public Trust Portfolio',
          'desc': 'Public verification portal charting client aggregation scoring matrices, service histories, and trade badges.',
        };
      default:
        return {
          'title': 'Active Workspace',
          'desc': 'Operational viewport showcasing sandbox environment metrics.',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final state = GoRouterState.of(context);
    final currentPath = state.uri.toString();

    final showNavbar = currentPath == '/dashboard' ||
        currentPath == '/bookings' ||
        currentPath == '/services' ||
        currentPath == '/profile' ||
        currentPath == '/earnings';

    String activeTab = 'dashboard';
    if (currentPath == '/bookings') {
      activeTab = 'bookings';
    } else if (currentPath == '/services') {
      activeTab = 'services';
    } else if (currentPath == '/profile' || currentPath == '/earnings') {
      activeTab = 'profile';
    }

    // If screen width is 900px or less, render the pure mobile screen directly
    if (size.width <= 900) {
      if (showNavbar) {
        return Scaffold(
          body: child,
          bottomNavigationBar: ProviderBottomNavbar(activeTab: activeTab),
        );
      } else {
        return Scaffold(
          body: child,
        );
      }
    }

    final specs = _getInspectorSpecs(currentPath);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. Left Sidebar
          _buildLeftSidebar(context, currentPath, isDark),

          // 2. Middle Frame Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(color: theme.dividerColor, width: 1),
                ),
              ),
              child: Column(
                children: [
                  _buildMiddleHeader(context, specs['title']!, isDark),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: isDark
                              ? [
                                  AppColors.primary.withOpacity(0.15),
                                  Colors.transparent,
                                ]
                              : [
                                  AppColors.primary.withOpacity(0.06),
                                  Colors.transparent,
                                ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _buildPhoneMockup(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Right Sidebar (Inspector)
          _buildRightSidebar(context, specs, isDark),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar(BuildContext context, String currentPath, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      width: 290,
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo & Branding
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'P',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ProtoServe Pro',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            'Provider Workspace Hub',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Version badges
                Row(
                  children: [
                    _buildVersionBadge('v4.5 Gate', Colors.blue),
                    const SizedBox(width: 8),
                    _buildVersionBadge('Auth Suite', AppColors.success),
                  ],
                ),
              ],
            ),
          ),

          // Menu list scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              children: [
                _buildSectionHeader('Intro & Authentication'),
                _buildSidebarItem(context, '1. System Splash Screen', '/', currentPath, 'Intro'),
                _buildSidebarItem(context, '2. Onboarding Carousel', '/onboarding', currentPath, 'Slides'),
                _buildSidebarItem(context, '3. Security Sign In', '/login', currentPath, 'Form'),
                _buildSidebarItem(context, '4. Fast Account Sign Up', '/signup', currentPath, 'Form'),
                
                const SizedBox(height: 24),
                
                _buildSectionHeader('Provider Ecosystem Modules'),
                _buildSidebarItem(context, '15. Earnings & KPI Analytics', '/dashboard', currentPath, 'Main'),
                _buildSidebarItem(context, '18. Job Dispatch Control', '/bookings', currentPath, '2 Live'),
                _buildSidebarItem(context, '18b. Job Manifest Specs', '/bookings/detail', currentPath, 'Specs'),
                _buildSidebarItem(context, '12. Live Client Thread Chat', '/chat', currentPath, 'Live'),
                _buildSidebarItem(context, '17. Managed Service Catalog', '/services', currentPath, 'Directory'),
                _buildSidebarItem(context, '16. Offer Catalog Creator', '/services/add', currentPath, 'Form'),
                _buildSidebarItem(context, '19. Financial Deposit Ledger', '/earnings', currentPath, 'Ledger'),
                _buildSidebarItem(context, '20. Public Trust Portfolio', '/profile', currentPath, 'Profile'),
              ],
            ),
          ),

          // Theme Selector Footer
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, currentMode, _) {
              return Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INTERFACE THEME',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          _buildThemeButton(
                            icon: Icons.light_mode,
                            isActive: currentMode == ThemeMode.light,
                            onTap: () => themeModeNotifier.value = ThemeMode.light,
                          ),
                          _buildThemeButton(
                            icon: Icons.dark_mode,
                            isActive: currentMode == ThemeMode.dark,
                            onTap: () => themeModeNotifier.value = ThemeMode.dark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleHeader(BuildContext context, String currentTitle, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      height: 56,
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Active Console Screen: ',
                style: GoogleFonts.poppins(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  currentTitle.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDark ? 'Dark Mode Active' : 'Light Mode Active',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Container(width: 1, height: 16, color: theme.dividerColor),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  context.go('/');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('State Pipeline Reset'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Reset Pipeline State',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRightSidebar(BuildContext context, Map<String, String> specs, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      width: 290,
      color: theme.cardColor,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UI/UX Live Inspector',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'State & Structural Metrics',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 24),
          
          // Token Specifications
          Text(
            'DESIGN SYSTEM TOKEN',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specs['title']!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  specs['desc']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Active Variables state
          Text(
            'ACTIVE VARIABLES STATE',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                _buildInspectorVariableRow('Availability:', 'ONLINE', AppColors.success),
                const SizedBox(height: 8),
                _buildInspectorVariableRow('Job Status:', 'ACCEPTED', AppColors.warning),
                const SizedBox(height: 8),
                _buildInspectorVariableRow('Net Wallet Balance:', '\$1,250.00', null),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Palette
          Text(
            'APPLIED COLORS PALETTE',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPaletteItem('PRIMARY', '#1E40AF', AppColors.primary, theme),
              const SizedBox(width: 12),
              _buildPaletteItem('ACCENT', '#7C3AED', AppColors.secondary, theme),
            ],
          ),
          
          const Spacer(),
          
          Text(
            'Designed for mobile business execution. Borders and line rules maintain strict sunlight scannability.',
            style: GoogleFonts.inter(
              fontSize: 9,
              height: 1.4,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget _buildPhoneMockup(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 390,
      height: 780,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // iPhone chassis outer border
        borderRadius: BorderRadius.circular(52),
        border: Border.all(
          color: const Color(0xFF334155).withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              // Phone Status Bar / Notch
              Container(
                height: 40,
                color: theme.cardColor,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '9:41',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // Dynamic notch
                    Container(
                      width: 90,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.6),
                                  blurRadius: 4,
                                )
                              ]
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.wifi, size: 12),
                      ],
                    ),
                  ],
                ),
              ),

              // Actual Route view
              Expanded(
                child: () {
                  final currentPath = GoRouterState.of(context).uri.toString();
                  final showNavbar = currentPath == '/dashboard' ||
                      currentPath == '/bookings' ||
                      currentPath == '/services' ||
                      currentPath == '/profile' ||
                      currentPath == '/earnings';

                  String activeTab = 'dashboard';
                  if (currentPath == '/bookings') {
                    activeTab = 'bookings';
                  } else if (currentPath == '/services') {
                    activeTab = 'services';
                  } else if (currentPath == '/profile' || currentPath == '/earnings') {
                    activeTab = 'profile';
                  }

                  if (showNavbar) {
                    return Scaffold(
                      body: child,
                      bottomNavigationBar: ProviderBottomNavbar(activeTab: activeTab),
                    );
                  } else {
                    return child;
                  }
                }(),
              ),

              // Bottom Home bar indicator
              Container(
                height: 16,
                color: theme.cardColor,
                alignment: Alignment.center,
                child: Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    String label,
    String routePath,
    String currentPath,
    String badgeText,
  ) {
    final isSelected = currentPath == routePath;
    final theme = Theme.of(context);

    Color badgeBg = theme.dividerColor;
    Color badgeTextCol = theme.textTheme.bodyMedium?.color ?? Colors.grey;

    if (badgeText == 'Intro') {
      badgeBg = Colors.blue.withOpacity(0.1);
      badgeTextCol = Colors.blue.shade600;
    } else if (badgeText == 'Slides') {
      badgeBg = Colors.amber.withOpacity(0.1);
      badgeTextCol = Colors.amber.shade700;
    } else if (badgeText == '2 Live' || badgeText == 'Live') {
      badgeBg = AppColors.primary.withOpacity(0.1);
      badgeTextCol = AppColors.primary;
    }

    return InkWell(
      onTap: () => context.go(routePath),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : theme.textTheme.bodyMedium?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.inter(
                  color: badgeTextCol,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildVersionBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive ? Colors.white : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildInspectorVariableRow(String label, String value, Color? color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.lightTextSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteItem(String label, String colorCode, Color color, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: AppColors.lightTextSecondary),
                  ),
                  Text(
                    colorCode,
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
