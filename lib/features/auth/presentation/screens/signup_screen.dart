import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_layout.dart';
import '../widgets/google_sign_in_section.dart';

/// Sign up (the "Jisajili" tab): the website's fields and wording in the app's own page: name, phone, optional
/// email, password, then "Continue with Google".
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final lang = ref.read(languageProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);
    final normalizedPhone = AuthController.normalizePhoneNumber(_phoneController.text.trim());
    final emailText = _emailController.text.trim();

    final result = await authNotifier.signUp(
      phone: normalizedPhone,
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      email: emailText.isNotEmpty ? emailText : null,
    );

    if (!mounted) return;
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.needsSignIn
                ? (lang == 'sw' ? 'Akaunti imeundwa! Tafadhali ingia.' : 'Account created! Please sign in.')
                : (lang == 'sw' ? 'Akaunti imeundwa! Karibu SomaSmart.' : 'Account created! Welcome to SomaSmart.'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(result.needsSignIn ? '/login' : '/home');
    } else {
      final error = ref.read(authControllerProvider).error ?? result.errorMessage;
      setState(() => _errorMessage = AuthController.getLocalizedErrorMessage(error, lang));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = ref.watch(languageProvider) == 'sw';
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: isSw ? 'Fungua akaunti' : 'Create your account',
              subtitle: isSw ? 'Akaunti ya mwanafunzi, bure kuanza.' : 'A student account, free to start.',
            ),
            const SizedBox(height: 20),
            const AuthTabs(registerSelected: true),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              AuthErrorBox(_errorMessage!),
              const SizedBox(height: 16),
            ],
            AuthField(
              label: isSw ? 'Jina kamili' : 'Full name',
              child: TextFormField(
                key: const Key('register-name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                style: authInputTextStyle,
                decoration: authInputDecoration(hint: 'Juma Kibena', icon: Icons.person_outline_rounded),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? (isSw ? 'Weka jina lako kamili.' : 'Please enter your full name.')
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            AuthField(
              label: isSw ? 'Namba ya simu' : 'Phone number',
              child: TextFormField(
                key: const Key('register-phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                style: authInputTextStyle,
                decoration: authInputDecoration(hint: '07XXXXXXXX', icon: Icons.phone_iphone_rounded),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isSw ? 'Weka namba yako ya simu.' : 'Please enter your phone number.';
                  }
                  final cleaned = val.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                  if (cleaned.length < 9) {
                    return isSw ? 'Namba ya simu si sahihi.' : 'Please enter a valid phone number.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            AuthField(
              label: isSw ? 'Barua pepe' : 'Email',
              optional: isSw ? '(si lazima)' : '(optional)',
              child: TextFormField(
                key: const Key('register-email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                style: authInputTextStyle,
                decoration: authInputDecoration(hint: 'name@email.com', icon: Icons.mail_outline_rounded),
                validator: (val) {
                  final v = val?.trim() ?? '';
                  if (v.isNotEmpty && (!v.contains('@') || !v.contains('.'))) {
                    return isSw
                        ? 'Barua pepe si sahihi. Iache wazi kama huna.'
                        : "That email is not valid. Leave it empty if you don't have one.";
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            AuthField(
              label: isSw ? 'Neno la siri' : 'Password',
              child: TextFormField(
                key: const Key('register-password'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _handleSignUp(),
                style: authInputTextStyle,
                decoration: authInputDecoration(
                  hint: isSw ? 'Angalau herufi 6' : 'At least 6 characters',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    tooltip: _obscurePassword
                        ? (isSw ? 'Onyesha neno la siri' : 'Show password')
                        : (isSw ? 'Ficha neno la siri' : 'Hide password'),
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AuthColors.muted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isSw ? 'Weka neno la siri.' : 'Please enter a password.';
                  }
                  if (val.length < 6) {
                    return isSw
                        ? 'Neno la siri lazima liwe na herufi 6 au zaidi.'
                        : 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              key: const Key('register-submit'),
              text: isSw ? 'Fungua akaunti' : 'Create account',
              isLoading: isLoading,
              onPressed: _handleSignUp,
            ),
            GoogleSignInSection(
              onError: (message) => setState(() => _errorMessage = message),
            ),
            const SizedBox(height: 20),
            AuthFooter(
              text: isSw ? 'Una akaunti tayari?' : 'Already have an account?',
              linkText: isSw ? 'Ingia' : 'Log in',
              linkKey: const Key('signup-to-login'),
              onTap: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
