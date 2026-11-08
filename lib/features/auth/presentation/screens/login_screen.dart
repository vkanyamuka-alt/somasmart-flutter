import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_layout.dart';
import '../widgets/google_sign_in_section.dart';

/// Log in: the app's full-page look with the website's Ingia | Jisajili tabs,
/// SW | EN switch and wording. Phone number or email + password, then
/// "Continue with Google" under an "or" line. ("Remember me" is gone: the
/// session is always kept, so the box did nothing.)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final lang = ref.read(languageProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);
    // Phone number or email, like the website (`resolveLoginIdentifier`):
    // anything with "@" is used as the email, everything else is a phone
    // number (signed in through its 255…@phone.somasmart.com address).
    final identifier = _identifierController.text.trim();

    final result = await authNotifier.signIn(
      phone: identifier.contains('@') ? identifier : AuthController.normalizePhoneNumber(identifier),
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
              label: isSw ? 'Namba ya simu au email' : 'Phone number or email',
              child: TextFormField(
                key: const Key('login-phone'),
                controller: _identifierController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [AutofillHints.telephoneNumber, AutofillHints.email],
                style: authInputTextStyle,
                decoration: authInputDecoration(
                  hint: isSw ? '07XXXXXXXX au email' : '07XXXXXXXX or email',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (val) {
                  final v = val?.trim() ?? '';
                  if (v.isEmpty) {
                    return isSw ? 'Weka namba ya simu au email.' : 'Please enter your phone number or email.';
                  }
                  if (v.contains('@')) {
                    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                    return ok ? null : (isSw ? 'Email si sahihi.' : 'Please enter a valid email address.');
                  }
                  final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
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
