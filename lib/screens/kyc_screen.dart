import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/kyc_service.dart';
import '../services/upload_service.dart';
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

  // Upload and UI state
  final Map<String, bool> _uploadingFields = {};
  final Set<String> _showManualUrlInputs = {};
  bool _submittedAttempt = false;

  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _formInitialized = false;

  bool _isFieldUploading(String key) => _uploadingFields[key] == true;
  bool get _isAnyUploading => _uploadingFields.values.any((v) => v == true);

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

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 25, 1, 1);
    final firstDate = DateTime(1930);
    final lastDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() {
        _dobController.text = '$y-$m-$d';
      });
    }
  }

  Future<void> _pickAndUploadImage({
    required String fieldKey,
    required TextEditingController controller,
    required ImageSource source,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _uploadingFields[fieldKey] = true;
      });

      final uploadService = ref.read(uploadServiceProvider);
      final result = await uploadService.uploadFile(
        file: pickedFile,
        folder: 'kyc',
      );

      if (mounted) {
        setState(() {
          controller.text = result.url;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Document uploaded successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to upload document image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingFields[fieldKey] = false;
        });
      }
    }
  }

  void _showImageSourcePicker({
    required String title,
    required String fieldKey,
    required TextEditingController controller,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        final isDark =
            Theme.of(bottomSheetContext).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upload Document Photo',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _pickAndUploadImage(
                            fieldKey: fieldKey,
                            controller: controller,
                            source: ImageSource.camera,
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Take Photo',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Use Camera',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _pickAndUploadImage(
                            fieldKey: fieldKey,
                            controller: controller,
                            source: ImageSource.gallery,
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: AppColors.secondary
                                .withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.photo_library_rounded,
                                  color: AppColors.secondary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Choose Gallery',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Device Photos',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImagePreviewDialog(String url, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade900,
                      alignment: Alignment.center,
                      child: const Text('Could not load image',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitKyc() async {
    setState(() => _submittedAttempt = true);

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Please fill all required form fields correctly.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isAnyUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Please wait for document images to finish uploading.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_identityFrontUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content:
              Text('Please upload the front image of your Identity Proof (POI).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_addressFrontUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content:
              Text('Please upload your Address Proof document image (POA).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
          _submittedAttempt = false;
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
                  _buildApprovedSummary(theme, kycMap, isDark)
                // If pending review and not editing, show review details with edit button
                else if (status == 'pending' && !_isEditing)
                  _buildPendingSummary(theme, kycMap, isDark)
                else if (status == 'in_review' && !_isEditing)
                  _buildInReviewSummary(theme, kycMap, isDark)
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

  Widget _buildApprovedSummary(
      ThemeData theme, Map<String, dynamic>? kycData, bool isDark) {
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
          _buildDocumentPreviewGrid(kycData, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildPendingSummary(
      ThemeData theme, Map<String, dynamic>? kycData, bool isDark) {
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
          _buildDocumentPreviewGrid(kycData, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildInReviewSummary(
      ThemeData theme, Map<String, dynamic>? kycData, bool isDark) {
    return _buildPendingSummary(theme, kycData, isDark);
  }

  Widget _buildDocumentPreviewGrid(
      Map<String, dynamic>? kycData, ThemeData theme, bool isDark) {
    if (kycData == null) return const SizedBox.shrink();

    final docs = <Map<String, String>>[];
    final idFront = (kycData['identityDocumentFrontUrl'] ??
            kycData['documentFrontUrl'])
        ?.toString();
    final idBack = (kycData['identityDocumentBackUrl'] ??
            kycData['documentBackUrl'])
        ?.toString();
    final addrFront = kycData['addressDocumentFrontUrl']?.toString();
    final addrBack = kycData['addressDocumentBackUrl']?.toString();
    final selfie = kycData['selfieUrl']?.toString();

    if (idFront != null && idFront.trim().isNotEmpty) {
      docs.add({'title': 'Identity Front', 'url': idFront.trim()});
    }
    if (idBack != null && idBack.trim().isNotEmpty) {
      docs.add({'title': 'Identity Back', 'url': idBack.trim()});
    }
    if (addrFront != null && addrFront.trim().isNotEmpty) {
      docs.add({'title': 'Address Proof', 'url': addrFront.trim()});
    }
    if (addrBack != null && addrBack.trim().isNotEmpty) {
      docs.add({'title': 'Address Back', 'url': addrBack.trim()});
    }
    if (selfie != null && selfie.trim().isNotEmpty) {
      docs.add({'title': 'Selfie Photo', 'url': selfie.trim()});
    }

    if (docs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(
          'SUBMITTED DOCUMENT ATTACHMENTS',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return InkWell(
                onTap: () =>
                    _showImagePreviewDialog(doc['url']!, doc['title']!),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(11)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                doc['url']!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      size: 24, color: Colors.grey),
                                ),
                              ),
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.zoom_in_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Text(
                          doc['title']!,
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
                  readOnly: true,
                  onTap: _pickDob,
                  decoration: InputDecoration(
                    hintText: 'YYYY-MM-DD (Tap to select)',
                    prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.date_range_rounded, size: 20),
                      onPressed: _pickDob,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Selfie / Portrait Photo
                _buildDocumentUploadCard(
                  title: 'Selfie or Portrait Photo (Optional)',
                  subtitle:
                      'Clear, front-facing face photo (no sunglasses, caps, or filters)',
                  fieldKey: 'selfie',
                  controller: _selfieUrlController,
                  isRequired: false,
                  icon: Icons.face_rounded,
                  theme: theme,
                  isDark: isDark,
                  isAvatarStyle: true,
                ),
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

                // Identity Front Document Upload Card
                _buildDocumentUploadCard(
                  title: 'Identity Document Front Side *',
                  subtitle:
                      'Upload clear photo or scan showing full name, photo, and ID number',
                  fieldKey: 'identity_front',
                  controller: _identityFrontUrlController,
                  isRequired: true,
                  icon: Icons.badge_rounded,
                  theme: theme,
                  isDark: isDark,
                ),

                // Identity Back Document Upload Card
                _buildDocumentUploadCard(
                  title: _identityDocumentType == 'pan'
                      ? 'Identity Document Back Side (Optional for PAN)'
                      : 'Identity Document Back Side (Optional)',
                  subtitle: _identityDocumentType == 'pan'
                      ? 'PAN cards are single-sided; back upload is not required.'
                      : 'Upload reverse side showing address, QR code, or validity details',
                  fieldKey: 'identity_back',
                  controller: _identityBackUrlController,
                  isRequired: false,
                  icon: Icons.flip_to_back_rounded,
                  theme: theme,
                  isDark: isDark,
                ),
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

                // Address Front Document Upload Card
                _buildDocumentUploadCard(
                  title: 'Address Proof Document (Front / Page 1) *',
                  subtitle:
                      'Upload clear bill, statement, or ID side showing complete address & name',
                  fieldKey: 'address_front',
                  controller: _addressFrontUrlController,
                  isRequired: true,
                  icon: Icons.home_work_rounded,
                  theme: theme,
                  isDark: isDark,
                ),

                // Address Back Document Upload Card
                _buildDocumentUploadCard(
                  title: 'Address Proof Document (Back / Page 2 - Optional)',
                  subtitle:
                      'Second page or reverse side if address information spans multiple pages',
                  fieldKey: 'address_back',
                  controller: _addressBackUrlController,
                  isRequired: false,
                  icon: Icons.flip_to_back_rounded,
                  theme: theme,
                  isDark: isDark,
                ),
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

  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required String fieldKey,
    required TextEditingController controller,
    required bool isRequired,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    bool isAvatarStyle = false,
  }) {
    final isUploading = _isFieldUploading(fieldKey);
    final hasUrl = controller.text.trim().isNotEmpty;
    final hasError = _submittedAttempt && isRequired && !hasUrl;
    final isManualOpen = _showManualUrlInputs.contains(fieldKey);

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? AppColors.danger
              : (hasUrl
                  ? AppColors.success.withValues(alpha: 0.45)
                  : theme.dividerColor),
          width: hasError ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: (hasUrl ? AppColors.success : AppColors.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: hasUrl ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isRequired)
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        subtitle,
                        style:
                            theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (hasUrl && !isUploading)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Ready',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Uploading State
          if (isUploading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uploading document...',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Encrypting and uploading securely to cloud',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          // Has Uploaded File
          else if (hasUrl)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image Thumbnail with tap to view
                  GestureDetector(
                    onTap: () =>
                        _showImagePreviewDialog(controller.text, title),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(isAvatarStyle ? 32 : 10),
                          child: Container(
                            width: isAvatarStyle ? 64 : 76,
                            height: 64,
                            color: Colors.black.withValues(alpha: 0.1),
                            child: Image.network(
                              controller.text,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 64,
                                height: 64,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.broken_image_rounded,
                                    size: 24),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fullscreen_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // File info & actions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.text.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // View Full Image Button
                            InkWell(
                              onTap: () => _showImagePreviewDialog(
                                  controller.text, title),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      theme.dividerColor.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_outlined, size: 13),
                                    SizedBox(width: 4),
                                    Text('View',
                                        style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Replace Button
                            InkWell(
                              onTap: () => _showImageSourcePicker(
                                title: title,
                                fieldKey: fieldKey,
                                controller: controller,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sync_rounded,
                                        size: 13, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Replace',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Remove Button
                            InkWell(
                              onTap: () {
                                setState(() {
                                  controller.clear();
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.danger.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        size: 13, color: AppColors.danger),
                                    SizedBox(width: 4),
                                    Text(
                                      'Remove',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          // Empty State - Prompt to Upload
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickAndUploadImage(
                            fieldKey: fieldKey,
                            controller: controller,
                            source: ImageSource.camera,
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickAndUploadImage(
                            fieldKey: fieldKey,
                            controller: controller,
                            source: ImageSource.gallery,
                          ),
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 16),
                          label: const Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 14, color: AppColors.danger),
                        SizedBox(width: 6),
                        Text(
                          'Please upload this document to proceed',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // Manual URL Toggle / Input
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isManualOpen) {
                        _showManualUrlInputs.remove(fieldKey);
                      } else {
                        _showManualUrlInputs.add(fieldKey);
                      }
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isManualOpen
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                      Text(
                        isManualOpen
                            ? 'Hide manual URL'
                            : 'or paste URL directly',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isManualOpen) ...[
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link_rounded, size: 16),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () =>
                                  setState(() => controller.clear()),
                            )
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
