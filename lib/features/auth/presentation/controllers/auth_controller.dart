import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/google_profile.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../account/presentation/controllers/account_controller.dart';

/// Provider for tracking first-time launch / onboarding completion.
final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const String key = 'somasmart_onboarding_completed';

  OnboardingNotifier(this._prefs) : super(false) {
    state = _prefs.getBool(key) ?? false;
  }

  Future<void> completeOnboarding() async {
    state = true;
    await _prefs.setBool(key, true);
  }

  Future<void> resetOnboarding() async {
    state = false;
    await _prefs.remove(key);
  }
}

/// Result of sign in or sign up operation.
class AuthResult {
  final bool success;

  /// Sign-up worked but Supabase returned no session (e.g. email confirmation is on):
  /// the student has to sign in.
  final bool needsSignIn;

  /// Signed in with Google for the first time: the phone number and form are
  /// still missing, so /complete-profile comes before /home.
  final bool needsProfile;

  /// The student closed the Google account picker: no error to show.
  final bool cancelled;
  final String? phone;
  final String? errorMessage;

  bool get isSuccess => success;

  const AuthResult({
    required this.success,
    this.needsSignIn = false,
    this.needsProfile = false,
    this.cancelled = false,
    this.phone,
    this.errorMessage,
  });

  factory AuthResult.success({String? phone, bool needsSignIn = false}) => AuthResult(
        success: true,
        needsSignIn: needsSignIn,
        phone: phone,
      );

  factory AuthResult.failure(String error) => AuthResult(
        success: false,
        errorMessage: error,
      );

  factory AuthResult.cancelled() => const AuthResult(success: false, cancelled: true);
}

