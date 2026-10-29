import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';

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

  /// Whether user has active paid premium subscription or admin or free access.
  bool get isPremium {
    if (role == 'admin') return true;
    if (freeAccess) return true;
    if (subscriptionStatus == 'paid') {
      if (subscriptionExpiresAt != null) {
        return subscriptionExpiresAt!.isAfter(DateTime.now().toUtc());
      }
      return true;
    }
    return false;
  }

  /// Days remaining on the active paid subscription until [subscriptionExpiresAt].
  /// Uses calendar-date difference in UTC.
  /// Never negative. If expiry is today or in the past, returns 0.
  int get subscriptionDaysRemaining {
    if (subscriptionExpiresAt == null) return 0;
    final now = DateTime.now().toUtc();
    if (subscriptionExpiresAt!.isBefore(now)) return 0;
    final expDate = DateTime.utc(
      subscriptionExpiresAt!.year,
      subscriptionExpiresAt!.month,
      subscriptionExpiresAt!.day,
    );
    final nowDate = DateTime.utc(
      now.year,
      now.month,
      now.day,
    );
    final diffDays = expDate.difference(nowDate).inDays;
    return diffDays < 0 ? 0 : diffDays;
  }

  /// Whether user is within the 6-day free trial period from account creation.
  bool get isTrialActive {
    if (isPremium) return false;
    if (createdAt == null) return false;
    final now = DateTime.now().toUtc();
    final trialDuration = const Duration(days: 6);
    final elapsed = now.difference(createdAt!);
    return elapsed >= Duration.zero && elapsed < trialDuration;
  }

  /// Days remaining on the 6-day trial.
  int get trialDaysLeft {
    if (createdAt == null) return 0;
    final now = DateTime.now().toUtc();
    final trialEnd = createdAt!.add(const Duration(days: 6));
    final diff = trialEnd.difference(now);
    if (diff.isNegative) return 0;
    // Part of a day still counts as a day: 6 at sign-up, 1 on the last day
    // (inDays + 1 showed 7 for a brand-new account).
    return (diff.inMicroseconds / Duration.microsecondsPerDay).ceil();
  }

  /// Whether the user's trial and subscription are both expired/locked.
  bool get isExpired => !isPremium && !isTrialActive;

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
        subscriptionStatus: 'trial',
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
      return UserProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: 'User',
        phone: '',
        role: 'student',
        subscriptionStatus: 'free',
        formLevel: 4,
      );
    }
  }

  /// Forces a fresh reload of the authenticated profile from Supabase.
  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _fetchProfile());
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

  /// Signs out from Supabase auth.
  Future<void> signOut() async {
    final client = ref.read(supabaseClientProvider);
    await client.auth.signOut();
    state = const AsyncValue.data(null);
  }
}
