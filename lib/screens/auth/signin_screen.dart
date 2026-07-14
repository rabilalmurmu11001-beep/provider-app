import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../theme.dart';
import '../../services/authServices.dart';
import '../../secureStorage.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isEmailSelected = true;
  bool _isOtpSelected = false;
  bool _isOtpSent = false;
  bool _isLoading = false;
  int _countdown = 0;
  Timer? _timer;

  String otpToken = '';

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _countdown = 30;
      _isOtpSent = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String getFormattedIdentifier() {
    final raw = _identifierController.text.trim();
    if (_isEmailSelected) {
      return raw;
    } else {
      if (raw.startsWith('+')) {
        return raw;
      }
      return '+1$raw';
    }
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

  String? _extractToken(Response response) {
    if (response.data == null) return null;
    final data = response.data;
    if (data is Map) {
      if (data.containsKey('token')) {
        return data['token']?.toString();
      }
      if (data.containsKey('accessToken')) {
        return data['accessToken']?.toString();
      }
      if (data.containsKey('data') && data['data'] is Map) {
        final nestedData = data['data'];
        if (nestedData.containsKey('token')) {
          return nestedData['token']?.toString();
        }
        if (nestedData.containsKey('accessToken')) {
          return nestedData['accessToken']?.toString();
        }
      }
    }
    return null;
  }

  Future<void> _resendOtp() async {
    final formattedIdentifier = getFormattedIdentifier();
    if (formattedIdentifier.isEmpty) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.requestOtp(formattedIdentifier);
      _startTimer();
      _showSuccessSnackBar('Verification code resent successfully!');
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

  Future<void> _handlePrimaryButtonPress() async {
    final formattedIdentifier = getFormattedIdentifier();

    if (formattedIdentifier.isEmpty) {
      _showErrorSnackBar(
        _isEmailSelected
            ? 'Please enter your email address'
            : 'Please enter your mobile number',
      );
      return;
    }

    final authService = ref.read(authServiceProvider);

    if (_isOtpSelected && !_isOtpSent) {
      // Step 1: Request OTP
      setState(() {
        _isLoading = true;
      });
      try {
        final response = await authService.requestOtp(formattedIdentifier);
        otpToken = response.data['otpToken'];
        print(otpToken);
        _startTimer();
        _showSuccessSnackBar('Verification code sent successfully!');
      } catch (err) {
        _showErrorSnackBar(_getErrorMessage(err));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_isOtpSelected && _isOtpSent) {
      // Step 2: Verify OTP
      final otp = _otpController.text.trim();
      if (otp.isEmpty || otp.length < 6) {
        _showErrorSnackBar('Please enter a valid 6-digit verification code');
        return;
      }

      setState(() {
        _isLoading = true;
      });
      try {
        final result = await authService.verifyOtp(otpToken, otp);
        final token = _extractToken(result);
        if (token != null) {
          await TokenRepository().persistToken(token);
          if (mounted) {
            _showSuccessSnackBar('Authenticated successfully!');
            context.go('/dashboard');
          }
        } else {
          _showErrorSnackBar(
            'Authentication token not found in server response',
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
    } else {
      // Password auth
      final password = _passwordController.text.trim();
      if (password.isEmpty) {
        _showErrorSnackBar('Please enter your password');
        return;
      }

      setState(() {
        _isLoading = true;
      });
      try {
        final Response result;
        if (_isEmailSelected) {
          result = await authService.emaillogin(formattedIdentifier, password);
        } else {
          result = await authService.phonelogin(formattedIdentifier, password);
        }

        final token = _extractToken(result);
        if (token != null) {
          await TokenRepository().persistToken(token);
          if (mounted) {
            _showSuccessSnackBar('Authenticated successfully!');
            context.go('/dashboard');
          }
        } else {
          _showErrorSnackBar(
            'Authentication token not found in server response',
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
                const SizedBox(height: 32),

                // Form header
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
                const SizedBox(height: 32),

                // 1. Selector Row for Email vs Mobile
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            // Email Option
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isEmailSelected = true;
                                    _isOtpSent = false;
                                    _timer?.cancel();
                                    _countdown = 0;
                                    _otpController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isEmailSelected
                                        ? theme.cardColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isEmailSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Email Address',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _isEmailSelected
                                          ? theme.textTheme.titleMedium?.color
                                          : theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Mobile Option
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isEmailSelected = false;
                                    _isOtpSent = false;
                                    _timer?.cancel();
                                    _countdown = 0;
                                    _otpController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isEmailSelected
                                        ? theme.cardColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_isEmailSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Mobile Number',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: !_isEmailSelected
                                          ? theme.textTheme.titleMedium?.color
                                          : theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Main Identifier Input (Email or Mobile)
                Text(
                  _isEmailSelected
                      ? 'Operator Business Email'
                      : 'Operator Mobile Number',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyMedium?.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (_isEmailSelected)
                  TextField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'hanson.pro@marketplace.com',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    style: const TextStyle(fontSize: 13),
                  )
                else
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
                            const Text('🇺🇸', style: TextStyle(fontSize: 15)),
                            const SizedBox(width: 4),
                            Text(
                              '+1',
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
                          controller: _identifierController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '(555) 019-2834',
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // 3. Credentials Method Selector Toggle
                Text(
                  'Authentication Method',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyMedium?.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            // Password Option
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isOtpSelected = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isOtpSelected
                                        ? theme.cardColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_isOtpSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Password',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: !_isOtpSelected
                                          ? theme.textTheme.titleMedium?.color
                                          : theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // OTP Option
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isOtpSelected = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isOtpSelected
                                        ? theme.cardColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isOtpSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'One-Time OTP',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _isOtpSelected
                                          ? theme.textTheme.titleMedium?.color
                                          : theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Verification Input (Password or OTP Field)
                if (!_isOtpSelected) ...[
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
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: '••••••••••••••',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ] else ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _isOtpSent
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'One-Time Verification Code',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyMedium?.color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: InputDecoration(
                                  hintText: '123456',
                                  counterText: '',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                  suffixIcon: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    alignment: Alignment.centerRight,
                                    width: 80,
                                    child: _countdown > 0
                                        ? Text(
                                            '${_countdown}s',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: theme
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                            ),
                                          )
                                        : TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : _resendOtp,
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(50, 30),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              'Resend',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'A secure 6-digit code will be generated and transmitted.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 11.5,
                                      color: theme.textTheme.bodyLarge?.color,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
                const SizedBox(height: 36),

                // Action buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _handlePrimaryButtonPress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isOtpSelected && !_isOtpSent
                                    ? 'Request Verification Code'
                                    : 'Authenticate Credentials',
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
      ),
    );
  }
}
