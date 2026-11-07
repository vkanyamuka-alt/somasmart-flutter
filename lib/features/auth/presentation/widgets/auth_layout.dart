import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Shared pieces of the sign-in screens (Log in, Sign up, Finish your account).
///
/// The app keeps its own full-page look (white page, logo + "SomaSmart", grey
/// filled fields, the standard button); from the website it takes the
/// Ingia | Jisajili tabs, the SW | EN switch and the wording. Always light,
/// like the `/login` route's forced light theme.
class AuthColors {
  static const page = AppColors.lightBgSurface;
  static const ink = AppColors.lightTextPrimary;
  static const label = AppColors.lightTextPrimary;
  static const muted = AppColors.lightTextSecondary;
  static const faint = AppColors.lightTextMuted;
  static const field = AppColors.lightBgContainer;
  static const fieldBorder = AppColors.lightBorderSubtle;
  static const line = AppColors.lightBorder;
  static const tabsBg = AppColors.lightBgContainer;
  static const navy = AppColors.primary;
}

class AuthLayout extends ConsumerWidget {
  final Widget child;

  /// Shows a back arrow (Log in / Sign up come from the welcome screen).
  final bool showBack;

  const AuthLayout({super.key, required this.child, this.showBack = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AuthColors.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AuthColors.ink),
                onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'),
              )
            : null,
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: Center(child: AuthLanguageSwitch())),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// SW | EN pill, top right (same switch as the website).
class AuthLanguageSwitch extends ConsumerWidget {
  const AuthLanguageSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    Widget option(String code, String text) {
      final selected = lang == code;
      return Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          key: Key('auth-lang-$code'),
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.read(languageProvider.notifier).setLanguage(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? const [BoxShadow(color: Color(0x1F0F172A), blurRadius: 2, offset: Offset(0, 1))]
                  : null,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AuthColors.navy : AuthColors.muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AuthColors.line, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [option('sw', 'SW'), option('en', 'EN')]),
    );
  }
}

/// Logo, "SomaSmart", title, subtitle and an optional highlighted line (an
/// email address) — the app's own header.
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? note;

  const AuthHeader({super.key, required this.title, this.subtitle, this.note});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 64,
          height: 64,
          fit: BoxFit.contain,
          semanticLabel: 'SomaSmart',
          errorBuilder: (context, error, stackTrace) => Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AuthColors.navy, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32)),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'SomaSmart',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AuthColors.ink),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AuthColors.ink),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AuthColors.muted),
          ),
        ],
        if (note != null && note!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            note!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AuthColors.navy),
          ),
        ],
      ],
    );
  }
}

/// Ingia | Jisajili. Each tab is its own route, so the phone's back button
/// still leaves the sign-in screens instead of flipping between tabs.
class AuthTabs extends ConsumerWidget {
  final bool registerSelected;

  const AuthTabs({super.key, required this.registerSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSw = ref.watch(languageProvider) == 'sw';
    Widget tab(Key key, String text, bool selected, String route) => Expanded(
          child: Semantics(
            button: true,
            selected: selected,
            child: GestureDetector(
              key: key,
              behavior: HitTestBehavior.opaque,
              onTap: selected ? null : () => context.go(route),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? const [BoxShadow(color: Color(0x1F0F172A), blurRadius: 2, offset: Offset(0, 1))]
                      : null,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? AuthColors.navy : AuthColors.faint,
                  ),
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AuthColors.tabsBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          tab(const Key('tab-login'), isSw ? 'Ingia' : 'Log in', !registerSelected, '/login'),
          tab(const Key('tab-register'), isSw ? 'Jisajili' : 'Sign up', registerSelected, '/signup'),
        ],
      ),
    );
  }
}

/// The app's red error banner.
class AuthErrorBox extends StatelessWidget {
  final String message;

  const AuthErrorBox(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.error, fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label above a field; `trailing` sits at the right of the label row
/// (the "Forgot password?" link) and `optional` adds a grey "(optional)".
class AuthField extends StatelessWidget {
  final String label;
  final String? optional;
  final Widget? trailing;
  final Widget child;

  const AuthField({super.key, required this.label, required this.child, this.optional, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: label,
                  children: [
                    if (optional != null)
                      TextSpan(
                        text: ' $optional',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400, color: AuthColors.faint),
                      ),
                  ],
                ),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AuthColors.label),
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing!],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// The app's grey filled field with a navy focus outline.
InputDecoration authInputDecoration({required String hint, required IconData icon, Widget? suffix}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, color: AuthColors.faint),
    prefixIcon: Icon(icon, size: 20, color: AuthColors.muted),
    suffixIcon: suffix,
    filled: true,
    fillColor: AuthColors.field,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(AuthColors.line),
    enabledBorder: border(AuthColors.fieldBorder),
    focusedBorder: border(AuthColors.navy, 1.5),
  );
}

const authInputTextStyle = TextStyle(color: AuthColors.ink);

/// Navy link text ("Forgot password?", "Create an account").
class AuthLink extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const AuthLink(this.text, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AuthColors.navy)),
      ),
    );
  }
}

/// The app's standard navy button.
class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({super.key, required this.text, required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(text: text, isLoading: isLoading, onPressed: isLoading ? null : onPressed);
  }
}

/// Grey line with centred text ("au" / "or").
class AuthDivider extends StatelessWidget {
  final String text;

  const AuthDivider(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AuthColors.line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: const TextStyle(fontSize: 12.5, color: AuthColors.muted)),
        ),
        const Expanded(child: Divider(color: AuthColors.line, height: 1)),
      ],
    );
  }
}

/// "Mgeni SomaSmart? Fungua akaunti" style line under the buttons.
class AuthFooter extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;
  final Key? linkKey;

  const AuthFooter({super.key, required this.text, required this.linkText, required this.onTap, this.linkKey});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$text ', style: const TextStyle(fontSize: 13.5, color: AuthColors.muted)),
        AuthLink(linkText, key: linkKey, onTap: onTap),
      ],
    );
  }
}
