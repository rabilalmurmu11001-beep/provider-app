import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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
                    onPressed: () => context.go('/login'),
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
                    'Ecosystem Capture',
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
                    'Create Provider Profile 🚀',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Setup catalog credentials and join local rosters.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  // Legal Name field
                  Text(
                    'Full Legal Operator Name',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'John Hanson',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  Text(
                    'Business Email Anchor',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'hanson@solutions.com',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Category field
                  Text(
                    'Primary Core Category',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: 'Sanitization & Deep Cleaning',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 13,
                    ),
                    dropdownColor: theme.cardColor,
                    decoration: const InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Sanitization & Deep Cleaning',
                        child: Text('Sanitization & Deep Cleaning'),
                      ),
                      DropdownMenuItem(
                        value: 'HVAC Logistics & Engineering',
                        child: Text('HVAC Logistics & Engineering'),
                      ),
                      DropdownMenuItem(
                        value: 'Electrical System Infrastructure',
                        child: Text('Electrical System Infrastructure'),
                      ),
                    ],
                    onChanged: (value) {},
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
                        'Publish Profile Matrix',
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
                        'Registered already? ',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
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