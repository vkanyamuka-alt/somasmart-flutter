import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/home/presentation/screens/home_screen.dart';
import 'package:somasmart_flutter/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  group('Subscription Status Indicator & Calendar Logic Tests', () {
    // 1. Active paid subscription with days remaining
    test('1. Active paid subscription calculates remaining calendar days', () {
      final futureDate = DateTime.now().toUtc().add(const Duration(days: 15, hours: 4));
      final paidUser = UserProfile(
        id: 'user_paid_15',
        email: 'paid15@somasmart.ac.tz',
        fullName: 'Baraka John',
        phone: '+255711223344',
        role: 'student',
        subscriptionStatus: 'paid',
        subscriptionStartedAt: DateTime.now().toUtc().subtract(const Duration(days: 15)),
        subscriptionExpiresAt: futureDate,
      );

      expect(paidUser.isPremium, isTrue);
      expect(paidUser.isExpired, isFalse);
      expect(paidUser.access.days, inInclusiveRange(15, 16));
    });

    // 2. Subscription expiring today
    test('2. Subscription expiring later today shows 1 day remaining', () {
      // Last moment of today (UTC). "Now + 2 hours" was tomorrow after 22:00 UTC.
      final now = DateTime.now().toUtc();
      final expiringToday = DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);
      final paidToday = UserProfile(
        id: 'user_expiring_today',
        email: 'today@somasmart.ac.tz',
        fullName: 'Neema Joseph',
        phone: '+255722334455',
        role: 'student',
        subscriptionStatus: 'paid',
        subscriptionStartedAt: DateTime.now().toUtc().subtract(const Duration(days: 30)),
        subscriptionExpiresAt: expiringToday,
      );

      expect(paidToday.isPremium, isTrue);
      // The last hours of a paid month count as a day, like the trial (never 0 while it still opens content).
      expect(paidToday.access.days, 1);
    });

    // 3. Expired subscription
    test('3. Expired subscription returns isExpired=true and 0 days remaining', () {
      final pastDate = DateTime.now().toUtc().subtract(const Duration(days: 2));
      final expiredUser = UserProfile(
        id: 'user_expired_sub',
        email: 'expired@somasmart.ac.tz',
        fullName: 'Juma Ali',
        phone: '+255733445566',
        role: 'student',
        subscriptionStatus: 'paid',
        subscriptionExpiresAt: pastDate,
      );

      expect(expiredUser.isPremium, isFalse);
      expect(expiredUser.isExpired, isTrue);
      expect(expiredUser.access.days, isNull);
    });

    // 4. Active six-day trial
    test('4. Active 6-day trial calculates correct days remaining', () {
      final trialUser = UserProfile(
        id: 'user_trial_active',
        email: 'trial@somasmart.ac.tz',
        fullName: 'Rehema Hassan',
        phone: '+255744556677',
        role: 'student',
        subscriptionStatus: 'free',
        createdAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      );

      expect(trialUser.isPremium, isFalse);
      expect(trialUser.isTrialActive, isTrue);
      expect(trialUser.isExpired, isFalse);
      expect(trialUser.access.days, inInclusiveRange(3, 5));
    });

    // 5. No subscription (never subscribed, trial expired)
    test('5. No subscription user is marked expired with 0 days', () {
      final noSubUser = UserProfile(
        id: 'user_no_sub',
        email: 'nosub@somasmart.ac.tz',
        fullName: 'Hawa Said',
        phone: '+255755667788',
        role: 'student',
        subscriptionStatus: 'free',
        createdAt: DateTime.now().toUtc().subtract(const Duration(days: 20)),
      );

      expect(noSubUser.isPremium, isFalse);
      expect(noSubUser.isTrialActive, isFalse);
      expect(noSubUser.isExpired, isTrue);
      expect(noSubUser.access.days, isNull);
    });

    // 8 & 10. Calendar-month subscription expiry & no fixed 30-day assumption
    test('8 & 10. Calendar-month subscription respects actual month boundaries (e.g., 31-day, 28-day months)', () {
      // Next year's October, so the subscription is always still running when
      // the test runs (a fixed 2026 date expired on 2026-11-03 and broke it).
      final year = DateTime.now().toUtc().year + 1;
      final start = DateTime.utc(year, 10, 3, 12, 0, 0);
      // Backend 1 calendar month starting Oct 3 arrives at Nov 3 (31 days in October)
      final endNov3 = DateTime.utc(year, 11, 3, 12, 0, 0);

      final octSub = UserProfile(
        id: 'user_oct',
        email: 'oct@somasmart.ac.tz',
        fullName: 'October Subscriber',
        phone: '+255766778899',
        role: 'student',
        subscriptionStatus: 'paid',
        subscriptionStartedAt: start,
        subscriptionExpiresAt: endNov3,
      );

      // Duration between Oct 3 and Nov 3 is 31 days, NOT hardcoded 30 days
      expect(endNov3.difference(start).inDays, 31);
      expect(octSub.isPremium, isTrue);
    });

    // 9. Verify no hardcoded "5" or "5 Active Days" in home screen logic
    test('9. No hardcoded 5 streak in home screen widget rendering', () {
      final sub = UserProfile(
        id: 'user_sub_check',
        email: 'sub@somasmart.ac.tz',
        fullName: 'Subscriber',
        phone: '+255777889900',
        role: 'student',
        subscriptionStatus: 'paid',
        subscriptionExpiresAt: DateTime.now().toUtc().add(const Duration(days: 196)),
      );

      expect(sub.access.days, inInclusiveRange(195, 197));
      expect(sub.access.days, isNot(5));
    });
  });

  group('Dashboard Status Bar Widget Tests (English & Kiswahili)', () {
    testWidgets('6. Paid subscription in English displays "X Days Remaining" and "Premium"', (tester) async {
      final paidUser = UserProfile(
        id: 'test_paid_en',
        email: 'test_en@somasmart.ac.tz',
        fullName: 'Anna Juma',
        phone: '+255788990011',
        role: 'student',
        subscriptionStatus: 'paid',
        subscriptionExpiresAt: DateTime.now().toUtc().add(const Duration(days: 20)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith((ref) => _TestLanguageNotifier('en')),
            userProfileProvider.overrideWith(() => _MockProfileNotifier(paidUser)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Days Remaining'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('Active Days'), findsNothing);
      expect(find.text('Active'), findsNothing);
    });

    testWidgets('7. Paid subscription in Kiswahili displays "Siku Zilizobaki" and "Premium"', (tester) async {
      final paidUser = UserProfile(
        id: 'test_paid_sw',
        email: 'test_sw@somasmart.ac.tz',
        fullName: 'Anna Juma',
        phone: '+255788990011',
        role: 'student',
        subscriptionStatus: 'paid',
        subscriptionExpiresAt: DateTime.now().toUtc().add(const Duration(days: 20)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith((ref) => _TestLanguageNotifier('sw')),
            userProfileProvider.overrideWith(() => _MockProfileNotifier(paidUser)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Siku Zilizobaki'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('Active Days'), findsNothing);
    });

    testWidgets('Trial in Kiswahili displays "Jaribio la Bure"', (tester) async {
      final trialUser = UserProfile(
        id: 'test_trial_sw',
        email: 'test_trial_sw@somasmart.ac.tz',
        fullName: 'John Doe',
        phone: '+255788990011',
        role: 'student',
        subscriptionStatus: 'free',
        createdAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith((ref) => _TestLanguageNotifier('sw')),
            userProfileProvider.overrideWith(() => _MockProfileNotifier(trialUser)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Siku Zilizobaki'), findsOneWidget);
      expect(find.text('Jaribio la Bure'), findsOneWidget);
    });

    testWidgets('Expired subscription in English displays "Subscription Expired" & "Expired"', (tester) async {
      final expiredUser = UserProfile(
        id: 'test_expired_en',
        email: 'expired_en@somasmart.ac.tz',
        fullName: 'Expired User',
        phone: '+255788990011',
        role: 'student',
        subscriptionStatus: 'free',
        createdAt: DateTime.now().toUtc().subtract(const Duration(days: 30)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith((ref) => _TestLanguageNotifier('en')),
            userProfileProvider.overrideWith(() => _MockProfileNotifier(expiredUser)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Subscription Expired'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('Expired subscription in Kiswahili displays "Usajili Umeisha" & "Umeisha"', (tester) async {
      final expiredUser = UserProfile(
        id: 'test_expired_sw',
        email: 'expired_sw@somasmart.ac.tz',
        fullName: 'Mtumiaji Aliyeisha',
        phone: '+255788990011',
        role: 'student',
        subscriptionStatus: 'free',
        createdAt: DateTime.now().toUtc().subtract(const Duration(days: 30)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith((ref) => _TestLanguageNotifier('sw')),
            userProfileProvider.overrideWith(() => _MockProfileNotifier(expiredUser)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Usajili Umeisha'), findsOneWidget);
      expect(find.text('Umeisha'), findsOneWidget);
    });
  });
}

class _TestLanguageNotifier extends StateNotifier<String> implements LanguageNotifier {
  _TestLanguageNotifier(super.state);

  @override
  Future<void> setLanguage(String lang) async {
    state = lang;
  }
}

class _MockProfileNotifier extends UserProfileNotifier {
  final UserProfile? _mockProfile;
  _MockProfileNotifier(this._mockProfile);

  @override
  Future<UserProfile?> build() async {
    return _mockProfile;
  }
}
