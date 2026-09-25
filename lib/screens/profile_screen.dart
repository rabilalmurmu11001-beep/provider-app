import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/authServices.dart';
import '../services/notification_service.dart';
import '../services/socketService.dart';
import '../services/upload_service.dart';
import '../stores/bookingProviders.dart';
import '../stores/kyc_providers.dart';
import '../stores/providers.dart';
import '../theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    // Pre-fetch profile if not loaded yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(providerProfileProvider) == null) {
        ref.read(providerProfileAsyncProvider);
      }
    });
  }

  Future<void> _refreshProfile() async {
    ref.invalidate(providerProfileAsyncProvider);
    ref.invalidate(providerAssignedBookingsProvider('completed'));
    await ref.read(providerProfileAsyncProvider.future);
  }

  Future<void> _pickAndUploadProfilePhoto(
    ImageSource source, {
    void Function(void Function())? modalSetState,
    void Function(String newUrl)? onUploaded,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return; // User cancelled

      if (modalSetState != null) {
        modalSetState(() {});
      }
      setState(() => _isUploadingPhoto = true);

      // 1. Upload to S3 via backend /upload endpoint
      final uploadService = ref.read(uploadServiceProvider);
      final uploadResult = await uploadService.uploadFile(
        file: pickedFile,
        folder: 'avatars',
      );

      // 2. Persist new photo URL to user profile
      final authService = ref.read(authServiceProvider);
      final res = await authService.updateProfilePicture(uploadResult.url);

      // 3. Update cached state in Riverpod
      if (res.data is Map<String, dynamic> && res.data['user'] != null) {
        ref.read(providerProfileProvider.notifier).state = res.data['user'];
      }
      ref.invalidate(providerProfileAsyncProvider);

      if (onUploaded != null) {
        onUploaded(uploadResult.url);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profile picture updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
      if (modalSetState != null) {
        modalSetState(() {});
      }
    }
  }

  void _showPhotoPickerActionSheet(
    BuildContext context, {
    void Function(void Function())? modalSetState,
    void Function(String newUrl)? onUploaded,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Update Profile Picture',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose an option to change your avatar image',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Use camera to capture a new photo',
                    style: TextStyle(fontSize: 10),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickAndUploadProfilePhoto(
                      ImageSource.camera,
                      modalSetState: modalSetState,
                      onUploaded: onUploaded,
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Select an existing image from your device',
                    style: TextStyle(fontSize: 10),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickAndUploadProfilePhoto(
                      ImageSource.gallery,
                      modalSetState: modalSetState,
                      onUploaded: onUploaded,
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _promptOtpVerification({
    required BuildContext context,
    required String type, // 'email' or 'mobile'
    required String target,
  }) async {
    // 1. Show loading indicator while requesting OTP
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final authService = ref.read(authServiceProvider);
      if (type == 'email') {
        await authService.requestEmailUpdateOtp(target);
      } else {
        await authService.requestMobileUpdateOtp(target);
      }
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        String errorMsg = 'Failed to send verification code';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'] is List
                ? (data['message'] as List).join(', ')
                : data['message'].toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    if (!context.mounted) return false;

    // 2. Open OTP Verification Sheet
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ProfileOtpVerificationSheet(
        type: type,
        target: target,
      ),
    );

    return verified == true;
  }

  void _showEditProfileModal(
    BuildContext context,
    Map<String, dynamic> userProfile,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(
      text: userProfile['username']?.toString() ?? '',
    );
    String initialEmail = (userProfile['email']?.toString() ?? '').trim();
    String initialMobile = (userProfile['mobile']?.toString() ?? '').trim();
    bool isEmailVerified = userProfile['isEmailVerified'] == true;
    bool isPhoneVerified = userProfile['isPhoneVerified'] == true;

    final emailController = TextEditingController(
      text: initialEmail,
    );
    final mobileController = TextEditingController(
      text: initialMobile,
    );
    final addressController = TextEditingController(
      text: userProfile['address']?.toString() ?? '',
    );
    final ageController = TextEditingController(
      text: userProfile['age']?.toString() ?? '',
    );
    String selectedGender =
        (userProfile['gender']?.toString().toLowerCase() == 'female')
            ? 'female'
            : (userProfile['gender']?.toString().toLowerCase() == 'male')
            ? 'male'
            : (userProfile['gender']?.toString().toLowerCase() == 'other')
            ? 'other'
            : '';

    bool isSaving = false;
    String? currentModalPhoto = userProfile['photo']?.toString();
    final modalInitials = (userProfile['username']?.toString() ?? 'P').trim().isNotEmpty
        ? (userProfile['username']?.toString() ?? 'P')
            .trim()
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => s[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'P';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle pill
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Provider Profile',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Update operational contact and personal info',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(modalContext).pop(),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.dividerColor.withValues(
                                alpha: 0.3,
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Profile Picture Preview & Change Action in Modal
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: (currentModalPhoto != null &&
                                            currentModalPhoto!.isNotEmpty)
                                        ? Image.network(
                                            currentModalPhoto!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Center(
                                              child: Text(
                                                modalInitials,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              modalInitials,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                if (_isUploadingPhoto)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: _isUploadingPhoto
                                  ? null
                                  : () => _showPhotoPickerActionSheet(
                                        modalContext,
                                        modalSetState: setModalState,
                                        onUploaded: (url) {
                                          setModalState(() {
                                            currentModalPhoto = url;
                                          });
                                        },
                                      ),
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                'Change Profile Photo',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Full Name / Username
                      Text(
                        'FULL NAME / DISPLAY NAME',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: usernameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Display name cannot be empty';
                          }
                          if (value.trim().length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email Address
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EMAIL ADDRESS',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final currentText =
                                  emailController.text.trim().toLowerCase();
                              final hasChanged =
                                  currentText != initialEmail.toLowerCase();
                              final isVerified = !hasChanged && isEmailVerified;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isVerified
                                                  ? AppColors.success
                                                  : AppColors.warning)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isVerified
                                              ? Icons.check_circle
                                              : Icons.schedule,
                                          size: 10,
                                          color: isVerified
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isVerified
                                              ? 'Verified'
                                              : hasChanged
                                              ? 'Requires OTP'
                                              : 'Pending',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: isVerified
                                                ? AppColors.success
                                                : AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isVerified &&
                                      currentText.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () async {
                                        final emailRegex = RegExp(
                                          r'^[^@]+@[^@]+\.[^@]+$',
                                        );
                                        if (!emailRegex.hasMatch(currentText)) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please enter a valid email address first',
                                              ),
                                              backgroundColor: AppColors.danger,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        final ok = await _promptOtpVerification(
                                          context: modalContext,
                                          type: 'email',
                                          target: currentText,
                                        );
                                        if (ok) {
                                          setModalState(() {
                                            initialEmail = currentText;
                                            isEmailVerified = true;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '✓ Email verified successfully!',
                                                ),
                                                backgroundColor:
                                                    AppColors.success,
                                                behavior:
                                                  SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          'Verify with OTP',
                                          style: GoogleFonts.inter(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setModalState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email address cannot be empty';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'provider@example.com',
                          prefixIcon: Icon(Icons.email_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mobile Phone
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CONTACT MOBILE NUMBER',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final currentText = mobileController.text.trim();
                              final hasChanged = currentText != initialMobile;
                              final isVerified = !hasChanged && isPhoneVerified;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isVerified
                                                  ? AppColors.success
                                                  : AppColors.warning)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isVerified
                                              ? Icons.check_circle
                                              : Icons.schedule,
                                          size: 10,
                                          color: isVerified
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isVerified
                                              ? 'Verified'
                                              : hasChanged
                                              ? 'Requires OTP'
                                              : 'Pending',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: isVerified
                                                ? AppColors.success
                                                : AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isVerified &&
                                      currentText.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () async {
                                        final clean = currentText.replaceAll(
                                          RegExp(r'[\s-]'),
                                          '',
                                        );
                                        if (clean.length < 10 ||
                                            clean.length > 15) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please enter a valid mobile number (10-15 digits)',
                                              ),
                                              backgroundColor: AppColors.danger,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        final ok = await _promptOtpVerification(
                                          context: modalContext,
                                          type: 'mobile',
                                          target: currentText,
                                        );
                                        if (ok) {
                                          setModalState(() {
                                            initialMobile = currentText;
                                            isPhoneVerified = true;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '✓ Mobile number verified successfully!',
                                                ),
                                                backgroundColor:
                                                    AppColors.success,
                                                behavior:
                                                  SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          'Verify with OTP',
                                          style: GoogleFonts.inter(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setModalState(() {}),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final clean = value.trim().replaceAll(
                              RegExp(r'[\s-]'),
                              '',
                            );
                            if (clean.length < 10 || clean.length > 15) {
                              return 'Mobile number must be 10-15 digits';
                            }
                          }
                          return null;
                        },
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 9876543210',
                          prefixIcon: Icon(Icons.phone_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Operational Address
                      Text(
                        'PRIMARY OPERATIONAL ADDRESS',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: addressController,
                        maxLines: 2,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 104 Sector 4, Metro Hub',
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender & Age Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GENDER',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyMedium?.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedGender.isNotEmpty
                                          ? selectedGender
                                          : null,
                                      hint: Text(
                                        'Select',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color:
                                              theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                      dropdownColor: theme.cardColor,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'male',
                                          child: Text(
                                            'Male',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'female',
                                          child: Text(
                                            'Female',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'other',
                                          child: Text(
                                            'Other',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        setModalState(() {
                                          selectedGender = val ?? '';
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AGE',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyMedium?.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: ageController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value != null &&
                                        value.trim().isNotEmpty) {
                                      final ageVal = int.tryParse(value.trim());
                                      if (ageVal == null ||
                                          ageVal < 18 ||
                                          ageVal > 100) {
                                        return '18-100';
                                      }
                                    }
                                    return null;
                                  },
                                  style: GoogleFonts.inter(fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: 'Age',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    final newEmail = emailController.text
                                        .trim()
                                        .toLowerCase();
                                    final newMobile =
                                        mobileController.text.trim();

                                    // Verify email with OTP if changed or pending
                                    if (newEmail.isNotEmpty &&
                                        (newEmail !=
                                                initialEmail.toLowerCase() ||
                                            !isEmailVerified)) {
                                      final emailOk =
                                          await _promptOtpVerification(
                                            context: modalContext,
                                            type: 'email',
                                            target: newEmail,
                                          );
                                      if (!emailOk) return;
                                      initialEmail = newEmail;
                                      isEmailVerified = true;
                                    }

                                    // Verify mobile with OTP if changed or pending
                                    if (newMobile.isNotEmpty &&
                                        (newMobile != initialMobile ||
                                            !isPhoneVerified)) {
                                      if (!modalContext.mounted) return;
                                      final mobileOk =
                                          await _promptOtpVerification(
                                            context: modalContext,
                                            type: 'mobile',
                                            target: newMobile,
                                          );
                                      if (!mobileOk) return;
                                      initialMobile = newMobile;
                                      isPhoneVerified = true;
                                    }

                                    setModalState(() => isSaving = true);
                                    try {
                                      final payload = <String, dynamic>{
                                        'username':
                                            usernameController.text.trim(),
                                      };

                                      final address =
                                          addressController.text.trim();
                                      if (address.isNotEmpty) {
                                        payload['address'] = address;
                                      }

                                      if (selectedGender.isNotEmpty) {
                                        payload['gender'] = selectedGender;
                                      }

                                      final ageText = ageController.text.trim();
                                      if (ageText.isNotEmpty) {
                                        final parsedAge = int.tryParse(ageText);
                                        if (parsedAge != null) {
                                          payload['age'] = parsedAge;
                                        }
                                      }

                                      final authService = ref.read(
                                        authServiceProvider,
                                      );
                                      final res = await authService
                                          .updateUserProfile(payload);

                                      if (res.data is Map<String, dynamic> &&
                                          res.data['user'] != null) {
                                        ref
                                            .read(
                                              providerProfileProvider.notifier,
                                            )
                                            .state = res.data['user'];
                                      } else {
                                        // Refresh from API
                                        ref.invalidate(
                                          providerProfileAsyncProvider,
                                        );
                                      }

                                      if (modalContext.mounted) {
                                        Navigator.of(modalContext).pop();
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '✓ Provider profile updated successfully!',
                                            ),
                                            backgroundColor: AppColors.success,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => isSaving = false);
                                      if (context.mounted) {
                                        String msg =
                                            'Failed to update profile: $e';
                                        if (e is DioException &&
                                            e.response?.data != null) {
                                          final d = e.response!.data;
                                          if (d is Map &&
                                              d['message'] != null) {
                                            msg = d['message'] is List
                                                ? (d['message'] as List).join(
                                                    ', ',
                                                  )
                                                : d['message'].toString();
                                          }
                                        }
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(msg),
                                            backgroundColor: AppColors.danger,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Save Specifications',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch both state and async provider
    final cachedProfile = ref.watch(providerProfileProvider);
    final asyncProfile = ref.watch(providerProfileAsyncProvider);

    // Watch completed bookings to calculate real-time stats
    final asyncCompleted = ref.watch(
      providerAssignedBookingsProvider('completed'),
    );
    final completedList = asyncCompleted.value ?? [];

    double totalSettledEarnings = 0;
    for (final c in completedList) {
      final b = c['booking'] as Map<String, dynamic>? ?? {};
      final amount = b['totalAmount'] ?? b['originalAmount'] ?? 0;
      if (amount is num) {
        totalSettledEarnings += amount.toDouble();
      }
    }

    final user = cachedProfile ?? asyncProfile.value;
    final isLoading = user == null && asyncProfile.isLoading;
    final hasError = user == null && asyncProfile.hasError;

    if (isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load Provider Profile',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${asyncProfile.error}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry Connection'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final userData = user ?? <String, dynamic>{};
    final username = userData['username']?.toString() ?? 'Service Provider';
    final email = userData['email']?.toString() ?? 'provider@network.local';
    final mobile = userData['mobile']?.toString() ?? 'Not configured';
    final address = userData['address']?.toString() ?? 'Service Radius Active';
    final photo = userData['photo']?.toString();
    final role = (userData['role']?.toString() ?? 'service_provider')
        .replaceAll('_', ' ')
        .toUpperCase();
    final isEmailVerified = userData['isEmailVerified'] == true;
    final isPhoneVerified = userData['isPhoneVerified'] == true;

    final initials = username.trim().isNotEmpty
        ? username
            .trim()
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => s[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'SP';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Top Header Card (Profile Identity)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.05,
                        ),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Provider Command Center',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _showEditProfileModal(context, userData),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Edit Profile Details',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.08,
                              ),
                              padding: const EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Avatar with Photo Upload, Camera Badge & Online Dot
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: _isUploadingPhoto
                                ? null
                                : () => _showPhotoPickerActionSheet(context),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (photo != null && photo.trim().isNotEmpty)
                                      Image.network(
                                        photo.trim(),
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Center(
                                            child: Text(
                                              initials,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    else
                                      Center(
                                        child: Text(
                                          initials,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                    // Uploading progress overlay
                                    if (_isUploadingPhoto)
                                      Container(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        alignment: Alignment.center,
                                        child: const SizedBox(
                                          width: 26,
                                          height: 26,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Online Status Dot (Top-Right)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.cardColor,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),

                          // Camera / Edit Badge (Bottom-Right)
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: GestureDetector(
                              onTap: _isUploadingPhoto
                                  ? null
                                  : () => _showPhotoPickerActionSheet(context),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.cardColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Provider Name
                      Text(
                        username,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'VERIFIED $role NODE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Body Specifications
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Real-time Metrics Row (API Integrated)
                      Row(
                        children: [
                          _buildMetricItem(
                            theme,
                            'FULFILLED',
                            '${completedList.length}',
                            null,
                          ),
                          const SizedBox(width: 10),
                          _buildMetricItem(
                            theme,
                            'SETTLED PAYOUT',
                            '\$${totalSettledEarnings.toStringAsFixed(2)}',
                            AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          _buildMetricItem(
                            theme,
                            'NODE STATUS',
                            'ONLINE',
                            AppColors.secondary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Ledger balance & Earnings Banner
                      InkWell(
                        onTap: () => context.go('/earnings'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.02,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '\$${totalSettledEarnings.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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

                      // Account Credentials & Info Card
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'IDENTITY & OPERATIONAL CREDENTIALS',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyMedium?.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                InkWell(
                                  onTap: () =>
                                      _showEditProfileModal(context, userData),
                                  child: Text(
                                    'Edit Info',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildInfoRow(
                              theme: theme,
                              icon: Icons.email_outlined,
                              label: 'Email Gateway',
                              value: email,
                              verified: isEmailVerified,
                              onVerifyTap: isEmailVerified
                                  ? null
                                  : () async {
                                      final ok = await _promptOtpVerification(
                                        context: context,
                                        type: 'email',
                                        target: email,
                                      );
                                      if (ok && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '✓ Email verified successfully!',
                                            ),
                                            backgroundColor: AppColors.success,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                            ),
                            const Divider(height: 18),
                            _buildInfoRow(
                              theme: theme,
                              icon: Icons.phone_android_outlined,
                              label: 'Mobile Node',
                              value: mobile,
                              verified: isPhoneVerified,
                              onVerifyTap: isPhoneVerified ||
                                      mobile == 'Not configured' ||
                                      mobile.isEmpty
                                  ? null
                                  : () async {
                                      final ok = await _promptOtpVerification(
                                        context: context,
                                        type: 'mobile',
                                        target: mobile,
                                      );
                                      if (ok && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '✓ Mobile number verified successfully!',
                                            ),
                                            backgroundColor: AppColors.success,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                            ),
                            const Divider(height: 18),
                            _buildInfoRow(
                              theme: theme,
                              icon: Icons.location_on_outlined,
                              label: 'Service Headquarters',
                              value: address,
                            ),
                            if (userData['gender'] != null ||
                                userData['age'] != null) ...[
                              const Divider(height: 18),
                              _buildInfoRow(
                                theme: theme,
                                icon: Icons.badge_outlined,
                                label: 'Demographics',
                                value: [
                                  if (userData['gender'] != null)
                                    'Gender: ${userData['gender']}',
                                  if (userData['age'] != null)
                                    'Age: ${userData['age']}',
                                ].join(' • '),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Operations Navigation Card
                      Material(
                        color: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              title: const Text(
                                'Manage Service Catalog',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Add or configure listed marketplace services',
                                style: TextStyle(fontSize: 9.5),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 16,
                              ),
                              onTap: () => context.go('/services'),
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            ListTile(
                              leading: const Icon(
                                Icons.list_alt_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              title: const Text(
                                'Job Dispatch History',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'View available, upcoming, and completed orders',
                                style: TextStyle(fontSize: 9.5),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 16,
                              ),
                              onTap: () => context.go('/bookings'),
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            ListTile(
                              leading: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              title: const Text(
                                'Client Communications Hub',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Direct messaging channels with active clients',
                                style: TextStyle(fontSize: 9.5),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 16,
                              ),
                              onTap: () => context.go('/chat'),
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            ListTile(
                              leading: const Icon(
                                Icons.notifications_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              title: const Text(
                                'Notification Center',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Dispatch alerts, booking notices, and client pings',
                                style: TextStyle(fontSize: 9.5),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ValueListenableBuilder<int>(
                                    valueListenable: NotificationService
                                        .instance.unreadCountNotifier,
                                    builder: (context, count, _) {
                                      if (count == 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count new',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                  ),
                                ],
                              ),
                              onTap: () => context.push('/notifications'),
                            ),
                          ],
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
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isDark
                                          ? 'Dark Mode Active'
                                          : 'Light Mode Active',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontSize: 9),
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
                                  activeThumbColor: Colors.white,
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

                      // KYC Verification Card
                      Consumer(
                        builder: (context, ref, _) {
                          final kycAsync = ref.watch(kycStatusAsyncProvider);
                          final status = (kycAsync.value?['status']?.toString() ??
                                  'not_submitted')
                              .toLowerCase();
                          final isVerified = kycAsync.value?['isVerified'] == true;

                          Color badgeBg;
                          Color badgeColor;
                          String badgeText;
                          IconData badgeIcon;

                          if (isVerified || status == 'approved') {
                            badgeBg = AppColors.success.withValues(alpha: 0.15);
                            badgeColor = AppColors.success;
                            badgeText = 'VERIFIED';
                            badgeIcon = Icons.verified_rounded;
                          } else if (status == 'pending') {
                            badgeBg = AppColors.warning.withValues(alpha: 0.15);
                            badgeColor = AppColors.warning;
                            badgeText = 'IN REVIEW';
                            badgeIcon = Icons.hourglass_top_rounded;
                          } else if (status == 'rejected') {
                            badgeBg = AppColors.danger.withValues(alpha: 0.15);
                            badgeColor = AppColors.danger;
                            badgeText = 'ACTION REQ.';
                            badgeIcon = Icons.error_outline_rounded;
                          } else {
                            badgeBg = AppColors.primary.withValues(alpha: 0.15);
                            badgeColor = AppColors.primary;
                            badgeText = 'NOT VERIFIED';
                            badgeIcon = Icons.shield_outlined;
                          }

                          return InkWell(
                            onTap: () => context.push('/kyc'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isVerified
                                      ? AppColors.success.withValues(alpha: 0.4)
                                      : (status == 'rejected'
                                          ? AppColors.danger.withValues(alpha: 0.4)
                                          : theme.dividerColor),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(badgeIcon,
                                        color: badgeColor, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'KYC Verification',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                badgeText,
                                                style: TextStyle(
                                                  color: badgeColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isVerified
                                              ? 'Government ID verified. Account in good standing.'
                                              : (status == 'pending'
                                                  ? 'Submission under review by administrators.'
                                                  : (status == 'rejected'
                                                      ? 'Review issues found. Tap to resubmit.'
                                                      : 'Submit ID to go online and accept bookings.')),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
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
                              'VERIFICATION & SECURITY MATRIX',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Consumer(
                              builder: (context, ref, _) {
                                final kycAsync =
                                    ref.watch(kycStatusAsyncProvider);
                                final isVerified =
                                    kycAsync.value?['isVerified'] == true;
                                final status = (kycAsync.value?['status']
                                            ?.toString() ??
                                        '')
                                    .toLowerCase();
                                final label = isVerified
                                    ? 'Identity Verification (KYC) Approved'
                                    : (status == 'pending'
                                        ? 'Identity Verification (KYC) In Review'
                                        : (status == 'rejected'
                                            ? 'Identity Verification (KYC) Rejected'
                                            : 'Identity Verification (KYC) Required'));
                                return _buildChecklistItem(
                                  theme,
                                  label,
                                  isVerified,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildChecklistItem(
                              theme,
                              '256-bit Encrypted Banking Nodes Bonded',
                              true,
                            ),
                            const SizedBox(height: 8),
                            _buildChecklistItem(
                              theme,
                              isEmailVerified
                                  ? 'Email Gateway Verification Authenticated'
                                  : 'Email Gateway Verification Pending',
                              isEmailVerified,
                            ),
                            const SizedBox(height: 8),
                            _buildChecklistItem(
                              theme,
                              isPhoneVerified
                                  ? 'Mobile Multi-Factor Channel Verified'
                                  : 'Mobile Multi-Factor Channel Unlinked',
                              isPhoneVerified,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Log Out Action Card
                      InkWell(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: theme.cardColor,
                              title: Text(
                                'Confirm Sign Out',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to sign out of the provider gateway?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text(
                                    'Sign Out',
                                    style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final success = await ref
                                .read(authServiceProvider)
                                .logout();
                            if (success && context.mounted) {
                              SocketService.instance.disconnect();
                              ref.read(providerProfileProvider.notifier).state =
                                  null;
                              context.go('/login');
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: AppColors.danger,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sign Out Gateway',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.danger,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Terminate current active session logs',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: AppColors.danger,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    bool? verified,
    VoidCallback? onVerifyTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (verified != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (verified ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  verified ? Icons.check_circle : Icons.schedule,
                  size: 10,
                  color: verified ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 3),
                Text(
                  verified ? 'Verified' : 'Pending',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: verified ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          if (!verified && onVerifyTap != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onVerifyTap,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Verify',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
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
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(ThemeData theme, String text, bool isApproved) {
    return Row(
      children: [
        Icon(
          isApproved ? Icons.check_circle_outline : Icons.pending_outlined,
          size: 14,
          color: isApproved ? AppColors.success : AppColors.warning,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 10.5),
          ),
        ),
      ],
    );
  }
}

class _ProfileOtpVerificationSheet extends ConsumerStatefulWidget {
  final String type; // 'email' or 'mobile'
  final String target;

  const _ProfileOtpVerificationSheet({
    required this.type,
    required this.target,
  });

  @override
  ConsumerState<_ProfileOtpVerificationSheet> createState() =>
      _ProfileOtpVerificationSheetState();
}

class _ProfileOtpVerificationSheetState
    extends ConsumerState<_ProfileOtpVerificationSheet> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _countdown = 60;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
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

  Future<void> _handleResend() async {
    if (_countdown > 0 || _isResending) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      if (widget.type == 'email') {
        await authService.requestEmailUpdateOtp(widget.target);
      } else {
        await authService.requestMobileUpdateOtp(widget.target);
      }
      _startCountdown(60);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ New verification code sent'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      String msg = 'Failed to resend code';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          msg = d['message'] is List
              ? (d['message'] as List).join(', ')
              : d['message'].toString();
        }
      }
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the full 6-digit code';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      Response res;
      if (widget.type == 'email') {
        res = await authService.verifyEmailUpdateOtp(widget.target, code);
      } else {
        res = await authService.verifyMobileUpdateOtp(widget.target, code);
      }

      if (res.data is Map<String, dynamic> && res.data['user'] != null) {
        ref.read(providerProfileProvider.notifier).state = res.data['user'];
      } else {
        ref.invalidate(providerProfileAsyncProvider);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      String msg = 'Invalid verification code. Please check and try again.';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          msg = d['message'] is List
              ? (d['message'] as List).join(', ')
              : d['message'].toString();
        }
      }
      setState(() {
        _errorMessage = msg;
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEmail = widget.type == 'email';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pill
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEmail
                    ? Icons.mark_email_read_outlined
                    : Icons.phone_android_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              isEmail ? 'Verify New Email' : 'Verify Mobile Number',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the 6-digit code sent to',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.target,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // OTP 6-box input
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.0,
                  child: TextField(
                    controller: _otpController,
                    focusNode: _focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      setState(() {
                        if (_errorMessage != null) _errorMessage = null;
                      });
                      if (val.length == 6) {
                        _handleVerify();
                      }
                    },
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _focusNode.requestFocus(),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final text = _otpController.text;
                      final isEntered = index < text.length;
                      final isFocused =
                          _focusNode.hasFocus && index == text.length;
                      final digit = isEntered ? text[index] : '';

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 44,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isEntered
                              ? (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9))
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _errorMessage != null
                                ? AppColors.danger
                                : isFocused
                                    ? AppColors.primary
                                    : isEntered
                                        ? AppColors.primary.withValues(
                                            alpha: 0.5,
                                          )
                                        : theme.dividerColor,
                            width: isFocused ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          digit,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Resend section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive the code? ",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                if (_countdown > 0)
                  Text(
                    'Resend in ${_countdown}s',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                else
                  TextButton(
                    onPressed: _isResending ? null : _handleResend,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _isResending
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Resend Code',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Actions: Verify Button and Cancel
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _handleVerify,
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Verify & Confirm',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
