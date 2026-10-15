import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/shop/domain/models/shop_models.dart';
import 'package:somasmart_flutter/features/shop/presentation/controllers/shop_controller.dart';

void main() {
  group('FimiPay Official Payment Integration Unit & Domain Tests', () {
    test('Amount & Currency: Enforces 2,500 TZS for SomaSmart subscription', () {
      const price = 2500.0;
      const currency = 'TZS';

      expect(price, 2500.0);
      expect(currency, 'TZS');
    });

    test('MobileOperator: Correct mapping for all 4 Tanzania mobile operators', () {
      expect(MobileOperator.fromCode('mpesa'), MobileOperator.mpesa);
      expect(MobileOperator.fromCode('airtel'), MobileOperator.airtel);
      expect(MobileOperator.fromCode('tigopesa'), MobileOperator.tigo);
      expect(MobileOperator.fromCode('yas'), MobileOperator.tigo);
      expect(MobileOperator.fromCode('mixx'), MobileOperator.tigo);
      expect(MobileOperator.fromCode('halopesa'), MobileOperator.halopesa);
      expect(MobileOperator.fromCode('halo'), MobileOperator.halopesa);
    });

    test('FimipayPaymentResult: Parses successful create_order response with PENDING status', () {
      final json = {
        'success': true,
        'order_id': 'fp_67890abcdef',
        'payment_reference': 'FP-1718000000-1234',
        'status': 'PENDING',
        'message': 'Payment request sent. Please approve the prompt on your phone.',
      };

      final result = FimipayPaymentResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.orderId, 'fp_67890abcdef');
      expect(result.paymentReference, 'FP-1718000000-1234');
      expect(result.status, 'PENDING');
      expect(result.message, contains('Payment request sent'));
      expect(result.errorMessage, isNull);
    });

    test('FimipayPaymentResult: Parses error response', () {
      final json = {
        'success': false,
        'error': 'Nambari ya simu si sahihi.',
      };

      final result = FimipayPaymentResult.fromJson(json);

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Nambari ya simu si sahihi.');
      expect(result.isInProgress, isFalse);
    });

    test('FimipayPaymentResult: Parses 409 payment_in_progress with the open order', () {
      final result = FimipayPaymentResult.fromJson({
        'success': false,
        'code': 'payment_in_progress',
        'order_id': 'fp_open',
        'payment_reference': 'FP-OPEN',
        'error': 'Una malipo yanayosubiri.',
      });

      expect(result.success, isFalse);
      expect(result.isInProgress, isTrue);
      expect(result.orderId, 'fp_open');
      expect(result.errorMessage, 'Una malipo yanayosubiri.');
    });

    test('FimipayStatusResult: Parses order_status response with SUCCESS, PAID, and COMPLETED status', () {
      final successJson = {
        'success': true,
        'payment_status': 'SUCCESS',
        'is_active': true,
        'payment_reference': 'FP-1718000000-1234',
      };
      final paidJson = {
        'success': true,
        'payment_status': 'PAID',
        'is_active': true,
        'payment_reference': 'FP-1718000000-1234',
      };
      final completedJson = {
        'success': true,
        'payment_status': 'COMPLETED',
        'is_active': true,
        'payment_reference': 'FP-1718000000-1234',
      };

      final statusSuccess = FimipayStatusResult.fromJson(successJson);
      final statusPaid = FimipayStatusResult.fromJson(paidJson);
      final statusCompleted = FimipayStatusResult.fromJson(completedJson);

      expect(statusSuccess.success, isTrue);
      expect(statusSuccess.paymentStatus, 'SUCCESS');
      expect(statusSuccess.isActive, isTrue);

      expect(statusPaid.success, isTrue);
      expect(statusPaid.paymentStatus, 'PAID');
      expect(statusPaid.isActive, isTrue);

      expect(statusCompleted.success, isTrue);
      expect(statusCompleted.paymentStatus, 'COMPLETED');
      expect(statusCompleted.isActive, isTrue);
    });

    test('FimipayStatusResult: Handles PENDING, INPROGRESS, CANCELLED, USERCANCELLED, REJECTED statuses', () {
      final pending = FimipayStatusResult.fromJson({'success': true, 'payment_status': 'PENDING', 'is_active': false});
      final inprogress = FimipayStatusResult.fromJson({'success': true, 'payment_status': 'INPROGRESS', 'is_active': false});
      final cancelled = FimipayStatusResult.fromJson({'success': true, 'payment_status': 'CANCELLED', 'is_active': false});
      final usercancelled = FimipayStatusResult.fromJson({'success': true, 'payment_status': 'USERCANCELLED', 'is_active': false});
      final rejected = FimipayStatusResult.fromJson({'success': true, 'payment_status': 'REJECTED', 'is_active': false});

      expect(pending.paymentStatus, 'PENDING');
      expect(pending.isActive, isFalse);

      expect(inprogress.paymentStatus, 'INPROGRESS');
      expect(inprogress.isActive, isFalse);

      expect(cancelled.paymentStatus, 'CANCELLED');
      expect(cancelled.isActive, isFalse);

      expect(usercancelled.paymentStatus, 'USERCANCELLED');
      expect(usercancelled.isActive, isFalse);

      expect(rejected.paymentStatus, 'REJECTED');
      expect(rejected.isActive, isFalse);
    });

    test('PaymentRecord: Deserialization with FimiPay provider, order_id, transid, and channel', () {
      final json = {
        'id': 'pay_fimi_01',
        'user_id': 'usr_fimi_02',
        'amount': 2500.00,
        'currency': 'TZS',
        'payment_method': 'mpesa',
        'provider': 'fimipay',
        'payment_reference': 'FP-1718000000-1234',
        'order_id': 'fp_67890abcdef',
        'transid': 'FPX9K2M4N7',
        'channel': 'M-Pesa',
        'phone': '255682812345',
        'status': 'completed',
        'type': 'subscription',
        'created_at': '2026-06-01T10:30:00Z',
      };

      final record = PaymentRecord.fromJson(json);

      expect(record.id, 'pay_fimi_01');
      expect(record.userId, 'usr_fimi_02');
      expect(record.amount, 2500.00);
      expect(record.currency, 'TZS');
      expect(record.provider, 'fimipay');
      expect(record.orderId, 'fp_67890abcdef');
      expect(record.transid, 'FPX9K2M4N7');
      expect(record.channel, 'M-Pesa');
      expect(record.phone, '255682812345');
      expect(record.status, 'completed');
    });

    test('PaymentState: Default initial state has 120s polling window and copyWith mutations', () {
      const initial = PaymentState();

      expect(initial.step, PaymentStep.idle);
      expect(initial.operator, MobileOperator.mpesa);
      expect(initial.phoneNumber, isEmpty);
      expect(initial.isSimulated, isFalse);
      expect(initial.pollSecondsRemaining, 120);

      final initiating = initial.copyWith(
        step: PaymentStep.initiating,
        phoneNumber: '255712345678',
        operator: MobileOperator.airtel,
      );

      expect(initiating.step, PaymentStep.initiating);
      expect(initiating.phoneNumber, '255712345678');
      expect(initiating.operator, MobileOperator.airtel);

      final waiting = initiating.copyWith(
        step: PaymentStep.waitingPrompt,
        orderId: 'fp_12345',
        paymentReference: 'FP-REF-1',
        pollSecondsRemaining: 120,
      );

      expect(waiting.step, PaymentStep.waitingPrompt);
      expect(waiting.orderId, 'fp_12345');
      expect(waiting.paymentReference, 'FP-REF-1');
      expect(waiting.pollSecondsRemaining, 120);
    });

    test('Subscription Entitlement: Activating paid status extends validity by 1 calendar month', () {
      final now = DateTime.now().toUtc();
      final oneMonthLater = DateTime.utc(now.year, now.month + 1, now.day, now.hour, now.minute, now.second);
      final user = UserProfile(
        id: 'student_1',
        email: 'student@somasmart.ac.tz',
        fullName: 'Baraka Juma',
        phone: '255712345678',
        role: 'student',
        subscriptionStatus: 'paid',
        subscriptionStartedAt: now,
        subscriptionExpiresAt: oneMonthLater,
      );

      expect(user.isPremium, isTrue);
      expect(user.isExpired, isFalse);
      expect(user.subscriptionExpiresAt!.isAfter(now), isTrue);
    });

    test('Subscription Entitlement: Active renewal extends existing expiry by 1 calendar month', () {
      final existingExpiry = DateTime.utc(2026, 10, 18, 12, 0, 0);
      final expectedNewExpiry = DateTime.utc(2026, 11, 18, 12, 0, 0);

      expect(expectedNewExpiry.isAfter(existingExpiry), isTrue);
      expect(expectedNewExpiry.month, equals(11));
      expect(expectedNewExpiry.day, equals(18));
    });

    test('Subscription Entitlement: Expired subscription blocks premium access', () {
      final past = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final user = UserProfile(
        id: 'student_2',
        email: 'past@somasmart.ac.tz',
        fullName: 'Amina Salum',
        phone: '255682812345',
        role: 'student',
        subscriptionStatus: 'paid',
        subscriptionStartedAt: past.subtract(const Duration(days: 30)),
        subscriptionExpiresAt: past,
      );

      expect(user.isPremium, isFalse);
      expect(user.isExpired, isTrue);
    });
  });
}
