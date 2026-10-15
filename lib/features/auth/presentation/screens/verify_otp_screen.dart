import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/soma_smart_logo.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Reusable 6-digit OTP Verification Screen — DISABLED.
///
/// Not reachable: there is no `/verify-otp` route. Codes used to be generated and accepted
/// on the device (including a master code), which verified nothing. Without an injected
/// [customVerifier] / [onResend] the screen refuses every code. Wire both to a server-side
/// SMS OTP before adding a route back.
///
/// Features:
/// - Masked phone display (e.g. "+255 7XX XXX 123") with "Edit" navigation link
/// - 6 individual auto-advancing digit input boxes with paste support & auto-submit
/// - Real-time 60s countdown timer ("Resend code in 00:45")
/// - 3-attempt resend limit with 10-minute lockout warning
/// - "Verify" button disabled until 6 digits entered with loading state
/// - Inline error reporting with automatic input clearance and refocusing
/// - Native Autofill & numeric keypad support
class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String? phone;
  final void Function(String otpCode)? onVerified;

  /// Server-side check of the entered code. Required: without it no code is accepted.
  final Future<bool> Function(String otpCode)? customVerifier;

  /// Asks the server to send a new code. Without it resending is unavailable.
  final Future<bool> Function(String phone)? onResend;
  final VoidCallback? onEditPhone;

  const VerifyOtpScreen({
    super.key,
    this.phone,
    this.onVerified,
    this.customVerifier,
    this.onResend,
    this.onEditPhone,
  });

  /// Formats raw or E.164 phone into a masked format (e.g. "+255 7XX XXX 123").
  static String maskPhoneNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.length < 8) return phone;

    if (clean.startsWith('+255') && clean.length >= 12) {
      final code = clean.substring(0, 4); // +255
      final rest = clean.substring(4);    // 7XXXXXXXX
      final first = rest.isNotEmpty ? rest[0] : '';
      final lastThree = rest.length >= 3 ? rest.substring(rest.length - 3) : rest;
      return '$code $first' 'XX XXX $lastThree';
    } else if (clean.startsWith('0') && clean.length >= 10) {
      final firstTwo = clean.substring(0, 2); // 07
      final lastThree = clean.substring(clean.length - 3);
      return '${firstTwo}XX XXX $lastThree';
    }

    final start = clean.length > 5 ? clean.substring(0, clean.startsWith('+') ? 5 : 3) : clean.substring(0, 2);
    final end = clean.substring(clean.length - 3);
    return '$start XX XXX $end';
  }

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const int _otpLength = 6;
  static const int _maxResendAttempts = 3;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  Timer? _timer;
  int _secondsRemaining = 60;
  int _resendAttempts = 0;
  String? _errorMessage;
  bool _isVerifying = false;

  String get _effectivePhone => widget.phone ?? '';
  bool get _isResendExhausted => _resendAttempts >= _maxResendAttempts;

  String get _currentOtpCode =>
      _controllers.map((c) => c.text.trim()).join();

  bool get _isComplete => _currentOtpCode.length == _otpLength;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldownTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _unavailableMessage(bool isSw) => isSw
      ? 'Uthibitisho wa simu haupatikani bado.'
      : 'Phone verification is not available yet.';

  String _formatTimerDisplay(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleDigitChanged(int index, String value) {
    setState(() {
      _errorMessage = null;
    });

    // Handle clipboard/SMS autofill pasting whole 6 digits into any box
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (var i = 0; i < _otpLength; i++) {
          if (i < digits.length) {
            _controllers[i].text = digits[i];
          }
        }
        final targetIndex = (digits.length - 1).clamp(0, _otpLength - 1);
        _focusNodes[targetIndex].requestFocus();

        if (digits.length >= _otpLength) {
          _handleVerify();
        }
        return;
      }
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }

      // Check auto-submit
      if (_isComplete) {
        _handleVerify();
      }
    }
  }

  void _handleKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  void _clearAndRefocus() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
    setState(() {});
  }

  Future<void> _handleVerify() async {
    final code = _currentOtpCode;
    final lang = ref.read(languageProvider);
    final isSw = lang == 'sw';

    if (code.length != _otpLength) return;

    setState(() {
      _errorMessage = null;
      _isVerifying = true;
    });

    if (widget.customVerifier == null) {
      // No server-side OTP yet: never accept a code.
      setState(() {
        _isVerifying = false;
        _errorMessage = _unavailableMessage(isSw);
      });
      _clearAndRefocus();
      return;
    }

    final success = await widget.customVerifier!(code);

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });

      if (success) {
        if (widget.onVerified != null) {
          widget.onVerified!(code);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isSw
                    ? 'Akaunti yako imethibitishwa kikamilifu! Karibu SomaSmart.'
                    : 'Account verified successfully! Welcome to SomaSmart.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/home');
        }
      } else {
        setState(() {
          _errorMessage = isSw
              ? 'Nambari ya OTP si sahihi, tafadhali jaribu tena'
              : 'Incorrect code, please try again';
        });
        _clearAndRefocus();
      }
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResendExhausted) return;

    final lang = ref.read(languageProvider);
    final isSw = lang == 'sw';

    setState(() {
      _errorMessage = null;
    });

    if (widget.onResend == null) {
      setState(() => _errorMessage = _unavailableMessage(isSw));
      return;
    }
    final ok = await widget.onResend!(_effectivePhone);

    if (mounted) {
      if (ok) {
        setState(() {
          _resendAttempts++;
        });
        _clearAndRefocus();
        _startCooldownTimer();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSw
                  ? 'Nambari mpya ya OTP imetumwa kwenye ${VerifyOtpScreen.maskPhoneNumber(_effectivePhone)}.'
                  : 'A new OTP code has been sent to ${VerifyOtpScreen.maskPhoneNumber(_effectivePhone)}.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        setState(() {
          _errorMessage = isSw
              ? 'Imeshindikana kutuma OTP tena. Tafadhali subiri kidogo.'
              : 'Failed to resend OTP. Please wait a moment.';
        });
      }
    }
  }

  void _handleEditPhone() {
    if (widget.onEditPhone != null) {
      widget.onEditPhone!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final isSw = lang == 'sw';
    final maskedPhone = VerifyOtpScreen.maskPhoneNumber(_effectivePhone);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgBase : AppColors.lightBgSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: _handleEditPhone,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: AutofillGroup(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Official Logo
                  const SomaSmartLogo(
                    size: 46,
                    fontSize: 22,
                  ),
                  const SizedBox(height: 24),

                  // 2. Icon Badge
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Title: "Verify Your Phone Number"
                  Text(
                    isSw ? 'Hakiki Nambari Yako ya Simu' : 'Verify Your Phone Number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 4. Subtitle showing Masked Phone with "Edit" Link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isSw
                            ? 'Msimbo umetumwa kwa '
                            : 'Code sent to ',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        maskedPhone.isNotEmpty ? maskedPhone : '+255 7XX XXX XXX',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleEditPhone,
                        child: Text(
                          isSw ? 'Badilisha' : 'Edit',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 5. Inline Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 6. Six Individual Digit Entry Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_otpLength, (index) {
                      final hasValue = _controllers[index].text.isNotEmpty;
                      final hasError = _errorMessage != null;

                      return SizedBox(
                        width: 46,
                        height: 56,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) => _handleKeyPress(index, event),
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: index == 0 ? 6 : 1, // allow pasting 6 digits into first box
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: isDark
                                  ? (hasValue ? AppColors.darkBgContainer : AppColors.darkBgSurface)
                                  : (hasValue ? AppColors.lightBgContainer : Colors.white),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: hasError
                                      ? AppColors.error
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: hasError
                                      ? AppColors.error
                                      : (hasValue
                                          ? AppColors.primary.withValues(alpha: 0.5)
                                          : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle)),
                                  width: hasValue ? 1.5 : 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: hasError ? AppColors.error : AppColors.primary,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            onChanged: (val) => _handleDigitChanged(index, val),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // 7. Verify Button (Disabled until all 6 digits entered)
                  PrimaryButton(
                    text: isSw ? 'Thibitisha' : 'Verify',
                    isLoading: _isVerifying,
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: (_isComplete && !_isVerifying) ? _handleVerify : null,
                  ),

                  const SizedBox(height: 24),

                  // 8. Resend Section: Countdown Timer vs Resend Code vs Max Attempts Warning
                  if (_isResendExhausted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isSw
                                  ? 'Majaribio mengi mno, tafadhali jaribu tena baada ya dakika 10.'
                                  : 'Too many attempts, please try again in 10 minutes.',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_secondsRemaining > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSw
                              ? 'Tuma tena msimbo baada ya ${_formatTimerDisplay(_secondsRemaining)}'
                              : 'Resend code in ${_formatTimerDisplay(_secondsRemaining)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSw ? 'Hujapokea msimbo?' : "Didn't receive the code?",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: _handleResend,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: AppColors.primary,
                          ),
                          child: Text(
                            isSw
                                ? 'Tuma Tena Msimbo (${_maxResendAttempts - _resendAttempts})'
                                : 'Resend Code (${_maxResendAttempts - _resendAttempts} left)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
