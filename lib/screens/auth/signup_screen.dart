import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../theme.dart';
import '../../services/authServices.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedCategory = 'Sanitization & Deep Cleaning';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data is Map) {
        final responseData = error.response?.data;
        if (responseData.containsKey('message')) {
          return responseData['message'].toString();
        }
        if (responseData.containsKey('error')) {
          return responseData['error'].toString();
        }
      }
      return error.message ?? 'An unexpected network error occurred';
    }
    return error.toString();
  }



  Future<void> _handleSignup() async {
    final username = _nameController.text.trim();
    final email = _emailController.text.trim();
    final rawMobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty) {
      _showErrorSnackBar('Please enter your full legal name');
      return;
    }
    if (username.length < 3) {
      _showErrorSnackBar('Name must be at least 3 characters long');
      return;
    }
    if (email.isEmpty) {
      _showErrorSnackBar('Please enter your business email');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }
    if (password.isEmpty) {
      _showErrorSnackBar('Please enter a password');
      return;
    }
    if (password.length < 8) {
      _showErrorSnackBar('Password must be at least 8 characters long');
      return;
    }

    String? cleanMobile;
    if (rawMobile.isNotEmpty) {
      final sanitized = rawMobile.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      final formatted = sanitized.startsWith('+') ? sanitized : '+91$sanitized';
      if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(formatted)) {
        _showErrorSnackBar(
          'Please enter a valid mobile number (10-15 digits) or leave it blank.',
        );
        return;
      }
      cleanMobile = formatted;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signup(
        username,
        password,
        email,
        cleanMobile,
      );

      final data = result.data is Map ? result.data : <String, dynamic>{};
      final signupToken = data['signupToken'] as String?;
      final requiresPhone = data['requiresPhoneVerification'] == true;
      final returnedEmail = data['email'] as String? ?? email;
      final returnedMobile = data['mobile'] as String? ?? cleanMobile;
      final message =
          data['message'] as String? ?? 'Verification code sent successfully.';

      if (mounted) {
        _showSuccessSnackBar(message);
        context.push(
          '/signup-otp',
          extra: {
            'signupToken': signupToken,
            'email': returnedEmail,
            'mobile': returnedMobile,
            'requiresPhoneVerification': requiresPhone,
          },
        );
      }
    } catch (err) {
      _showErrorSnackBar(_getErrorMessage(err));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
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
                const SizedBox(height: 32),

                // Form fields title
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

                // Form fields
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'John Hanson',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      style: const TextStyle(fontSize: 13),
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
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'hanson@solutions.com',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Mobile field
                    Row(
                      children: [
                        Text(
                          'Operator Mobile Number',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OPTIONAL',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                            color: theme.cardColor,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('�🇳', style: TextStyle(fontSize: 15)),
                              const SizedBox(width: 4),
                              Text(
                                '+91',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: '(555) 019-2834 (Optional)',
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    Text(
                      'Access Security Pin',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••••••••',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
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
                      value: _selectedCategory,
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
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Action buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Confirm Registration',
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
      ),
    );
  }
}