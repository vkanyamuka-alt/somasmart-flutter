import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_layout.dart';
import '../widgets/google_sign_in_section.dart';

/// Log in, same layout as the website's sign-in page: one white card with the
/// logo, "Karibu tena", Ingia | Jisajili tabs, phone + password, then
/// "Continue with Google" under an "or" line. ("Remember me" is gone: the
/// session is always kept, so the box did nothing.)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final lang = ref.read(languageProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);
    final normalizedPhone = AuthController.normalizePhoneNumber(_phoneController.text.trim());

    final result = await authNotifier.signIn(
      phone: normalizedPhone,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (result.isSuccess) {
      context.go('/home');
    } else {
      final error = ref.read(authControllerProvider).error;
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
              title: isSw ? 'Karibu tena' : 'Welcome back',
              subtitle: isSw ? 'Ingia uendelee kujisomea.' : 'Log in to continue studying.',
            ),
            const SizedBox(height: 20),
            const AuthTabs(registerSelected: false),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              AuthErrorBox(_errorMessage!),
              const SizedBox(height: 16),
            ],
            AuthField(
              label: isSw ? 'Namba ya simu' : 'Phone number',
              child: TextFormField(
                key: const Key('login-phone'),
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
              label: isSw ? 'Neno la siri' : 'Password',
              trailing: AuthLink(
                isSw ? 'Umesahau neno la siri?' : 'Forgot password?',
                key: const Key('login-forgot'),
                onTap: () => context.push('/forgot-password'),
              ),
              child: TextFormField(
                key: const Key('login-password'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _handleSignIn(),
                style: authInputTextStyle,
                decoration: authInputDecoration(
                  hint: '••••••••',
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
                    return isSw ? 'Weka neno la siri.' : 'Please enter your password.';
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
              key: const Key('login-submit'),
              text: isSw ? 'Ingia' : 'Log in',
              isLoading: isLoading,
              onPressed: _handleSignIn,
            ),
            GoogleSignInSection(
              onError: (message) => setState(() => _errorMessage = message),
            ),
            const SizedBox(height: 20),
            AuthFooter(
              text: isSw ? 'Mgeni SomaSmart?' : 'New to SomaSmart?',
              linkText: isSw ? 'Fungua akaunti' : 'Create an account',
              linkKey: const Key('login-to-signup'),
              onTap: () => context.go('/signup'),
            ),
          ],
        ),
      ),
    );
  }
}
