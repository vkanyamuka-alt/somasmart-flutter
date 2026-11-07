import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/soma_smart_logo.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

/// First Google sign-in: Google gives a name and an email, but not the phone
/// number and form that every other sign-up asks for. Same fields and rules as
/// the website's /complete-profile page.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int? _formLevel;
  String? _errorMessage;
  bool _nameFilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameFilled) return;
    _nameFilled = true;
    try {
      final user = ref.read(supabaseClientProvider).auth.currentUser;
      final profileName = ref.read(userProfileProvider).value?.fullName;
      _nameController.text = (user?.userMetadata?['full_name'] as String?) ?? profileName ?? '';
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    final lang = ref.read(languageProvider);
    final result = await ref.read(authControllerProvider.notifier).completeGoogleProfile(
          fullName: _nameController.text,
          phone: _phoneController.text,
          formLevel: _formLevel!,
        );
    if (!mounted) return;
    if (result.isSuccess) {
      context.go('/home');
    } else {
      setState(() => _errorMessage = AuthController.getLocalizedErrorMessage(result.errorMessage, lang));
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go('/welcome');
  }

  InputDecoration _decoration(bool isDark, {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13.5,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
      prefixIcon: Icon(icon, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
      filled: true,
      fillColor: isDark ? AppColors.darkBgContainer : AppColors.lightBgContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _label(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSw = ref.watch(languageProvider) == 'sw';
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    String? email;
    try {
      email = ref.read(supabaseClientProvider).auth.currentUser?.email;
    } catch (_) {}

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgBase : AppColors.lightBgSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SomaSmartLogo(size: 44, fontSize: 22),
                  const SizedBox(height: 20),
                  Text(
                    isSw ? 'Kamilisha Akaunti' : 'Finish your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSw
                        ? 'Hatua moja zaidi: namba yako ya simu na kidato chako.'
                        : 'One more step: your phone number and your form.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _label(isSw ? 'Jina Kamili *' : 'Full Name *', isDark),
                  TextFormField(
                    key: const Key('complete-name'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: textColor),
                    decoration: _decoration(isDark,
                        hint: isSw ? 'Weka jina lako kamili' : 'Enter your full name',
                        icon: Icons.person_outline_rounded),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (isSw ? 'Tafadhali weka jina lako.' : 'Please enter your name.')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _label(isSw ? 'Nambari ya Simu *' : 'Phone Number *', isDark),
                  TextFormField(
                    key: const Key('complete-phone'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: textColor),
                    decoration: _decoration(isDark, hint: '07XXXXXXXX', icon: Icons.phone_iphone_rounded),
                    validator: (v) => AuthController.isValidTanzanianPhone(v ?? '')
                        ? null
                        : (isSw
                            ? 'Weka namba ya simu sahihi (mfano 07XXXXXXXX).'
                            : 'Enter a valid phone number (e.g. 07XXXXXXXX).'),
                  ),
                  const SizedBox(height: 16),
                  _label(isSw ? 'Kidato *' : 'Form *', isDark),
                  DropdownButtonFormField<int>(
                    key: const Key('complete-form-level'),
                    initialValue: _formLevel,
                    decoration: _decoration(isDark,
                        hint: isSw ? 'Chagua kidato' : 'Choose your form', icon: Icons.school_outlined),
                    dropdownColor: isDark ? AppColors.darkBgSurface : Colors.white,
                    style: TextStyle(color: textColor, fontSize: 15),
                    items: [
                      for (var level = 1; level <= 6; level++)
                        DropdownMenuItem(value: level, child: Text(isSw ? 'Kidato cha $level' : 'Form $level')),
                    ],
                    onChanged: (v) => setState(() => _formLevel = v),
                    validator: (v) => v == null ? (isSw ? 'Chagua kidato chako.' : 'Please choose your form.') : null,
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    key: const Key('complete-profile-submit'),
                    text: isSw ? 'Endelea' : 'Continue',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isLoading ? null : _signOut,
                    child: Text(
                      isSw ? 'Si akaunti yako? Toka' : 'Not your account? Sign out',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
