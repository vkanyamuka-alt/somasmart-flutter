import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether this Supabase user has a Google identity (first sign-in with
/// Google, or an email account that Google was later linked to).
bool signedInWithGoogle(User? user) {
  if (user == null) return false;
  final providers = user.appMetadata['providers'];
  if (providers is List && providers.contains('google')) return true;
  if (user.appMetadata['provider'] == 'google') return true;
  return user.identities?.any((i) => i.provider == 'google') ?? false;
}

/// A first Google sign-in gives a name and an email but no phone number or
/// form, which every other sign-up asks for. Only Google students without a
/// phone go through /complete-profile, so older accounts never see it.
/// Same rule as the website (src/lib/googleSignIn.js).
bool needsProfileCompletion(User? user, String? phone) {
  if (user == null) return false;
  if ((phone ?? '').trim().isNotEmpty) return false;
  return signedInWithGoogle(user);
}
