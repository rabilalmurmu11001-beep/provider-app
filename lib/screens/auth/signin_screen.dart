import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Back Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go('/onboarding'),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  Text(
                    'Secure Verification',
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),

              // Form fields
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back 👋',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to sync operational queues and active payouts.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 36),

                  // Business Email field
                  Text(
                    'Operator Business Email',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const TextField(
                    controller: null, // static
                    decoration: InputDecoration(
                      hintText: 'hanson.pro@marketplace.com',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Access Security Pin',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Recover Key?',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const TextField(
                    obscureText: true,
                    controller: null,
                    decoration: InputDecoration(
                      hintText: '••••••••••••••',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),

              // Action buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go('/dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Authenticate Credentials',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New to the provider network? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: Text(
                          'Register Business',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
