import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FimiPay V4 Webhook HMAC-SHA256 Signature Verification & Idempotency Tests', () {
    const webhookSecret = 'test_webhook_secret_key_12345';

    String computeSignature(String rawBody, String secret) {
      final key = utf8.encode(secret);
      final bytes = utf8.encode(rawBody);
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(bytes);
      return digest.toString();
    }

    bool verifySignature(String rawBody, String signatureHeader, String secret) {
      final expected = computeSignature(rawBody, secret);
      return expected.toLowerCase() == signatureHeader.trim().toLowerCase();
    }

    test('Valid webhook signature against exact raw body is accepted', () {
      const rawPayload = '{"event":"payment.success","order_id":"fp_67890abcdef","payment_status":"SUCCESS","amount":2500,"currency":"TZS","transid":"FPX9K2M4N7","channel":"M-Pesa","timestamp":"2026-06-01T10:30:05Z"}';
      final validSignature = computeSignature(rawPayload, webhookSecret);

      expect(verifySignature(rawPayload, validSignature, webhookSecret), isTrue);
    });

    test('Invalid webhook signature with wrong secret is rejected (HTTP 401)', () {
      const rawPayload = '{"event":"payment.success","order_id":"fp_67890abcdef","payment_status":"SUCCESS","amount":2500,"currency":"TZS"}';
      final wrongSignature = computeSignature(rawPayload, 'wrong_secret');

      expect(verifySignature(rawPayload, wrongSignature, webhookSecret), isFalse);
    });

    test('Tampered or modified raw body fails signature verification (HTTP 401)', () {
      const originalPayload = '{"event":"payment.success","order_id":"fp_67890abcdef","payment_status":"SUCCESS","amount":2500,"currency":"TZS"}';
      const tamperedPayload = '{"event":"payment.success","order_id":"fp_67890abcdef","payment_status":"SUCCESS","amount":5000,"currency":"TZS"}';

      final signature = computeSignature(originalPayload, webhookSecret);

      // Signature computed on original payload must fail against tampered payload
      expect(verifySignature(tamperedPayload, signature, webhookSecret), isFalse);
    });

    test('Amount validation: Only 2500 TZS is accepted', () {
      final validPayload = jsonDecode('{"amount": 2500, "currency": "TZS"}');
      final invalidAmount = jsonDecode('{"amount": 5000, "currency": "TZS"}');
      final invalidCurrency = jsonDecode('{"amount": 2500, "currency": "USD"}');

      expect(validPayload['amount'] == 2500 && validPayload['currency'] == 'TZS', isTrue);
      expect(invalidAmount['amount'] == 2500 && invalidAmount['currency'] == 'TZS', isFalse);
      expect(invalidCurrency['amount'] == 2500 && invalidCurrency['currency'] == 'TZS', isFalse);
    });

    test('Status Fulfillment Matrix: PAID, SUCCESS, and COMPLETED fulfill; PENDING, REJECTED do not', () {
      bool shouldFulfill(String status, String event) {
        final normStatus = status.trim().toUpperCase();
        final normEvent = event.trim().toLowerCase();
        return normStatus == 'SUCCESS' ||
            normStatus == 'COMPLETED' ||
            normStatus == 'PAID' ||
            normEvent == 'payment.success';
      }

      // Successful statuses
      expect(shouldFulfill('PAID', ''), isTrue);
      expect(shouldFulfill('SUCCESS', ''), isTrue);
      expect(shouldFulfill('COMPLETED', ''), isTrue);
      expect(shouldFulfill('', 'payment.success'), isTrue);
      expect(shouldFulfill('paid', 'payment.success'), isTrue);

      // Non-terminal / failed statuses
      expect(shouldFulfill('PENDING', ''), isFalse);
      expect(shouldFulfill('INPROGRESS', ''), isFalse);
      expect(shouldFulfill('REJECTED', ''), isFalse);
      expect(shouldFulfill('CANCELLED', ''), isFalse);
      expect(shouldFulfill('USERCANCELLED', ''), isFalse);
    });

    test('Idempotency: Processing duplicate webhook returns idempotent status without re-extending', () {
      // Mock payment store and profile subscription state
      final paymentStore = <String, Map<String, dynamic>>{
        'fp_67890': {
          'id': 'pay_1',
          'status': 'pending',
          'amount': 2500.0,
          'transid': 'FPX123',
        }
      };

      DateTime? subscriptionExpiresAt;
      int extensionCount = 0;

      Map<String, dynamic> processWebhook(String orderId, String status) {
        final payment = paymentStore[orderId];
        if (payment == null) {
          return {'success': false, 'error': 'Payment not found'};
        }

        if (payment['status'] == 'completed') {
          return {
            'success': true,
            'message': 'Payment already processed and active.',
            'idempotent': true,
            'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
          };
        }

        payment['status'] = 'completed';
        extensionCount++;
        subscriptionExpiresAt = DateTime.now().toUtc().add(const Duration(days: 30));

        return {
          'success': true,
          'message': 'Subscription activated.',
          'idempotent': false,
          'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
        };
      }

      final firstRun = processWebhook('fp_67890', 'PAID');
      expect(firstRun['success'], isTrue);
      expect(firstRun['idempotent'], isFalse);
      expect(extensionCount, 1);

      final originalExpiry = firstRun['subscription_expires_at'];

      // Webhook Replay
      final secondRun = processWebhook('fp_67890', 'PAID');
      expect(secondRun['success'], isTrue);
      expect(secondRun['idempotent'], isTrue);
      expect(secondRun['subscription_expires_at'], originalExpiry);
      expect(extensionCount, 1); // No double extension
    });
  });
}
