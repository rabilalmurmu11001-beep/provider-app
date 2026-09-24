import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/kyc_service.dart';
import '../stores/kyc_providers.dart';
import '../stores/providers.dart';
import '../theme.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Identity Proof (POI)
  String _identityDocumentType = 'aadhaar';
  final _identityNumberController = TextEditingController();
  final _identityFrontUrlController = TextEditingController();
  final _identityBackUrlController = TextEditingController();

  // 2. Address Proof (POA)
  String _addressDocumentType = 'aadhaar';
  final _addressNumberController = TextEditingController();
  final _addressFrontUrlController = TextEditingController();
  final _addressBackUrlController = TextEditingController();

  // Personal Info
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _selfieUrlController = TextEditingController();

  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _formInitialized = false;

  final List<Map<String, dynamic>> _identityDocumentTypes = [
    {
      'id': 'aadhaar',
      'label': 'Aadhaar Card',
      'icon': Icons.credit_card_rounded,
      'hint': '12-digit UIDAI Number',
    },
    {
      'id': 'pan',
      'label': 'PAN Card',
      'icon': Icons.badge_rounded,
      'hint': '10-character alphanumeric PAN',
    },
    {
      'id': 'driving_license',
      'label': 'Driving License',
      'icon': Icons.drive_eta_rounded,
      'hint': 'State Driving License Number',
    },
    {
      'id': 'passport',
      'label': 'Passport',
      'icon': Icons.flight_takeoff_rounded,
      'hint': 'Passport Booklet Number',
    },
    {
      'id': 'voter_id',
      'label': 'Voter ID (EPIC)',
      'icon': Icons.how_to_vote_rounded,
      'hint': 'Election Commission EPIC Number',
    },
  ];

  final List<Map<String, dynamic>> _addressDocumentTypes = [
    {
      'id': 'aadhaar',
      'label': 'Aadhaar Card (Address Side)',
      'icon': Icons.credit_card_rounded,
      'hint': '12-digit UIDAI Number',
    },
    {
      'id': 'utility_bill',
      'label': 'Utility Bill (Electricity, Water, Gas)',
      'icon': Icons.receipt_long_rounded,
      'hint': 'Consumer / CA Account Number',
    },
    {
      'id': 'rent_agreement',
      'label': 'Rent Agreement',
      'icon': Icons.home_work_rounded,
      'hint': 'Agreement Ref / Reg No (optional)',
    },
    {
      'id': 'bank_statement',
      'label': 'Bank Statement / Passbook',
      'icon': Icons.account_balance_rounded,
      'hint': 'Account / Ref Number (optional)',
    },
    {
      'id': 'driving_license',
      'label': 'Driving License',
      'icon': Icons.drive_eta_rounded,
      'hint': 'State Driving License Number',
    },
    {
      'id': 'passport',
      'label': 'Passport',
      'icon': Icons.flight_takeoff_rounded,
      'hint': 'Passport Booklet Number',
    },
    {
      'id': 'voter_id',
      'label': 'Voter ID (EPIC)',
      'icon': Icons.how_to_vote_rounded,
      'hint': 'Election Commission EPIC Number',
    },
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _identityNumberController.dispose();
    _identityFrontUrlController.dispose();
    _identityBackUrlController.dispose();
    _addressNumberController.dispose();
    _addressFrontUrlController.dispose();
    _addressBackUrlController.dispose();
    _dobController.dispose();
    _selfieUrlController.dispose();
    super.dispose();
  }

  void _populateForm(Map<String, dynamic>? kycData) {
    if (_formInitialized || kycData == null) return;
    _formInitialized = true;

    // Identity Document
    final idType = kycData['identityDocumentType']?.toString() ??
        kycData['documentType']?.toString() ??
        'aadhaar';
    if (_identityDocumentTypes.any((d) => d['id'] == idType)) {
      _identityDocumentType = idType;
    }
    _identityNumberController.text =
        kycData['identityDocumentNumber']?.toString() ??
            kycData['documentNumber']?.toString() ??
            '';
    _identityFrontUrlController.text =
        kycData['identityDocumentFrontUrl']?.toString() ??
            kycData['documentFrontUrl']?.toString() ??
            '';
    _identityBackUrlController.text =
        kycData['identityDocumentBackUrl']?.toString() ??
            kycData['documentBackUrl']?.toString() ??
            '';

    // Address Document
    final addrType = kycData['addressDocumentType']?.toString() ?? 'aadhaar';
    if (_addressDocumentTypes.any((d) => d['id'] == addrType)) {
      _addressDocumentType = addrType;
    }
    _addressNumberController.text =
        kycData['addressDocumentNumber']?.toString() ?? '';
    _addressFrontUrlController.text =
        kycData['addressDocumentFrontUrl']?.toString() ?? '';
    _addressBackUrlController.text =
        kycData['addressDocumentBackUrl']?.toString() ?? '';

    // Personal Details
    _fullNameController.text = kycData['fullName']?.toString() ?? '';
    _dobController.text = kycData['dob']?.toString() ?? '';
    _selfieUrlController.text = kycData['selfieUrl']?.toString() ?? '';
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final kycService = ref.read(kycServiceProvider);
      final response = await kycService.submitKyc(
        identityDocumentType: _identityDocumentType,
        identityDocumentNumber: _identityNumberController.text,
        identityDocumentFrontUrl: _identityFrontUrlController.text,
        identityDocumentBackUrl: _identityBackUrlController.text.isNotEmpty
            ? _identityBackUrlController.text
            : null,
        addressDocumentType: _addressDocumentType,
        addressDocumentNumber: _addressNumberController.text.isNotEmpty
            ? _addressNumberController.text
            : null,
        addressDocumentFrontUrl: _addressFrontUrlController.text,
        addressDocumentBackUrl: _addressBackUrlController.text.isNotEmpty
            ? _addressBackUrlController.text
            : null,
        selfieUrl: _selfieUrlController.text.isNotEmpty
            ? _selfieUrlController.text
            : null,
        fullName: _fullNameController.text,
        dob: _dobController.text.isNotEmpty ? _dobController.text : null,
      );

      ref.invalidate(kycStatusAsyncProvider);
      ref.invalidate(kycDetailsAsyncProvider);
      ref.invalidate(providerProfileAsyncProvider);

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    response['message']?.toString() ??
                        'KYC documents submitted successfully!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        String errorMsg = 'Failed to submit KYC. Please try again.';
        if (err is Exception) {
          try {
            final dynamic data = (err as dynamic).response?.data;
            if (data is Map && data['message'] != null) {
              errorMsg = data['message'].toString();
            }
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(errorMsg),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final kycAsync = ref.watch(kycDetailsAsyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'KYC Verification',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Status',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(kycStatusAsyncProvider);
              ref.invalidate(kycDetailsAsyncProvider);
            },
          ),
        ],
      ),
      body: kycAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.danger,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load KYC information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(kycDetailsAsyncProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final isVerified = data['isVerified'] == true;
          final status = (data['kycStatus']?.toString() ??
                  data['status']?.toString() ??
                  'not_submitted')
              .toLowerCase();
          final kycMap = data['kyc'] as Map<String, dynamic>?;

          // Auto-populate form if not already edited
          if (!_formInitialized && kycMap != null) {
            _populateForm(kycMap);
          }

          final showForm = status == 'not_submitted' ||
              status == 'rejected' ||
              _isEditing;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Header Card
                _buildStatusCard(
                  theme: theme,
                  isDark: isDark,
                  status: status,
                  isVerified: isVerified,
                  kycData: kycMap,
                ),

                const SizedBox(height: 24),

                // If approved and not editing, show verification summary
                if (isVerified && !_isEditing)
                  _buildApprovedSummary(theme, kycMap)
                // If pending review and not editing, show review details with edit button
                else if (status == 'pending' && !_isEditing)
                  _buildPendingSummary(theme, kycMap)
                else if (status == 'in_review' && !_isEditing)
                  _buildInReviewSummary(theme, kycMap)
                // Otherwise show the submission / edit form
                else if (showForm)
                  _buildKycForm(theme, isDark, status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard({
    required ThemeData theme,
    required bool isDark,
    required String status,
    required bool isVerified,
    Map<String, dynamic>? kycData,
  }) {
    Color cardColor;
    Color borderColor;
    Color accentColor;
    IconData statusIcon;
    String statusTitle;
    String statusDesc;

    if (isVerified || status == 'approved') {
      cardColor = AppColors.success.withValues(alpha: isDark ? 0.15 : 0.08);
      borderColor = AppColors.success.withValues(alpha: 0.35);
      accentColor = AppColors.success;
      statusIcon = Icons.verified_user_rounded;
      statusTitle = 'Identity & Address Verified ✅';
      statusDesc =
          'Your KYC documentation is fully verified. You can go online, receive client requests, and accept bookings.';
    } else if (status == 'pending') {
      cardColor = AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.08);
      borderColor = AppColors.warning.withValues(alpha: 0.35);
      accentColor = AppColors.warning;
      statusIcon = Icons.hourglass_top_rounded;
      statusTitle = 'Verification Under Review ⏳';
      statusDesc =
          'Your identity and address proof documents have been received and are queued for verification. Approval is typically completed within 24-48 hours.';
    } else if (status == 'in_review') {
      cardColor = AppColors.secondary.withValues(alpha: isDark ? 0.15 : 0.08);
      borderColor = AppColors.secondary.withValues(alpha: 0.35);
      accentColor = AppColors.secondary;
      statusIcon = Icons.fact_check_rounded;
      statusTitle = 'Active Review in Progress 🔍';
      statusDesc =
          'Our compliance team is actively evaluating your documents. You will receive an immediate notification once approved.';
    } else if (status == 'rejected') {
      cardColor = AppColors.danger.withValues(alpha: isDark ? 0.15 : 0.08);
      borderColor = AppColors.danger.withValues(alpha: 0.35);
      accentColor = AppColors.danger;
      statusIcon = Icons.gpp_bad_rounded;
      statusTitle = 'Verification Action Required ⚠️';
      final reason = kycData?['rejectionReason']?.toString() ??
          'Document illegible or details did not match.';
      statusDesc = 'Your previous submission was not approved: "$reason"';
    } else {
      cardColor = AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08);
      borderColor = AppColors.primary.withValues(alpha: 0.35);
      accentColor = AppColors.primary;
      statusIcon = Icons.security_rounded;
      statusTitle = 'KYC Verification Needed 🪪';
      statusDesc =
          'Submit two government-recognized documents (Identity Proof + Address Proof) to unlock online availability and accept customer bookings.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'STATUS: ${status.replaceAll('_', ' ').toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            statusDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedSummary(ThemeData theme, Map<String, dynamic>? kycData) {
    final idDocType = (kycData?['identityDocumentType'] ?? kycData?['documentType'])
            ?.toString()
            .replaceAll('_', ' ')
            .toUpperCase() ??
        'ID CARD';
    final idDocNum = (kycData?['identityDocumentNumber'] ?? kycData?['documentNumber'])
            ?.toString() ??
        '••••••••';

    final addrDocType = kycData?['addressDocumentType']
            ?.toString()
            .replaceAll('_', ' ')
            .toUpperCase() ??
        'ADDRESS PROOF';
    final addrDocNum = kycData?['addressDocumentNumber']?.toString();

    final name = kycData?['fullName']?.toString() ?? 'Verified Provider';
    final verifiedAt = kycData?['reviewedAt']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
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
                'VERIFIED CREDENTIALS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: theme.hintColor,
                ),
              ),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Legal Name', name),
          const Divider(height: 20),
          _buildInfoRow('Identity Proof (POI)', idDocType),
          const SizedBox(height: 4),
          _buildInfoRow('ID Number', idDocNum),
          const Divider(height: 20),
          _buildInfoRow('Address Proof (POA)', addrDocType),
          if (addrDocNum != null && addrDocNum.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildInfoRow('Address Ref ID', addrDocNum),
          ],
          if (verifiedAt.isNotEmpty) ...[
            const Divider(height: 20),
            _buildInfoRow('Verified On', verifiedAt.split('T').first),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingSummary(ThemeData theme, Map<String, dynamic>? kycData) {
    final idDocType = (kycData?['identityDocumentType'] ?? kycData?['documentType'])
            ?.toString()
            .replaceAll('_', ' ')
            .toUpperCase() ??
        'ID CARD';
    final idDocNum = (kycData?['identityDocumentNumber'] ?? kycData?['documentNumber'])
            ?.toString() ??
        '••••••••';

    final addrDocType = kycData?['addressDocumentType']
            ?.toString()
            .replaceAll('_', ' ')
            .toUpperCase() ??
        'ADDRESS PROOF';
    final addrDocNum = kycData?['addressDocumentNumber']?.toString();

    final name = kycData?['fullName']?.toString() ?? 'Provider';

    return Container(
      padding: const EdgeInsets.all(18),
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
                'SUBMISSION DETAILS (QUEUED)',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: theme.hintColor,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _isEditing = true);
                },
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('Edit / Replace', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Legal Name', name),
          const Divider(height: 20),
          _buildInfoRow('Identity Proof (POI)', idDocType),
          const SizedBox(height: 4),
          _buildInfoRow('ID Number', idDocNum),
          const Divider(height: 20),
          _buildInfoRow('Address Proof (POA)', addrDocType),
          if (addrDocNum != null && addrDocNum.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildInfoRow('Address Ref ID', addrDocNum),
          ],
        ],
      ),
    );
  }

  Widget _buildInReviewSummary(ThemeData theme, Map<String, dynamic>? kycData) {
    return _buildPendingSummary(theme, kycData);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKycForm(ThemeData theme, bool isDark, String status) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status == 'rejected'
                ? 'CORRECT & RESUBMIT DOCUMENTS'
                : (_isEditing ? 'UPDATE KYC DOCUMENTS' : 'DOCUMENT SUBMISSION'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // SECTION 1: Personal Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  theme: theme,
                  title: 'Personal Information',
                  subtitle: 'Basic details as appearing on your official IDs',
                  icon: Icons.person_rounded,
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: 16),

                // Full Name
                Text(
                  'Full Legal Name (as on documents) *',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Ramesh Kumar Sharma',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your legal name as on document';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Date of Birth
                Text(
                  'Date of Birth (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    hintText: 'YYYY-MM-DD or DD/MM/YYYY',
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                ),

                const SizedBox(height: 16),

                // Selfie / Portrait Photo URL
                Text(
                  'Selfie or Portrait Photo URL (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _selfieUrlController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'https://storage.../selfie.jpg',
                    prefixIcon: Icon(Icons.camera_alt_outlined, size: 18),
                  ),
                ),
                if (_selfieUrlController.text.startsWith('http'))
                  _buildUrlPreview(_selfieUrlController.text, 'Selfie Preview'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SECTION 2: 1. Identity Proof (POI)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  theme: theme,
                  title: '1. Identity Proof (POI) *',
                  subtitle:
                      'Government photo ID (Aadhaar, PAN, DL, Passport, Voter ID)',
                  icon: Icons.badge_rounded,
                  iconColor: AppColors.secondary,
                ),
                const SizedBox(height: 16),

                // Identity Document Type Selector
                Text(
                  'Identity Document Type *',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _identityDocumentType,
                      isExpanded: true,
                      dropdownColor: theme.cardColor,
                      items: _identityDocumentTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['id'] as String,
                          child: Row(
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                type['label'] as String,
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _identityDocumentType = val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Identity Document Number
                Text(
                  'Identity Document Number *',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _identityNumberController,
                  decoration: InputDecoration(
                    hintText: _identityDocumentTypes
                        .firstWhere(
                            (d) => d['id'] == _identityDocumentType)['hint']
                        .toString(),
                    prefixIcon: const Icon(Icons.numbers_rounded, size: 18),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 4) {
                      return 'Please enter a valid document ID number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Identity Front Document URL
                Text(
                  'Identity Document Front Image URL *',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _identityFrontUrlController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'https://storage.../identity_front.jpg',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 8) {
                      return 'Please provide a valid document front image URL';
                    }
                    return null;
                  },
                ),
                if (_identityFrontUrlController.text.startsWith('http'))
                  _buildUrlPreview(
                      _identityFrontUrlController.text, 'Identity Front Preview'),

                const SizedBox(height: 16),

                // Identity Back Document URL
                Text(
                  'Identity Document Back Image URL (Optional for PAN)',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _identityBackUrlController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'https://storage.../identity_back.jpg',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                  ),
                ),
                if (_identityBackUrlController.text.startsWith('http'))
                  _buildUrlPreview(
                      _identityBackUrlController.text, 'Identity Back Preview'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SECTION 3: 2. Address Proof (POA)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  theme: theme,
                  title: '2. Address Proof (POA) *',
                  subtitle:
                      'Aadhaar back, Utility Bill, Rent Agreement, Bank Passbook, etc.',
                  icon: Icons.home_rounded,
                  iconColor: AppColors.success,
                ),
                const SizedBox(height: 16),

                // Address Document Type Selector
                Text(
                  'Address Document Type *',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _addressDocumentType,
                      isExpanded: true,
                      dropdownColor: theme.cardColor,
                      items: _addressDocumentTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['id'] as String,
                          child: Row(
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                size: 18,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  type['label'] as String,
                                  style: GoogleFonts.inter(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _addressDocumentType = val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Address Document Number / Account ID
                Text(
                  'Address Document / Consumer / Ref Number (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressNumberController,
                  decoration: InputDecoration(
                    hintText: _addressDocumentTypes
                        .firstWhere(
                            (d) => d['id'] == _addressDocumentType)['hint']
                        .toString(),
                    prefixIcon: const Icon(Icons.pin_outlined, size: 18),
                  ),
                ),

                const SizedBox(height: 16),

                // Address Front Document URL
                Text(
                  'Address Document Image URL *',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressFrontUrlController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'https://storage.../address_document.jpg',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 8) {
                      return 'Please provide a valid address document image URL';
                    }
                    return null;
                  },
                ),
                if (_addressFrontUrlController.text.startsWith('http'))
                  _buildUrlPreview(
                      _addressFrontUrlController.text, 'Address Proof Preview'),

                const SizedBox(height: 16),

                // Address Back Document URL
                Text(
                  'Address Document Back Image URL (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressBackUrlController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'https://storage.../address_back.jpg',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                  ),
                ),
                if (_addressBackUrlController.text.startsWith('http'))
                  _buildUrlPreview(
                      _addressBackUrlController.text, 'Address Back Preview'),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitKyc,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          status == 'rejected'
                              ? 'Resubmit KYC for Review'
                              : (_isEditing
                                  ? 'Update Submission'
                                  : 'Submit KYC for Verification'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (_isEditing) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Cancel Edit'),
              ),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildUrlPreview(String url, String label) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image_rounded, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
