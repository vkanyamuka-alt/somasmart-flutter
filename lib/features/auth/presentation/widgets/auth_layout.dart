import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Shared look of the sign-in screens (Log in, Sign up, Finish your account),
/// the same as the website's `AuthLayout` + `AuthPages.css`: grey page, one
/// white card, logo, title, plain labels, 48px fields and buttons, logo navy.
/// Always light, like the website and the `/login` route's forced light theme.
class AuthColors {
  static const page = Color(0xFFF4F6F9);
  static const card = Colors.white;
  static const cardBorder = Color(0xFFE2E8F0);
  static const ink = Color(0xFF0F172A);
  static const label = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
  static const inputBorder = Color(0xFFCBD5E1);
  static const tabsBg = Color(0xFFF1F5F9);
  static const navy = Color(0xFF184E78);
  static const navyDark = Color(0xFF123B5B);
  static const errorBg = Color(0xFFFEF2F2);
  static const errorBorder = Color(0xFFFECACA);
  static const errorText = Color(0xFFB91C1C);
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (showBack)
                            IconButton(
                              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AuthColors.label),
                              onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'),
                            ),
                          const Spacer(),
                          const AuthLanguageSwitch(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                        decoration: BoxDecoration(
                          color: AuthColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AuthColors.cardBorder),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0F0F172A), blurRadius: 3, offset: Offset(0, 1)),
                            BoxShadow(color: Color(0x0F0F172A), blurRadius: 24, offset: Offset(0, 8)),
                          ],
                        ),
                        child: child,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// SW | EN pill, top right (same as the website).
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
                color: selected ? AuthColors.navy : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AuthColors.cardBorder, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [option('sw', 'SW'), option('en', 'EN')]),
    );
  }
}

/// Logo, title, subtitle and an optional highlighted line (an email address).
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
          width: 52,
          height: 52,
          fit: BoxFit.contain,
          semanticLabel: 'SomaSmart',
          errorBuilder: (context, error, stackTrace) => Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AuthColors.navy, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AuthColors.ink,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.5, color: AuthColors.muted),
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
                    color: selected ? AuthColors.navy : AuthColors.muted,
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

/// Red box for errors, like `.auth-alert--error`.
class AuthErrorBox extends StatelessWidget {
  final String message;

  const AuthErrorBox(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AuthColors.errorBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AuthColors.errorBorder),
        ),
        child: Text(message, style: const TextStyle(fontSize: 13, height: 1.5, color: AuthColors.errorText)),
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
                        style: const TextStyle(fontWeight: FontWeight.w400, color: AuthColors.faint),
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

/// White 48px input with a grey outline and a navy focus ring.
InputDecoration authInputDecoration({required String hint, required IconData icon, Widget? suffix}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AuthColors.faint),
    prefixIcon: Icon(icon, size: 18, color: AuthColors.faint),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(AuthColors.inputBorder),
    enabledBorder: border(AuthColors.inputBorder),
    focusedBorder: border(AuthColors.navy, 1.5),
    errorBorder: border(AuthColors.errorText),
    focusedErrorBorder: border(AuthColors.errorText, 1.5),
    errorStyle: const TextStyle(fontSize: 12, color: AuthColors.errorText),
  );
}

const authInputTextStyle = TextStyle(fontSize: 15, color: AuthColors.ink);

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
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AuthColors.navy)),
      ),
    );
  }
}

/// Navy 48px button with an arrow, like `.auth-primary`.
class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({super.key, required this.text, required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AuthColors.navy.withValues(alpha: 0.7);
            if (states.contains(WidgetState.pressed)) return AuthColors.navyDark;
            return AuthColors.navy;
          }),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
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
        const Expanded(child: Divider(color: AuthColors.cardBorder, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: const TextStyle(fontSize: 12.5, color: AuthColors.faint)),
        ),
        const Expanded(child: Divider(color: AuthColors.cardBorder, height: 1)),
      ],
    );
  }
}

/// "Mgeni SomaSmart? Fungua akaunti" style line under the card's buttons.
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
