import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/push/push_providers.dart';
import '../../../settings/data/study_reminder.dart';

/// User Profile model matching Supabase `profiles` & `student_profiles` tables.
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role;
  final String subscriptionStatus;
  final bool freeAccess;
  final bool isVerified;
  final DateTime? subscriptionStartedAt;
  final DateTime? subscriptionExpiresAt;
  final int formLevel;
  final String stream;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.subscriptionStatus,
    this.freeAccess = false,
    this.isVerified = true,
    this.subscriptionStartedAt,
    this.subscriptionExpiresAt,
    this.formLevel = 1,
    this.stream = 'none',
    this.createdAt,
  });

  factory UserProfile.fromSupabase(
    Map<String, dynamic> profileMap,
    Map<String, dynamic>? studentProfileMap,
  ) {
    final freeAcc = profileMap['free_access'] == true ||
        profileMap['free_access']?.toString() == 'true';
    final isVer = profileMap['is_verified'] == true ||
        profileMap['is_verified']?.toString() == 'true' ||
        profileMap['is_verified'] == null;

    return UserProfile(
      id: profileMap['id'] as String? ?? '',
      email: profileMap['email'] as String? ?? '',
      fullName: profileMap['full_name'] as String? ?? 'User',
      phone: profileMap['phone'] as String? ?? '',
      role: profileMap['role'] as String? ?? 'student',
      subscriptionStatus: profileMap['subscription_status'] as String? ?? 'free',
      freeAccess: freeAcc,
      isVerified: isVer,
      subscriptionStartedAt: profileMap['subscription_started_at'] != null
          ? DateTime.tryParse(profileMap['subscription_started_at'] as String)
          : null,
      subscriptionExpiresAt: profileMap['subscription_expires_at'] != null
          ? DateTime.tryParse(profileMap['subscription_expires_at'] as String)
          : null,
      formLevel: (studentProfileMap?['form_level'] as num?)?.toInt() ?? 4,
      stream: studentProfileMap?['stream'] as String? ?? 'none',
      createdAt: profileMap['created_at'] != null
          ? DateTime.tryParse(profileMap['created_at'] as String)
          : null,
    );
  }

  /// The one access rule, a copy of the database function
  /// public.has_active_subscription (what the server lets a student open):
  /// admin, free access from an admin, a paid month that has not ended, or the
  /// first 6 days after the account was created. The expiry date is set only
  /// by a payment; sign-up sets none, so the trial always comes from createdAt.
  ///
  /// The website has the same rule in src/lib/accessStatus.js; both are tested
  /// against test/fixtures/access_status_cases.json (= the website's
  /// src/lib/accessStatusCases.json, keep in step).
  AccessStatus accessAt(DateTime now) {
    if (role == 'admin' || freeAccess) return const AccessStatus(AccessKind.paid);

    final expiresAt = subscriptionExpiresAt;
    if (subscriptionStatus == 'paid' && expiresAt != null && expiresAt.isAfter(now)) {
      return AccessStatus(AccessKind.paid, days: _daysUntil(expiresAt, now), endsAt: expiresAt);
    }

    final created = createdAt;
    if (created != null) {
      final trialEnd = created.add(const Duration(days: trialDays));
      // Like the server (now - created_at < 6 days): a phone clock that runs
      // behind still gets the trial, never more than 6 days.
      if (now.isBefore(trialEnd)) {
        final days = _daysUntil(trialEnd, now);
        return AccessStatus(AccessKind.trial, days: days > trialDays ? trialDays : days, endsAt: trialEnd);
      }
    }
    return const AccessStatus(AccessKind.expired);
  }

  static const int trialDays = 6;

  /// Part of a day still counts as a day: 6 at sign-up, 1 on the last day.
  static int _daysUntil(DateTime end, DateTime now) =>
      (end.difference(now).inMicroseconds / Duration.microsecondsPerDay).ceil();

  AccessStatus get access => accessAt(DateTime.now().toUtc());

  /// May the student open premium content (notes, quizzes, lab, forum, Ask Me).
  bool get hasAccess => access.kind != AccessKind.expired;

  /// Paid month running, admin or free access.
  bool get isPremium => access.kind == AccessKind.paid;

  /// In the 6-day free trial (and not paid).
  bool get isTrialActive => access.kind == AccessKind.trial;

  /// Neither paid nor in the trial: content is locked.
  bool get isExpired => access.kind == AccessKind.expired;

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? role,
    String? subscriptionStatus,
    bool? freeAccess,
    bool? isVerified,
    DateTime? subscriptionStartedAt,
    DateTime? subscriptionExpiresAt,
    int? formLevel,
    String? stream,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      freeAccess: freeAccess ?? this.freeAccess,
      isVerified: isVerified ?? this.isVerified,
      subscriptionStartedAt: subscriptionStartedAt ?? this.subscriptionStartedAt,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      formLevel: formLevel ?? this.formLevel,
      stream: stream ?? this.stream,
      createdAt: createdAt,
    );
  }
}

