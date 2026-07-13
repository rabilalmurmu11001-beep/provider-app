import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _stepIndex = 1;

  final List<Map<String, String>> _slides = [
    {
      'icon': '💼',
      'header': 'Manage Live Dispatches',
      'desc':
          'Receive immediate customer dispatch orders complete with distance vectors and explicit component itemizations.',
    },
    {
      'icon': '📊',
      'header': 'Track Performance Analytics',
      'desc':
          'Inspect accurate weekly earnings logs, trade level metrics, and aggregate client rating scores.',
    },
    {
      'icon': '🏛️',
      'header': 'Instant Bank Payouts',
      'desc':
          'Liquidate clear capital reserves directly to your local verified banking coordinates with 256-bit data encryption.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSlide = _slides[_stepIndex - 1];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workspace Guide',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Skip',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Content slide
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Graphic Icon Card
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentSlide['icon']!,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    currentSlide['header']!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      currentSlide['desc']!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (idx) {
                      final active = (idx + 1) == _stepIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _stepIndex = idx + 1;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: active ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : theme.dividerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_stepIndex < 3) {
                      setState(() {
                        _stepIndex++;
                      });
                    } else {
                      context.go('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _stepIndex == 3 ? 'Launch Sign In' : 'Continue',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
