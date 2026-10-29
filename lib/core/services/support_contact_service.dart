import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';

/// Public support details that admins edit in the admin panel (the
/// `support_contact` table), the same source as the web app's
/// `src/lib/supportContact.js`.
class SupportContact {
  final String? phone;
  final String? email;
  const SupportContact({this.phone, this.email});

  static final _phonePattern = RegExp(r'^\+255[67]\d{8}$');
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Phone digits without "+", only for a valid Tanzanian mobile number.
  String? get _digits => phone != null && _phonePattern.hasMatch(phone!) ? phone!.substring(1) : null;
  bool get _hasEmail => email != null && _emailPattern.hasMatch(email!);

  bool get isEmpty => _digits == null && !_hasEmail;

  Uri? get whatsapp => _digits == null ? null : Uri.parse('https://wa.me/$_digits');
  Uri? get call => _digits == null ? null : Uri.parse('tel:+$_digits');
  Uri? get mail => _hasEmail ? Uri(scheme: 'mailto', path: email) : null;

  /// "+255 712 345 678", for display.
  String? get displayPhone {
    final d = _digits;
    if (d == null) return null;
    return '+${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6, 9)} ${d.substring(9)}';
  }

  /// WhatsApp with the student's feedback already written in.
  Uri? feedbackWhatsapp(String message) => _digits == null
      ? null
      : Uri.https('wa.me', '/$_digits', {'text': 'SomaSmart feedback:\n${message.trim()}'});

  /// Email with subject and the student's feedback as the body.
  Uri? feedbackMail(String message) => _hasEmail
      ? Uri(
          scheme: 'mailto',
          path: email,
          query: 'subject=${Uri.encodeComponent('SomaSmart feedback')}&body=${Uri.encodeComponent(message.trim())}',
        )
      : null;
}

/// Loads the contact once; a missing table or row gives an empty contact.
final supportContactProvider = FutureProvider<SupportContact>((ref) async {
  try {
    final client = ref.read(supabaseClientProvider);
    final row = await client.from('support_contact').select('phone, email').maybeSingle();
    return SupportContact(phone: row?['phone'] as String?, email: row?['email'] as String?);
  } catch (_) {
    return const SupportContact();
  }
});