enum AccessKind { paid, trial, expired }

/// Result of [UserProfile.accessAt]. [days] and [endsAt] are null for admins
/// and free access (no end) and when expired.
class AccessStatus {
  final AccessKind kind;
  final int? days;
  final DateTime? endsAt;

  const AccessStatus(this.kind, {this.days, this.endsAt});
}

/// Provider for fetching and managing current user profile.
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(() {
  return UserProfileNotifier();
});

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    return _fetchProfile();
  }

  Future<UserProfile?> _fetchProfile() async {
    final client = ref.watch(supabaseClientProvider);
    final user = client.auth.currentUser;

    if (user == null) {
      // Default fallback profile for guest/demo browsing
      return const UserProfile(
        id: 'guest',
        email: 'student@somasmart.ac.tz',
        fullName: 'Mwanafunzi SomaSmart',
        phone: '+255 700 000 000',
        role: 'student',
        subscriptionStatus: 'free',
        formLevel: 4,
      );
    }

    try {
      final profileRes = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileRes == null) {
        return UserProfile(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] as String? ??
              user.email?.split('@').first ??
              'User',
          phone: user.phone ?? '',
          role: 'student',
          subscriptionStatus: 'free',
          formLevel: 4,
        );
      }

      Map<String, dynamic>? studentRes;
      try {
        studentRes = await client
            .from('student_profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
      } catch (_) {}

      return UserProfile.fromSupabase(profileRes, studentRes);
    } catch (e) {
      // No made-up profile: it had no sign-up date, so a slow or failed load
      // (no internet) showed "Usajili Umeisha" to students in their trial or
      // paid month. The error reaches the screens, which show nothing or Retry.
      debugPrint('Profile load failed: $e');
      rethrow;
    }
  }

  /// Forces a fresh reload of the authenticated profile from Supabase.
  /// Screens keep the last profile while it reloads (and if the reload
  /// fails), so the home card does not flash "Usajili Umeisha".
  Future<void> refreshProfile() async {
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final previous = state.valueOrNull?.id == uid ? state : const AsyncData<UserProfile?>(null);
    state = const AsyncLoading<UserProfile?>().copyWithPrevious(previous);
    final next = await AsyncValue.guard(() async => await _fetchProfile());
    state = next.hasError ? next.copyWithPrevious(previous) : next;
  }

  /// Updates profile name and phone in Supabase and local state.
  Future<bool> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;

    final current = state.value;
    if (current == null) return false;

    state = const AsyncValue.loading();
    try {
      if (user != null) {
        await client.from('profiles').update({
          'full_name': fullName.trim(),
          'phone': phone.trim(),
        }).eq('id', user.id);
      }

      final updated = current.copyWith(
        fullName: fullName.trim(),
        phone: phone.trim(),
      );
      state = AsyncValue.data(updated);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Signs out from Supabase auth. This phone's push token is removed first,
  /// while the session can still delete it.
  Future<void> signOut() async {
    await unregisterPushBeforeSignOut(ref);
    final client = ref.read(supabaseClientProvider);
    await client.auth.signOut();
    ref.invalidate(studyReminderProvider);
    state = const AsyncValue.data(null);
  }
}
