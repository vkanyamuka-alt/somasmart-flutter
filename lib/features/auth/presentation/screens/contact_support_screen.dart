import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/support_contact_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/soma_smart_logo.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

/// Screen for manual account recovery and support when user has lost their phone and has no email access.
class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lostPhoneController = TextEditingController();
  final _alternateContactController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitted = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _lostPhoneController.dispose();
    _alternateContactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authNotifier = ref.read(authControllerProvider.notifier);
    final success = await authNotifier.submitAccountRecoveryRequest(
      fullName: _nameController.text,
      lostPhone: _lostPhoneController.text,
      alternateContact: _alternateContactController.text,
      issueDescription: _descriptionController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _isSubmitted = true;
        } else {
          _errorMessage = 'Imeshindikana kutuma ombi. Tafadhali jaribu tena.';
        }
      });
    }
  }

  Future<void> _launch(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uri.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final isSw = lang == 'sw';

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
          onPressed: () {
            if (context.canPop()) {
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
            child: _isSubmitted
                ? _buildSuccessView(context, isDark: isDark, isSw: isSw)
                : _buildFormView(context, isDark: isDark, isSw: isSw),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context, {
    required bool isDark,
    required bool isSw,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isSw ? 'Ombi Limetumwa Kikamilifu' : 'Recovery Request Submitted',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isSw
              ? 'Timu yetu ya huduma kwa wateja itawasiliana nawe kupitia mawasiliano mbadala uliyoweka ndani ya masaa 24.'
              : 'Our support team will contact you via your alternate contact details within 24 hours.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          text: isSw ? 'Rudi Kwenye Kuingia' : 'Back to Sign In',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildFormView(
    BuildContext context, {
    required bool isDark,
    required bool isSw,
  }) {
    final contact = ref.watch(supportContactProvider).valueOrNull;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SomaSmartLogo(size: 44, fontSize: 22),
          const SizedBox(height: 20),

          // Badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),

          Text(
            isSw ? 'Msaada wa Akaunti' : 'Account Recovery & Support',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSw
                ? 'Ikiwa umepoteza simu na huna barua pepe, jaza fomu hii kwa ajili ya kurejesha akaunti yako.'
                : 'If you lost your phone and have no email, fill this form to recover your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
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
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Full Name
          _buildTextField(
            controller: _nameController,
            label: isSw ? 'Jina Kamili' : 'Full Name',
            hint: isSw ? 'Weka jina lako kamili' : 'Enter your full name',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
            validator: (v) =>
                v == null || v.trim().isEmpty ? (isSw ? 'Weka jina lako' : 'Name is required') : null,
          ),
          const SizedBox(height: 14),

          // Lost Phone
          _buildTextField(
            controller: _lostPhoneController,
            label: isSw ? 'Namba ya Simu ya Akaunti' : 'Registered Phone Number',
            hint: isSw ? 'Weka nambari ya simu iliyosajiliwa' : 'Enter registered phone number',
            icon: Icons.phone_disabled_outlined,
            keyboardType: TextInputType.phone,
            isDark: isDark,
            validator: (v) => v == null || v.trim().length < 9
                ? (isSw ? 'Weka namba sahihi' : 'Valid phone number required')
                : null,
          ),
          const SizedBox(height: 14),

          // Alternate Contact
          _buildTextField(
            controller: _alternateContactController,
            label: isSw ? 'Mawasiliano Mbadala (Simu / Barua Pepe)' : 'Alternate Contact (Phone / Email)',
            hint: isSw ? 'Weka nambari ya simu au barua pepe' : 'Enter alternate phone or email',
            icon: Icons.contact_phone_outlined,
            isDark: isDark,
            validator: (v) => v == null || v.trim().isEmpty
                ? (isSw ? 'Weka mawasiliano mbadala' : 'Alternate contact is required')
                : null,
          ),
          const SizedBox(height: 14),

          // Issue description
          _buildTextField(
            controller: _descriptionController,
            label: isSw ? 'Maelezo ya Tatizo' : 'Issue Description',
            hint: isSw
                ? 'Eleza jinsi ulivyopoteza namba yako...'
                : 'Explain what happened with your account...',
            icon: Icons.description_outlined,
            maxLines: 3,
            isDark: isDark,
            validator: (v) => v == null || v.trim().isEmpty
                ? (isSw ? 'Weka maelezo ya tatizo' : 'Please provide details')
                : null,
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            text: isSw ? 'Tuma Ombi la Msaada' : 'Submit Recovery Request',
            isLoading: _isLoading,
            icon: Icons.send_rounded,
            onPressed: _handleSubmit,
          ),
          const SizedBox(height: 24),

          // Direct Channels
          // Direct contact, from the details an admin set in the admin panel.
          if (contact != null && contact.whatsapp != null) ...[
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    isSw ? 'Au wasiliana nasi moja kwa moja' : 'Or reach us directly',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launch(contact.whatsapp!),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF22C55E),
                      side: const BorderSide(color: Color(0xFF22C55E)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launch(contact.call!),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                    label: Text(isSw ? 'Piga Simu' : 'Call Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            filled: true,
            fillColor: isDark ? AppColors.darkBgSurface : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
