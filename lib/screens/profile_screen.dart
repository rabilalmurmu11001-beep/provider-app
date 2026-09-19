import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/authServices.dart';
import '../services/notification_service.dart';
import '../services/socketService.dart';
import '../stores/bookingProviders.dart';
import '../stores/providers.dart';
import '../theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
    final mobileController = TextEditingController(
      text: userProfile['mobile']?.toString() ?? '',
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
                      const SizedBox(height: 20),

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

                      // Mobile Phone
                      Text(
                        'CONTACT MOBILE NUMBER',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              value.trim().length != 10) {
                            return 'Mobile number must be 10 digits';
                          }
                          return null;
                        },
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 9876543210',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            size: 18,
                          ),
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
                                    setModalState(() => isSaving = true);
                                    try {
                                      final payload = <String, dynamic>{
                                        'username':
                                            usernameController.text.trim(),
                                      };

                                      final mobile =
                                          mobileController.text.trim();
                                      if (mobile.isNotEmpty) {
                                        payload['mobile'] = mobile;
                                      }

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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to update profile: $e',
                                            ),
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

                      // Avatar with Online Dot
                      Stack(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
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
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 18,
                              height: 18,
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
                            ),
                            const Divider(height: 18),
                            _buildInfoRow(
                              theme: theme,
                              icon: Icons.phone_android_outlined,
                              label: 'Mobile Node',
                              value: mobile,
                              verified: isPhoneVerified,
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
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
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
                            _buildChecklistItem(
                              theme,
                              'Identity Verification Baseline Approved',
                              true,
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        if (verified != null)
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
