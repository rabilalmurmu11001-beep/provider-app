import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../theme.dart';
import '../../services/authServices.dart';
import '../../services/socketService.dart';
import '../../services/notification_service.dart';
import '../../secureStorage.dart';
import '../../stores/providers.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String? signupToken;
  final String email;
  final String? mobile;
  final bool requiresPhoneVerification;

  const OtpVerificationScreen({
    super.key,
    this.signupToken,
    required this.email,
    this.mobile,
    this.requiresPhoneVerification = false,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _emailOtpController = TextEditingController();
  final TextEditingController _phoneOtpController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isResending = false;
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;

  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _emailOtpController.dispose();
    _phoneOtpController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown([int seconds = 60]) {
    setState(() {
      _countdown = seconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _countdown = 0;
        });
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
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

  Future<void> _handleResendOtp({String type = 'all'}) async {
    if (_countdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final res = await authService.resendSignupOtp(
        signupToken: widget.signupToken,
        email: widget.email,
        type: type,
      );

      if (mounted) {
        setState(() {
          _isResending = false;
        });
        _startCountdown(60);

        final message = res.data is Map && res.data['message'] != null
            ? res.data['message'].toString()
            : 'Verification code resent successfully.';

        _showSuccessSnackBar(message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
        _showErrorSnackBar(_getErrorMessage(e));
      }
    }
  }

  Future<void> _handleVerify() async {
    final emailOtp = _emailOtpController.text.trim();
    final phoneOtp = _phoneOtpController.text.trim();

    // Check validation
    if (!_isEmailVerified && emailOtp.length < 6) {
      _showErrorSnackBar('Please enter the 6-digit email verification code.');
      _emailFocusNode.requestFocus();
      return;
    }

    if (widget.requiresPhoneVerification &&
        !_isPhoneVerified &&
        phoneOtp.length < 6) {
      _showErrorSnackBar('Please enter the 6-digit mobile verification code.');
      _phoneFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final res = await authService.verifySignupOtp(
        signupToken: widget.signupToken,
        email: widget.email,
        emailOtp: _isEmailVerified ? null : emailOtp,
        phoneOtp: (!widget.requiresPhoneVerification || _isPhoneVerified)
            ? null
            : phoneOtp,
      );

      final data = res.data is Map ? res.data : <String, dynamic>{};
      final bool isFullyVerified = data['verified'] == true;

      if (isFullyVerified) {
        final String? token = data['token']?.toString();
        if (token != null && token.isNotEmpty) {
          await TokenRepository().persistToken(token);
          SocketService.instance.connect(token);
          try {
            await NotificationService.instance.syncTokenWithBackend();
          } catch (_) {}
        }

        if (data['user'] is Map<String, dynamic>) {
          ref.read(providerProfileProvider.notifier).state =
              data['user'] as Map<String, dynamic>;
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSuccessSnackBar('Provider profile verified and activated successfully!');
          context.go('/dashboard');
        }
      } else {
        // Partial verification state (e.g. Email verified, phone still pending)
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isEmailVerified = data['emailVerified'] == true;
            _isPhoneVerified = data['phoneVerified'] == true;
          });

          final message = data['message']?.toString() ??
              'Partial verification complete. Please enter the remaining code.';
          _showSuccessSnackBar(message);

          if (_isEmailVerified && !_isPhoneVerified) {
            _phoneFocusNode.requestFocus();
          } else if (!_isEmailVerified && _isPhoneVerified) {
            _emailFocusNode.requestFocus();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(_getErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasMobile = widget.requiresPhoneVerification &&
        widget.mobile != null &&
        widget.mobile!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: theme.textTheme.titleLarge?.color,
          ),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
        title: Text(
          'Identity Authorization',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Security Badge Icon Header
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            size: 34,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: Text(
                          hasMobile
                              ? 'Verify Email & Mobile'
                              : 'Verify Email Address',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          hasMobile
                              ? 'Enter the 6-digit verification codes sent to your registered email and mobile number.'
                              : 'Enter the 6-digit verification code sent to your registered email address.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.4,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Email OTP Section
                      _buildOtpSection(
                        title: 'BUSINESS EMAIL OTP',
                        destination: widget.email,
                        icon: Icons.email_outlined,
                        controller: _emailOtpController,
                        focusNode: _emailFocusNode,
                        isVerified: _isEmailVerified,
                        theme: theme,
                        isDark: isDark,
                      ),

                      // Mobile OTP Section (Only if mobile was provided)
                      if (hasMobile) ...[
                        const SizedBox(height: 20),
                        _buildOtpSection(
                          title: 'OPERATOR MOBILE SMS OTP',
                          destination: widget.mobile!,
                          icon: Icons.phone_android_rounded,
                          controller: _phoneOtpController,
                          focusNode: _phoneFocusNode,
                          isVerified: _isPhoneVerified,
                          theme: theme,
                          isDark: isDark,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Resend Code Section
                      _buildResendSection(theme, hasMobile),

                      const Spacer(),
                      const SizedBox(height: 32),

                      // Verify & Complete Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerify,
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
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Text(
                                  'Verify & Activate Profile',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Back to edit info
                      Center(
                        child: TextButton(
                          onPressed: _isLoading ? null : () => context.pop(),
                          child: Text(
                            'Entered wrong details? Change them',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOtpSection({
    required String title,
    required String destination,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isVerified,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isVerified
              ? AppColors.success.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 13, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            destination,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          if (isVerified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Code successfully verified ✓',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            )
          else
            _PinCodeInputField(
              controller: controller,
              focusNode: focusNode,
              length: 6,
              theme: theme,
              isDark: isDark,
              onChanged: (_) {
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResendSection(ThemeData theme, bool hasMobile) {
    return Center(
      child: Column(
        children: [
          if (_countdown > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  'Resend code in ${_countdown.toString().padLeft(2, '0')}s',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ] else ...[
            if (_isResending)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleResendOtp(type: 'all'),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      hasMobile ? 'Resend All Codes' : 'Resend Code',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  if (hasMobile) ...[
                    if (!_isEmailVerified)
                      TextButton(
                        onPressed: () => _handleResendOtp(type: 'email'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.textTheme.bodyMedium?.color,
                        ),
                        child: const Text(
                          'Resend Email Only',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (!_isPhoneVerified)
                      TextButton(
                        onPressed: () => _handleResendOtp(type: 'phone'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.textTheme.bodyMedium?.color,
                        ),
                        child: const Text(
                          'Resend SMS Only',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _PinCodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final ThemeData theme;
  final bool isDark;
  final ValueChanged<String>? onChanged;

  const _PinCodeInputField({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.theme,
    required this.isDark,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Hidden input capturing keystrokes and system paste events
        Opacity(
          opacity: 0.0,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            maxLength: length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onChanged,
            showCursor: false,
            enableInteractiveSelection: true,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),

        // Visual digit container boxes
        GestureDetector(
          onTap: () => focusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(length, (index) {
              final text = controller.text;
              final isEntered = index < text.length;
              final isFocused = focusNode.hasFocus && index == text.length;
              final digit = isEntered ? text[index] : '';

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isEntered
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : (isDark ? AppColors.darkBg : theme.scaffoldBackgroundColor),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primary
                        : isEntered
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : (isDark ? AppColors.darkBorder : theme.dividerColor),
                    width: isFocused ? 1.8 : 1.0,
                  ),
                ),
                child: Text(
                  digit,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