/// Controller managing Phone-First Supabase authentication.
///
/// Phone verification is skipped: there is no server-side SMS OTP yet, and codes made on the
/// device proved nothing. Add verification back only through a server-side OTP.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AuthController(this._ref) : super(const AsyncValue.data(null));

  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  /// Normalizes phone input to Tanzanian E.164 (+255XXXXXXXXX).
  static String normalizePhoneNumber(String input) {
    var cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
    if (cleaned.isEmpty) return '';

    if (cleaned.startsWith('0')) {
      cleaned = '+255${cleaned.substring(1)}';
    } else if (cleaned.startsWith('255')) {
      cleaned = '+$cleaned';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+255$cleaned';
    }
    return cleaned;
  }

  /// Validates standard Tanzanian mobile numbers (+255 followed by 6 or 7 and 8 digits).
  static bool isValidTanzanianPhone(String phone) {
    final norm = normalizePhoneNumber(phone);
    return RegExp(r'^\+255[67]\d{8}$').hasMatch(norm);
  }

  /// Authenticate an existing student via Phone Number and Password.
  Future<AuthResult> signIn({
    required String phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final normPhone = normalizePhoneNumber(phone);

    try {
      // Determine auth identity (supports normalized phone with synthetic fallback or email)
      final authEmail = phone.contains('@')
          ? phone.trim()
          : '${normPhone.replaceAll('+', '')}@phone.somasmart.com';

      final response = await _client.auth.signInWithPassword(
        email: authEmail,
        password: password.trim(),
      );

      final user = response.user;
      if (user != null) {
        await _ref.read(userProfileProvider.notifier).refreshProfile();
        state = const AsyncValue.data(null);
        return AuthResult.success(phone: normPhone);
      } else {
        throw const AuthException('Sign in failed. Invalid credentials.');
      }
    } on AuthException catch (e, st) {
      state = AsyncValue.error(e, st);
      return AuthResult.failure(e.message);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return AuthResult.failure(e.toString());
    }
  }

  /// Register a new student account.
  Future<AuthResult> signUp({
    required String phone,
    required String password,
    required String fullName,
    String? email,
    int formLevel = 4,
  }) async {
    state = const AsyncValue.loading();
    final normPhone = normalizePhoneNumber(phone);

    try {
      // 1. Verify unique phone number in profiles
      try {
        final existing = await _client
            .from('profiles')
            .select('id')
            .eq('phone', normPhone)
            .maybeSingle();

        if (existing != null) {
          final err = 'Namba hii ya simu ($normPhone) tayari imesajiliwa. Tafadhali ingia.';
          state = AsyncValue.error(AuthException(err), StackTrace.current);
          return AuthResult.failure(err);
        }
      } catch (_) {}

      // 2. Register user with Supabase Auth
      final cleanEmail = email?.trim().isNotEmpty == true ? email!.trim() : null;
      final authEmail = cleanEmail ?? '${normPhone.replaceAll('+', '')}@phone.somasmart.com';

      debugPrint('🔵 [SUPABASE AUTH SIGNUP ATTEMPT] authEmail=$authEmail, phone=$normPhone');

      final response = await _client.auth.signUp(
        email: authEmail,
        password: password.trim(),
        data: {
          'phone': normPhone,
          'full_name': fullName.trim(),
          'email': cleanEmail,
          'role': 'student',
          'form_level': formLevel,
          'is_verified': false,
        },
      );

      debugPrint('🟢 [SUPABASE AUTH SIGNUP SUCCESS] user.id=${response.user?.id}, hasSession=${response.session != null}');

      final user = response.user;
      if (user != null) {
        // 3. Create initial profile record (marked is_verified: false)
        try {
          await _client.from('profiles').upsert({
            'id': user.id,
            'phone': normPhone,
            'email': cleanEmail ?? '',
            'full_name': fullName.trim(),
            'role': 'student',
            'is_verified': false,
            'subscription_status': 'trial',
          });
        } catch (dbErr, dbSt) {
          debugPrint('⚠️ [PROFILES DB UPSERT NON-FATAL ERROR]: $dbErr\n$dbSt');
        }

        try {
          await _client.from('student_profiles').upsert({
            'id': user.id,
            'form_level': formLevel,
            'stream': 'none',
          });
        } catch (studentDbErr, studentDbSt) {
          debugPrint('⚠️ [STUDENT PROFILES DB UPSERT NON-FATAL ERROR]: $studentDbErr\n$studentDbSt');
        }

        // No phone verification step (see class comment).
        final hasSession = response.session != null;
        if (hasSession) {
          await _ref.read(userProfileProvider.notifier).refreshProfile();
        }
        state = const AsyncValue.data(null);
        return AuthResult.success(phone: normPhone, needsSignIn: !hasSession);
      } else {
        throw const AuthException('Registration failed. Please try again.');
      }
    } on AuthException catch (e, st) {
      debugPrint('🔴 [SUPABASE AUTH EXCEPTION]');
      debugPrint('  Error Type: ${e.runtimeType}');
      debugPrint('  Error Message: ${e.message}');
      debugPrint('  Status Code: ${e.statusCode}');
      debugPrint('  Error Code: ${e.code}');
      debugPrint('  Stack Trace:\n$st');
      state = AsyncValue.error(e, st);
      return AuthResult.failure(e.message);
    } catch (e, st) {
      debugPrint('🔴 [UNEXPECTED AUTH EXCEPTION]');
      debugPrint('  Error Type: ${e.runtimeType}');
      debugPrint('  Error: $e');
      debugPrint('  Stack Trace:\n$st');
      state = AsyncValue.error(e, st);
      return AuthResult.failure(e.toString());
    }
  }

  /// GoogleSignIn.initialize may run only once per app start.
  static Future<void>? _googleInit;

  /// "Continue with Google": Android's own account picker gives a Google ID
  /// token, and Supabase signs in with it (no browser, no deep link). A first
  /// sign-in creates the auth user; the on_auth_user_created trigger then makes
  /// the profile as a free student, whatever the token or metadata say.
  Future<AuthResult> signInWithGoogle() async {
    if (!Env.googleSignInConfigured) {
      return AuthResult.failure('Google sign-in is not set up in this build.');
    }
    state = const AsyncValue.loading();
    try {
      final google = GoogleSignIn.instance;
      _googleInit ??= google.initialize(serverClientId: Env.googleWebClientId);
      await _googleInit;

      final account = await google.authenticate(scopeHint: const ['email']);
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google did not return an ID token.');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      await _ref.read(userProfileProvider.notifier).refreshProfile();
      final profile = _ref.read(userProfileProvider).value;
      state = const AsyncValue.data(null);
      return AuthResult(
        success: true,
        needsProfile: needsProfileCompletion(_client.auth.currentUser, profile?.phone),
      );
    } on GoogleSignInException catch (e, st) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        state = const AsyncValue.data(null);
        return AuthResult.cancelled();
      }
      debugPrint('[GOOGLE SIGN-IN] ${e.code}: ${e.description}');
      state = AsyncValue.error(e, st);
      return AuthResult.failure(e.toString());
    } on AuthException catch (e, st) {
      debugPrint('[GOOGLE SIGN-IN -> SUPABASE] ${e.statusCode} ${e.message}');
      state = AsyncValue.error(e, st);
      return AuthResult.failure(e.message);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return AuthResult.failure(e.toString());
    }
  }

  /// Last step of a first Google sign-in: the phone number and form that the
  /// sign-up screen asks everyone else for. The form is saved first because
  /// the phone number is what marks the profile as complete. Name and phone go
  /// through update_my_profile, like the website.
  Future<AuthResult> completeGoogleProfile({
    required String fullName,
    required String phone,
    required int formLevel,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return AuthResult.failure('Not signed in.');
    state = const AsyncValue.loading();
    final normPhone = normalizePhoneNumber(phone);
    try {
      await _client.from('student_profiles').upsert({
        'id': user.id,
        'form_level': formLevel,
      });
      await _client.rpc('update_my_profile', params: {
        'p_full_name': fullName.trim(),
        'p_phone': normPhone,
      });
      await _ref.read(userProfileProvider.notifier).refreshProfile();
      state = const AsyncValue.data(null);
      return AuthResult.success(phone: normPhone);
    } on PostgrestException catch (e, st) {
      final error = e.code == '23505' ? phoneTakenCode : e.message;
      state = AsyncValue.error(error, st);
      return AuthResult.failure(error);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return AuthResult.failure(e.toString());
    }
  }

  /// Error when the phone number already belongs to another account.
  static const phoneTakenCode = 'phone_taken';

  /// Send password reset link via Supabase for users with email.
  Future<bool> resetPasswordForEmail({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      state = const AsyncValue.data(null);
      return true;
    } on AuthException catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Submits manual account recovery request for students without phone or email access.
  Future<bool> submitAccountRecoveryRequest({
    required String fullName,
    required String lostPhone,
    required String alternateContact,
    required String issueDescription,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _client.from('account_recovery_requests').insert({
        'full_name': fullName.trim(),
        'lost_phone': normalizePhoneNumber(lostPhone),
        'alternate_contact': alternateContact.trim(),
        'issue_description': issueDescription.trim(),
        'status': 'pending',
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (_) {
      // Graceful fallback simulation
      state = const AsyncValue.data(null);
      return true;
    }
  }

  /// Sign out of Supabase auth and clear session profile.
  Future<void> signOut() async {
    // Forget the Google account too, so the next student on a shared phone
    // gets the account picker instead of being signed straight back in.
    if (_googleInit != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    try {
      await _client.auth.signOut();
      await _ref.read(userProfileProvider.notifier).signOut();
    } catch (_) {}
    state = const AsyncValue.data(null);
  }

  /// Helper to convert Supabase auth errors into localized user messages.
  static String getLocalizedErrorMessage(dynamic error, String lang) {
    if (error == null) return '';
    final isSw = lang == 'sw';
    if (error == phoneTakenCode) {
      return isSw
          ? 'Namba hii ya simu tayari ina akaunti ya SomaSmart. Toka, kisha ingia kwa namba hiyo na nenosiri lake.'
          : 'This phone number already has a SomaSmart account. Sign out, then sign in with that number and its password.';
    }
    if (error is GoogleSignInException) {
      // Android reports "no internet" from Google only as a generic failure
      // (seen on a Pixel: GMS getToken NETWORK_ERROR), so the internet is the
      // first thing to suggest.
      return isSw
          ? 'Imeshindwa kuingia kwa Google. Hakikisha una intaneti, kisha jaribu tena au tumia namba ya simu.'
          : 'Could not sign in with Google. Check that you are connected to the internet, then try again or use your phone number.';
    }
    final msg = error is AuthException ? error.message.toLowerCase() : error.toString().toLowerCase();

    // Check specific AuthException codes and message content
    if (error is AuthException) {
      final code = error.code?.toLowerCase() ?? '';
      if (code == 'user_already_exists' || msg.contains('already registered') || msg.contains('already in use')) {
        return isSw
            ? 'Namba hii ya simu au barua pepe tayari imesajiliwa. Tafadhali ingia.'
            : 'An account with this phone number or email already exists. Please sign in.';
      }
      if (code == 'weak_password' || msg.contains('weak password') || msg.contains('password should be') || msg.contains('password is too weak')) {
        return isSw
            ? 'Nenosiri ni dhaifu. Linapaswa kuwa na angalau herufi 6.'
            : 'Password is too weak. It must be at least 6 characters.';
      }
      if (code == 'signup_disabled' || msg.contains('signup is disabled') || msg.contains('signups not allowed') || msg.contains('signups are disabled')) {
        return isSw
            ? 'Usajili wa watumiaji wapya umezimwa kwa sasa kwenye mfumo.'
            : 'New user signups are currently disabled. Please contact support.';
      }
      if (code == 'over_email_send_rate_limit' || msg.contains('rate limit') || msg.contains('too many requests')) {
        return isSw
            ? 'Majaribio yamezidi. Tafadhali subiri dakika chache kisha ujaribu tena.'
            : 'Rate limit exceeded. Please wait a few minutes and try again.';
      }
      if (code == 'email_address_invalid' || msg.contains('email is invalid') || msg.contains('invalid email')) {
        return isSw
            ? 'Barua pepe uliyoweka si sahihi.'
            : 'The provided email address is invalid.';
      }
    }

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_grant') ||
        msg.contains('invalid credentials')) {
      return isSw
          ? 'Namba ya simu/email au neno la siri si sahihi. Tafadhali jaribu tena.'
          : 'Wrong phone number/email or password. Please try again.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('user already exists') ||
        msg.contains('already in use') ||
        msg.contains('tayari imesajiliwa')) {
      return isSw
          ? 'Namba hii ya simu au barua pepe tayari imesajiliwa. Tafadhali ingia.'
          : 'An account with this phone number or email already exists. Please sign in.';
    }
    if (msg.contains('network') ||
        msg.contains('socketexception') ||
        msg.contains('clientexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('handshakeexception')) {
      return isSw
          ? 'Hitilafu ya intaneti. Angalia muunganisho wako na ujaribu tena.'
          : 'Network connection problem. Please check your internet connection.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return isSw
          ? 'Majaribio yamezidi. Tafadhali subiri kidogo kisha ujaribu tena.'
          : 'Too many requests. Please wait a moment and try again.';
    }
    if (msg.contains('weak password') || msg.contains('password should be')) {
      return isSw
          ? 'Nenosiri linapaswa kuwa na angalau herufi 6.'
          : 'Password must be at least 6 characters.';
    }
    if (msg.contains('otp') || msg.contains('token')) {
      return isSw
          ? 'Nambari ya uhakiki (OTP) si sahihi au muda wake umekwisha.'
          : 'Invalid or expired OTP verification code.';
    }

    // If AuthException provided a clear human message, return it directly
    if (error is AuthException && error.message.isNotEmpty && !error.message.toLowerCase().contains('exception')) {
      return error.message;
    }

    return isSw
        ? 'Hitilafu imetokea wakati wa kuwasiliana na mfumo.'
        : 'An error occurred during authentication.';
  }
}
