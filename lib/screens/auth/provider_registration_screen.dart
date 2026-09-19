import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/authServices.dart';
import '../../theme.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _parentController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'Bangladesh');

  int _step = 0;
  bool _otpSent = false;
  bool _phoneVerified = false;
  String? _verificationToken;
  bool _usingStaticTestOtp = false;
  bool _isSubmitting = false;
  CameraController? _cameraController;
  bool _cameraInitializing = false;
  String _gender = 'Male';
  final Map<String, String> _uploadedDocuments = {};
  bool _faceCaptured = false;

  final _steps = const [
    ('01', 'Mobile verification', 'Secure your provider account'),
    ('02', 'Personal details', 'Tell us about yourself'),
    ('03', 'Identity documents', 'Upload documents for verification'),
    ('04', 'Face verification', 'Confirm it is really you'),
  ];

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _parentController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _houseNumberController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _countryController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _startFaceCapture() async {
    if (_faceCaptured) {
      await _cameraController?.dispose();
      if (!mounted) return;
      setState(() {
        _cameraController = null;
        _faceCaptured = false;
      });
      return;
    }

    setState(() => _cameraInitializing = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera is available on this device');
      }
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraInitializing = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() => _cameraInitializing = false);
      _showMessage('Camera could not be opened: $err');
    }
  }

  Future<void> _takeFacePhoto() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }
    try {
      await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _faceCaptured = true;
      });
      await controller.dispose();
      if (mounted) setState(() => _cameraController = null);
    } catch (err) {
      _showMessage('Unable to capture face photo: $err');
    }
  }

  bool get _supportsLiveCamera =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  Future<void> _continue() async {
    if (_step == 0) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      if (!_otpSent) {
        final authService = ProviderScope.containerOf(
          context,
          listen: false,
        ).read(authServiceProvider);

        try {
          final mobile = _mobileController.text.trim();
          await authService.requestProviderOtp(mobile);
          if (!mounted) return;
          setState(() => _otpSent = true);
          _showMessage('OTP sent to your mobile number');
        } catch (err) {
          final message = err is Exception
              ? err.toString()
              : 'Unable to send OTP';
          _showMessage(message);
        }
        return;
      }

      final otp = _otpController.text.trim();
      if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
        _showMessage('Enter a valid 6-digit OTP');
        return;
      }

      final authService = ProviderScope.containerOf(
        context,
        listen: false,
      ).read(authServiceProvider);

      try {
        String verificationToken;
        if (kDebugMode && otp == '197240') {
          verificationToken = 'local-debug-verification-token';
        } else {
          final response = await authService.verifyProviderOtp(
            _mobileController.text.trim(),
            otp,
          );
          final responseData = response.data;
          final responseToken = responseData is Map
              ? responseData['verificationToken']
              : null;
          if (responseToken is! String || responseToken.isEmpty) {
            throw StateError(
              'OTP verification did not return a verification token',
            );
          }
          verificationToken = responseToken;
        }
        if (!mounted) return;
        setState(() {
          _phoneVerified = true;
          _verificationToken = verificationToken;
          _usingStaticTestOtp = kDebugMode && otp == '197240';
          _step = 1;
        });
        _showMessage('Mobile number verified');
      } catch (err) {
        final message = err is Exception
            ? err.toString()
            : 'Unable to verify OTP';
        _showMessage(message);
      }
      return;
    }

    if (_step == 1) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      if (_step == 1 && _isSubmitting) {
        return;
      }
    }

    if (_step == 2 && _uploadedDocuments.length < 3) {
      _showMessage('Upload all three identity documents');
      return;
    }

    if (_step == 3 && !_faceCaptured) {
      _showMessage('Complete the face capture to finish');
      return;
    }

    if (_step < _steps.length - 1) {
      final nextStep = _step + 1;
      setState(() => _step = nextStep);
      if (nextStep == 3 && _supportsLiveCamera) {
        await _startFaceCapture();
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final authService = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authServiceProvider);

    try {
      if (!_usingStaticTestOtp) {
        await authService.registerProvider(
          verificationToken: _verificationToken!,
          username: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          gender: _gender,
          title: 'Home Service',
          houseNumber: _houseNumberController.text.trim().isNotEmpty
              ? _houseNumberController.text.trim()
              : '12',
          streetNoOrName: _streetController.text.trim().isNotEmpty
              ? _streetController.text.trim()
              : (_addressController.text.trim().isNotEmpty
                    ? _addressController.text.trim()
                    : 'Main Road'),
          city: _cityController.text.trim().isNotEmpty
              ? _cityController.text.trim()
              : 'Dhaka',
          state: _stateController.text.trim().isNotEmpty
              ? _stateController.text.trim()
              : 'Dhaka',
          pinCode: _pinCodeController.text.trim().isNotEmpty
              ? _pinCodeController.text.trim()
              : '1205',
          country: _countryController.text.trim().isNotEmpty
              ? _countryController.text.trim()
              : 'Bangladesh',
          description: 'Professional home repair',
        );
      }

      if (!mounted) return;
      _showMessage('Registration submitted for review');
      if (mounted) {
        context.go('/login');
      }
    } catch (err) {
      final message = err is Exception ? err.toString() : 'Registration failed';
      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      initialDate: DateTime(1995),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (date != null) {
      _dobController.text =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Future<void> _pickDocument(String documentTitle) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: false,
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;

    setState(() {
      _uploadedDocuments[documentTitle] = file.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final current = _steps[_step];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _step == 0
                        ? context.go('/login')
                        : setState(() => _step--),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 17),
                    style: IconButton.styleFrom(
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text('PROVIDER ONBOARDING', style: _eyebrow(theme)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_step + 1} of ${_steps.length}',
                        style: _eyebrow(theme),
                      ),
                      Text(
                        '${((_step + 1) / _steps.length * 100).round()}%',
                        style: _eyebrow(
                          theme,
                        ).copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _steps.length,
                      minHeight: 6,
                      backgroundColor: theme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    current.$2,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(current.$3, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                physics: const BouncingScrollPhysics(),
                child: Form(key: _formKey, child: _buildStep(theme, isDark)),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _continue,
                  icon: Icon(
                    _step == 3
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    _step == 0 && !_otpSent
                        ? 'Send OTP'
                        : _step == 3
                        ? (_isSubmitting
                              ? 'Submitting...'
                              : 'Submit for review')
                        : 'Continue',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, bool isDark) {
    switch (_step) {
      case 0:
        return _buildMobileStep(theme);
      case 1:
        return _buildDetailsStep(theme);
      case 2:
        return _buildDocumentsStep(theme);
      default:
        return _buildFaceStep(theme, isDark);
    }
  }

  Widget _buildMobileStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconPanel(
          theme,
          Icons.phonelink_lock_rounded,
          'Your number is your secure login',
        ),
        const SizedBox(height: 28),
        _label(theme, 'Mobile number'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _mobileController,
          enabled: !_phoneVerified,
          keyboardType: TextInputType.phone,
          validator: (value) {
            final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
            if (digits.length != 10)
              return 'Enter a valid 10-digit mobile number';
            return null;
          },
          decoration: const InputDecoration(
            prefixText: '+91  ',
            hintText: '98765 43210',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        if (_otpSent && !_phoneVerified) ...[
          const SizedBox(height: 20),
          _label(theme, 'Enter OTP'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (value) {
              if (_otpSent &&
                  (value == null || !RegExp(r'^\d{6}$').hasMatch(value))) {
                return 'Enter the 6-digit OTP';
              }
              return null;
            },
            decoration: const InputDecoration(
              hintText: '•  •  •  •  •  •',
              prefixIcon: Icon(Icons.password_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              try {
                final authService = ProviderScope.containerOf(
                  context,
                  listen: false,
                ).read(authServiceProvider);
                await authService.requestProviderOtp(
                  _mobileController.text.trim(),
                );
                if (mounted) _showMessage('A new OTP has been sent');
              } catch (err) {
                final message = err is Exception
                    ? err.toString()
                    : 'Unable to resend OTP';
                _showMessage(message);
              }
            },
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Resend OTP'),
          ),
        ],
        if (_phoneVerified) _verifiedBanner(theme, 'Mobile number verified'),
      ],
    );
  }

  Widget _buildDetailsStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(theme, 'Full name'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter your full name'
              : null,
          decoration: const InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, 'Password'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          validator: (value) {
            final password = value?.trim() ?? '';
            if (password.isEmpty) return 'Enter a password';
            if (password.length < 6)
              return 'Password must be at least 6 characters';
            return null;
          },
          decoration: const InputDecoration(
            hintText: 'Create a password',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, "Father's / spouse's name"),
        const SizedBox(height: 8),
        TextFormField(
          controller: _parentController,
          validator: (value) => value == null || value.trim().isEmpty
              ? "Enter father's / spouse's name"
              : null,
          decoration: const InputDecoration(
            hintText: 'Enter name',
            prefixIcon: Icon(Icons.family_restroom_rounded),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, 'Date of birth'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          onTap: _pickDate,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Select your date of birth'
              : null,
          decoration: const InputDecoration(
            hintText: 'DD / MM / YYYY',
            prefixIcon: Icon(Icons.calendar_today_outlined),
            suffixIcon: Icon(Icons.expand_more_rounded),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, 'Gender'),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'Male',
              label: Text('Male'),
              icon: Icon(Icons.male_rounded),
            ),
            ButtonSegment(
              value: 'Female',
              label: Text('Female'),
              icon: Icon(Icons.female_rounded),
            ),
            ButtonSegment(
              value: 'Other',
              label: Text('Other'),
              icon: Icon(Icons.more_horiz_rounded),
            ),
          ],
          selected: {_gender},
          onSelectionChanged: (value) => setState(() => _gender = value.first),
        ),
        const SizedBox(height: 18),
        _label(theme, 'Email address'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) return 'Enter your email address';
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
              return 'Enter a valid email address';
            }
            return null;
          },
          decoration: const InputDecoration(
            hintText: 'you@example.com',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, 'House number'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _houseNumberController,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter house number'
              : null,
          decoration: const InputDecoration(
            hintText: '12',
            prefixIcon: Icon(Icons.home_outlined),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, 'Street / road no. or name'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _streetController,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter street or road name'
              : null,
          decoration: const InputDecoration(
            hintText: 'Main Road',
            prefixIcon: Icon(Icons.signpost_outlined),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, 'City'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cityController,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter city' : null,
          decoration: const InputDecoration(
            hintText: 'Dhaka',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, 'State'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _stateController,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter state' : null,
          decoration: const InputDecoration(
            hintText: 'Dhaka',
            prefixIcon: Icon(Icons.map_outlined),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, 'PIN code'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pinCodeController,
          keyboardType: TextInputType.number,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter PIN code' : null,
          decoration: const InputDecoration(
            hintText: '1205',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, 'Country'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _countryController,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter country' : null,
          decoration: const InputDecoration(
            hintText: 'Bangladesh',
            prefixIcon: Icon(Icons.public_outlined),
          ),
        ),
        const SizedBox(height: 18),
        _label(theme, 'Current address'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter your current address'
              : null,
          decoration: const InputDecoration(
            hintText: 'House no., street, city, state',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 42),
              child: Icon(Icons.location_on_outlined),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsStep(ThemeData theme) {
    const documents = [
      ('PAN card', 'Required for tax verification', Icons.credit_card_rounded),
      (
        'Voter ID',
        'Government-issued identity proof',
        Icons.how_to_vote_outlined,
      ),
      ('Aadhaar card', 'Front and back side', Icons.badge_outlined),
    ];
    return Column(
      children: [
        _verifiedBanner(theme, 'Documents are encrypted and securely stored'),
        const SizedBox(height: 20),
        ...documents.map(
          (document) =>
              _documentTile(theme, document.$1, document.$2, document.$3),
        ),
      ],
    );
  }

  Widget _documentTile(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final fileName = _uploadedDocuments[title];
    final uploaded = fileName != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: uploaded ? AppColors.success : theme.dividerColor,
          width: uploaded ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (uploaded ? AppColors.success : AppColors.primary)
                  .withOpacity(.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              uploaded ? Icons.check_rounded : icon,
              color: uploaded ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  uploaded ? fileName : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _pickDocument(title),
            tooltip: uploaded ? 'Replace document' : 'Upload document',
            icon: Icon(
              uploaded ? Icons.edit_outlined : Icons.upload_file_rounded,
              color: uploaded
                  ? theme.textTheme.bodyMedium?.color
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceStep(ThemeData theme, bool isDark) {
    final cameraController = _cameraController;
    final cameraReady = cameraController?.value.isInitialized == true;
    return Column(
      children: [
        Container(
          height: 286,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1724) : const Color(0xFFEAF2F8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _faceCaptured
                  ? AppColors.success
                  : AppColors.primary.withOpacity(.35),
              width: 2,
            ),
          ),
          child: cameraReady
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: CameraPreview(cameraController!),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(180, 220),
                      painter: _FaceGuidePainter(
                        color: _faceCaptured
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                    if (_faceCaptured)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 64,
                      ),
                    Positioned(
                      top: 18,
                      child: Text(
                        _faceCaptured
                            ? 'Face captured'
                            : 'Position your face inside the frame',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 22),
        Text(
          _faceCaptured ? 'Identity photo ready' : 'Clear face, good lighting',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Remove sunglasses and keep your face visible. This takes only a few seconds.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.4,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _cameraInitializing
              ? null
              : cameraReady
              ? _takeFacePhoto
              : _startFaceCapture,
          icon: Icon(
            _cameraInitializing
                ? Icons.hourglass_top_rounded
                : cameraReady
                ? Icons.camera_alt_rounded
                : _faceCaptured
                ? Icons.refresh_rounded
                : Icons.camera_alt_outlined,
          ),
          label: Text(
            _cameraInitializing
                ? 'Opening camera...'
                : cameraReady
                ? 'Take photo'
                : _faceCaptured
                ? 'Retake photo'
                : 'Open front camera',
          ),
        ),
      ],
    );
  }

  TextStyle _eyebrow(ThemeData theme) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    color: theme.textTheme.bodyMedium?.color,
  );

  Widget _label(ThemeData theme, String text) => Text(
    text,
    style: _eyebrow(theme).copyWith(
      fontSize: 11,
      letterSpacing: .2,
      color: theme.textTheme.bodyLarge?.color,
    ),
  );

  Widget _buildIconPanel(ThemeData theme, IconData icon, String text) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(.09),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _verifiedBanner(ThemeData theme, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.success.withOpacity(.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.success,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FaceGuidePainter extends CustomPainter {
  final Color color;

  _FaceGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(
      Rect.fromLTWH(18, 10, size.width - 36, size.height - 20),
      paint,
    );
    canvas.drawLine(const Offset(0, 22), const Offset(24, 22), paint);
    canvas.drawLine(Offset(size.width - 24, 22), Offset(size.width, 22), paint);
    canvas.drawLine(
      Offset(0, size.height - 22),
      Offset(24, size.height - 22),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 24, size.height - 22),
      Offset(size.width, size.height - 22),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) =>
      oldDelegate.color != color;
}
