import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/shop/domain/models/shop_models.dart';

void main() {
  group('Priority 8 — Shop, Subscription & Payment Logic Tests', () {
    test('Entitlement: Admin user has full premium access', () {
      const admin = UserProfile(
        id: 'admin_1',
        email: 'admin@somasmart.ac.tz',
        fullName: 'Admin User',
        phone: '+255700111222',
        role: 'admin',
        subscriptionStatus: 'free',
      );

      expect(admin.isPremium, isTrue);
      expect(admin.isExpired, isFalse);
    });

    test('Entitlement: Free access override grants full access', () {
      const freeUser = UserProfile(
        id: 'user_free',
        email: 'free@somasmart.ac.tz',
        fullName: 'Scholarship Student',
        phone: '+255700222333',
        role: 'student',
        subscriptionStatus: 'free',
        freeAccess: true,
      );

      expect(freeUser.isPremium, isTrue);
      expect(freeUser.isExpired, isFalse);
    });

    test('Entitlement: 6-day Free Trial is active within 6 days of signup', () {
      final recentUser = UserProfile(
        id: 'user_trial',
        email: 'trial@somasmart.ac.tz',
        fullName: 'New Student',
        phone: '+255700333444',
        role: 'student',
        subscriptionStatus: 'free',
        createdAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      );

      expect(recentUser.isPremium, isFalse);
      expect(recentUser.isTrialActive, isTrue);
      expect(recentUser.trialDaysLeft, inInclusiveRange(3, 5));
      expect(recentUser.isExpired, isFalse);
    });

    test('Entitlement: Free Trial is expired after 6 days without payment', () {
      final expiredUser = UserProfile(
        id: 'user_expired',
        email: 'expired@somasmart.ac.tz',
        fullName: 'Expired Student',
        phone: '+255700444555',
        role: 'student',
        subscriptionStatus: 'free',
        createdAt: DateTime.now().toUtc().subtract(const Duration(days: 8)),
      );

      expect(expiredUser.isPremium, isFalse);
      expect(expiredUser.isTrialActive, isFalse);
      expect(expiredUser.trialDaysLeft, 0);
      expect(expiredUser.isExpired, isTrue);
    });

    test('Entitlement: Paid subscription is valid when expires_at is in future', () {
      final paidUser = UserProfile(
        id: 'user_paid',
        email: 'paid@somasmart.ac.tz',
        fullName: 'Active Subscriber',
        phone: '+255700555666',
        role: 'student',
        subscriptionStatus: 'paid',
        subscriptionStartedAt: DateTime.now().toUtc().subtract(const Duration(days: 5)),
        subscriptionExpiresAt: DateTime.now().toUtc().add(const Duration(days: 25)),
      );

      expect(paidUser.isPremium, isTrue);
      expect(paidUser.isExpired, isFalse);
    });

    test('ShopItem: Deserialization and localized title/description formatting', () {
      final json = {
        'id': 'book_1',
        'title_en': 'Form 4 Chemistry Practical Manual',
        'title_sw': 'Mwongozo wa Vitendo Kemia Form 4',
        'desc_en': 'Complete step-by-step titration and analysis experiments.',
        'desc_sw': 'Majaribio yote ya titration hatua kwa hatua.',
        'category': 'Books',
        'price': 2500,
        'discount_price': 5000,
        'currency': 'TZS',
        'cover_image': 'https://example.com/cover.png',
        'stock_quantity': 50,
        'is_featured': true,
      };

      final item = ShopItem.fromJson(json, isPurchased: true);

      expect(item.id, 'book_1');
      expect(item.getTitle('sw'), 'Mwongozo wa Vitendo Kemia Form 4');
      expect(item.getTitle('en'), 'Form 4 Chemistry Practical Manual');
      expect(item.getDesc('sw'), 'Majaribio yote ya titration hatua kwa hatua.');
      expect(item.formattedPrice, 'TZS 2,500');
      expect(item.isFeatured, isTrue);
      expect(item.isPurchased, isTrue);
    });

    test('PaymentRecord: Deserialization and standard transaction reference format', () {
      final json = {
        'id': 'pay_123',
        'user_id': 'usr_456',
        'amount': 2500.0,
        'currency': 'TZS',
        'payment_method': 'mpesa',
        'payment_reference': 'TXN-847291',
        'status': 'pending',
        'type': 'subscription',
        'created_at': '2026-09-14T10:00:00Z',
      };

      final record = PaymentRecord.fromJson(json);

      expect(record.id, 'pay_123');
      expect(record.userId, 'usr_456');
      expect(record.amount, 2500.0);
      expect(record.paymentMethod, 'mpesa');
      expect(record.paymentReference, startsWith('TXN-'));
      expect(record.status, 'pending');
      expect(record.type, 'subscription');
    });

    test('MobileOperator: Correct mapping of operator codes', () {
      expect(MobileOperator.fromCode('mpesa'), MobileOperator.mpesa);
      expect(MobileOperator.fromCode('airtel'), MobileOperator.airtel);
      expect(MobileOperator.fromCode('tigopesa'), MobileOperator.tigo);
      expect(MobileOperator.fromCode('tigo'), MobileOperator.tigo);
      expect(MobileOperator.fromCode('yas'), MobileOperator.tigo);
    });
  });
}
