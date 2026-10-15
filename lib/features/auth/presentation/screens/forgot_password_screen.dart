import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/soma_smart_logo.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

/// Official SomaSmart Forgot Password Screen.
/// Supports Phone OTP Reset (Primary), Email Reset (Secondary), and Contact Support fallback.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _resetPasswordFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  // Reset Modes: 0 = Phone (SMS OTP), 1 = Email
  int _resetMode = 0;
  // Phone flow step: 0 = enter phone, 1 = enter OTP + new password
  int _phoneStep = 0;

  bool _obscurePassword = true;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendPhoneOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final lang = ref.read(languageProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);

    final rawPhone = _phoneController.text.trim();
    final normalizedPhone = AuthController.normalizePhoneNumber(rawPhone);

    final success = await authNotifier.sendPhonePasswordResetOtp(
      phone: normalizedPhone,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _phoneStep = 1;
          _successMessage = lang == 'sw'
              ? 'Nambari ya OTP imetumwa kwa SMS kwa $normalizedPhone.'
              : 'Password reset OTP has been sent via SMS to $normalizedPhone.';
        });
      } else {
        final authState = ref.read(authControllerProvider);
        final error = authState.error;
        setState(() {
          _errorMessage = AuthController.getLocalizedErrorMessage(error, lang);
        });
      }
    }
  }

  Future<void> _handleVerifyPhoneOtpAndReset() async {
    if (!_resetPasswordFormKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final lang = ref.read(languageProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);

    final rawPhone = _phoneController.text.trim();
    final normalizedPhone = AuthController.normalizePhoneNumber(rawPhone);

    final success = await authNotifier.verifyResetOtpAndSetPassword(
      phone: normalizedPhone,
      otpToken: _otpController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _isSuccess = true;
          _successMessage = lang == 'sw'
              ? 'Nenosiri lako limewekwa upya kikamilifu! Sasa unaweza kuingia.'
              : 'Password reset successfully! You can now sign in with your new password.';
        });
      } else {
        final authState = ref.read(authControllerProvider);
        final error = authState.error;
        setState(() {
          _errorMessage = AuthController.getLocalizedErrorMessage(error, lang);
        });
      }
    }
  }

  Future<void> _handleSendEmailReset() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _isSuccess = false;
      _successMessage = null;
    });

    final lang = ref.read(languageProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);

    final success = await authNotifier.resetPasswordForEmail(
      email: _emailController.text.trim(),
    );

    if (mounted) {
      if (success) {
        setState(() {
          _isSuccess = true;
          _successMessage = lang == 'sw'
              ? 'Maelekezo ya kuweka upya nenosiri yametumwa kwenye barua pepe yako.'
              : 'Password reset instructions have been sent to your email.';
        });
      } else {
        final authState = ref.read(authControllerProvider);
        final error = authState.error;
        setState(() {
          _errorMessage = AuthController.getLocalizedErrorMessage(error, lang);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final isSw = lang == 'sw';
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgBase : AppColors.lightBgSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          onPressed: () {
            if (_phoneStep == 1 && !_isSuccess) {
              setState(() {
                _phoneStep = 0;
                _errorMessage = null;
              });
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Official S Logo & Live Wordmark
                const SomaSmartLogo(
                  size: 44,
                  fontSize: 22,
                ),

                const SizedBox(height: 20),

                // 2. Heading
                Text(
                  isSw ? 'Umesahau Nenosiri?' : 'Reset Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  isSw
                      ? 'Rejesha akaunti yako kwa urahisi kwa kutumia simu au barua pepe.'
                      : 'Recover your account easily using your phone number or email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Mode Toggle (Phone SMS OTP vs Email)
                if (!_isSuccess && _phoneStep == 0) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBgContainer
                          : AppColors.lightBgContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorderSubtle
                            : AppColors.lightBorderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _resetMode = 0;
                                _errorMessage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _resetMode == 0
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sms_outlined,
                                    size: 16,
                                    color: _resetMode == 0
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isSw ? 'Simu (SMS)' : 'Phone (SMS)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _resetMode == 0
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _resetMode = 1;
                                _errorMessage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _resetMode == 1
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: _resetMode == 1
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isSw ? 'Barua Pepe' : 'Email',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _resetMode == 1
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. Success Banner
                if (_successMessage != null || _isSuccess) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage ??
                                (isSw
                                    ? 'Ujumbe umetumwa kikamilifu.'
                                    : 'Operation completed successfully.'),
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 5. Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 6. Primary Flow: Phone Mode Step 0 (Input Phone)
                if (!_isSuccess && _resetMode == 0 && _phoneStep == 0) ...[
                  Form(
                    key: _phoneFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSw ? 'Nambari ya Simu' : 'Phone Number',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSendPhoneOtp(),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: isSw
                                ? 'Weka nambari yako ya simu'
                                : 'Enter your phone number',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.phone_iphone_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkBgContainer
                                : AppColors.lightBgContainer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorderSubtle
                                    : AppColors.lightBorderSubtle,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isSw
                                  ? 'Tafadhali weka nambari yako ya simu.'
                                  : 'Please enter your phone number.';
                            }
                            final cleaned = val.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                            if (cleaned.length < 9) {
                              return isSw
                                  ? 'Nambari ya simu si sahihi.'
                                  : 'Please enter a valid phone number.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: isSw ? 'Tuma Nambari ya OTP' : 'Send Reset OTP',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _handleSendPhoneOtp,
                        ),
                      ],
                    ),
                  ),
                ],

                // 7. Phone Mode Step 1 (Input OTP + New Password)
                if (!_isSuccess && _resetMode == 0 && _phoneStep == 1) ...[
                  Form(
                    key: _resetPasswordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSw ? 'Nambari ya OTP ya SMS' : 'SMS OTP Code',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(
                            fontSize: 18,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: isSw
                                ? 'Weka nambari ya OTP'
                                : 'Enter 6-digit OTP',
                            hintStyle: TextStyle(
                              letterSpacing: 1,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.pin_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkBgContainer
                                : AppColors.lightBgContainer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorderSubtle
                                    : AppColors.lightBorderSubtle,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isSw
                                  ? 'Tafadhali weka nambari ya OTP.'
                                  : 'Please enter the OTP code.';
                            }
                            if (val.trim().length != 6) {
                              return isSw
                                  ? 'OTP lazima iwe ya tarakimu 6.'
                                  : 'OTP must be 6 digits.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isSw ? 'Nenosiri Jipya' : 'New Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleVerifyPhoneOtpAndReset(),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: isSw
                                ? 'Weka nenosiri jipya'
                                : 'Enter new password',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkBgContainer
                                : AppColors.lightBgContainer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorderSubtle
                                    : AppColors.lightBorderSubtle,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isSw
                                  ? 'Tafadhali weka nenosiri jipya.'
                                  : 'Please enter a new password.';
                            }
                            if (val.length < 6) {
                              return isSw
                                  ? 'Nenosiri lazima liwe na angalau herufi 6.'
                                  : 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: isSw
                              ? 'Weka Nenosiri Jipya'
                              : 'Set New Password',
                          isLoading: isLoading,
                          onPressed:
                              isLoading ? null : _handleVerifyPhoneOtpAndReset,
                        ),
                      ],
                    ),
                  ),
                ],

                // 8. Secondary Flow: Email Reset Mode
                if (!_isSuccess && _resetMode == 1) ...[
                  Form(
                    key: _emailFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSw ? 'Barua Pepe' : 'Email Address',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSendEmailReset(),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: isSw
                                ? 'Weka barua pepe yako'
                                : 'Enter your email',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkBgContainer
                                : AppColors.lightBgContainer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorderSubtle
                                    : AppColors.lightBorderSubtle,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isSw
                                  ? 'Tafadhali weka barua pepe yako.'
                                  : 'Please enter your email.';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return isSw
                                  ? 'Muundo wa barua pepe si sahihi.'
                                  : 'Please enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: isSw ? 'Tuma Kiungo cha Barua Pepe' : 'Send Email Reset Link',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _handleSendEmailReset,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 9. Lost Phone / No Email Fallback: Contact Support
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBgContainer.withValues(alpha: 0.5)
                        : AppColors.lightBgContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorderSubtle
                          : AppColors.lightBorderSubtle,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isSw
                                  ? 'Umepoteza simu au huna barua pepe?'
                                  : 'Lost your phone or have no email?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSw
                            ? 'Wasiliana na dawati letu la usaidizi ili kurejesha akaunti yako kibinafsi.'
                            : 'Contact our support desk for manual account verification and recovery.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/contact-support'),
                          icon: const Icon(Icons.headset_mic_rounded, size: 16),
                          label: Text(
                            isSw ? 'Wasiliana na Msaada' : 'Contact Support',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 10. Back to Login
                TextButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    isSw ? 'Rudi Kwenye Kuingia' : 'Back to Sign In',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
