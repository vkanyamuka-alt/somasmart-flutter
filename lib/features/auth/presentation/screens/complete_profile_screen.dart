import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_layout.dart';

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

  @override
  Widget build(BuildContext context) {
    final isSw = ref.watch(languageProvider) == 'sw';
    final isLoading = ref.watch(authControllerProvider).isLoading;
    String? email;
    try {
      email = ref.read(supabaseClientProvider).auth.currentUser?.email;
    } catch (_) {}

    return AuthLayout(
      showBack: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: isSw ? 'Kamilisha akaunti' : 'Finish your account',
              subtitle: isSw
                  ? 'Hatua moja zaidi: namba yako ya simu na kidato chako.'
                  : 'One more step: your phone number and your form.',
              note: email,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              AuthErrorBox(_errorMessage!),
              const SizedBox(height: 16),
            ],
            AuthField(
              label: isSw ? 'Jina kamili' : 'Full name',
              child: TextFormField(
                key: const Key('complete-name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: authInputTextStyle,
                decoration: authInputDecoration(hint: 'Juma Kibena', icon: Icons.person_outline_rounded),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (isSw ? 'Weka jina lako kamili.' : 'Please enter your full name.')
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            AuthField(
              label: isSw ? 'Namba ya simu' : 'Phone number',
              child: TextFormField(
                key: const Key('complete-phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                style: authInputTextStyle,
                decoration: authInputDecoration(hint: '07XXXXXXXX', icon: Icons.phone_iphone_rounded),
                validator: (v) => AuthController.isValidTanzanianPhone(v ?? '')
                    ? null
                    : (isSw
                        ? 'Weka namba ya simu sahihi (mfano 07XXXXXXXX).'
                        : 'Enter a valid phone number (e.g. 07XXXXXXXX).'),
              ),
            ),
            const SizedBox(height: 16),
            AuthField(
              label: isSw ? 'Kidato' : 'Form',
              child: DropdownButtonFormField<int>(
                key: const Key('complete-form-level'),
                initialValue: _formLevel,
                decoration: authInputDecoration(
                  hint: isSw ? 'Chagua kidato' : 'Choose your form',
                  icon: Icons.school_outlined,
                ),
                dropdownColor: Colors.white,
                style: authInputTextStyle,
                items: [
                  for (var level = 1; level <= 6; level++)
                    DropdownMenuItem(value: level, child: Text(isSw ? 'Kidato cha $level' : 'Form $level')),
                ],
                onChanged: (v) => setState(() => _formLevel = v),
                validator: (v) => v == null ? (isSw ? 'Chagua kidato chako.' : 'Please choose your form.') : null,
              ),
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              key: const Key('complete-profile-submit'),
              text: isSw ? 'Endelea' : 'Continue',
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Center(
              child: AuthLink(
                isSw ? 'Si akaunti yako? Toka' : 'Not your account? Sign out',
                onTap: isLoading ? null : _signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
