import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/shop/data/repositories/shop_repository.dart';
import 'package:somasmart_flutter/features/shop/domain/models/shop_models.dart';
import 'package:somasmart_flutter/features/shop/presentation/controllers/shop_controller.dart';

/// Stands in for the fimipay-* Edge Functions.
class _FakeShopRepository implements ShopRepository {
  FimipayPaymentResult createResult;

  /// Answers from fimipay-check-status, in order; the last one repeats.
  List<FimipayStatusResult> statuses;
  int statusCalls = 0;

  _FakeShopRepository({required this.createResult, required this.statuses});

  @override
  Future<FimipayPaymentResult> initiateFimipayPayment({
    required String phone,
    required String operator,
  }) async =>
      createResult;

  @override
  Future<FimipayStatusResult> checkFimipayPaymentStatus({required String orderId}) async {
    final i = statusCalls < statuses.length ? statusCalls : statuses.length - 1;
    statusCalls++;
    return statuses[i];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileNotifier extends UserProfileNotifier {
  int refreshes = 0;

  @override
  Future<UserProfile?> build() async => null;

  @override
  Future<void> refreshProfile() async => refreshes++;
}

FimipayStatusResult _status(String paymentStatus, {bool isActive = false}) =>
    FimipayStatusResult(success: true, paymentStatus: paymentStatus, isActive: isActive);

const _created = FimipayPaymentResult(
  success: true,
  orderId: 'fp_order_1',
  paymentReference: 'FP-REF-1',
  status: 'PENDING',
);

void main() {
  late _FakeShopRepository repo;
  late _FakeProfileNotifier profile;
  late ProviderContainer container;
  late AutoDisposeStateNotifierProvider<PaymentController, PaymentState> provider;

  PaymentController setUpController({
    required FimipayPaymentResult createResult,
    required List<FimipayStatusResult> statuses,
    int pollWindowSeconds = 120,
  }) {
    repo = _FakeShopRepository(createResult: createResult, statuses: statuses);
    profile = _FakeProfileNotifier();
    provider = StateNotifierProvider.autoDispose<PaymentController, PaymentState>(
      (ref) => PaymentController(repo, ref, pollWindowSeconds: pollWindowSeconds),
    );
    container = ProviderContainer(overrides: [
      userProfileProvider.overrideWith(() => profile),
    ]);
    container.listen(provider, (_, _) {});
    return container.read(provider.notifier)
      ..setPhoneNumber('0712345678')
      ..setOperator(MobileOperator.tigo);
  }

  PaymentState current() => container.read(provider);

  group('paymentStepForStatus', () {
    test('only SUCCESS / COMPLETED / PAID mean paid', () {
      expect(paymentStepForStatus('SUCCESS'), PaymentStep.success);
      expect(paymentStepForStatus('completed'), PaymentStep.success);
      expect(paymentStepForStatus('PAID'), PaymentStep.success);
      expect(paymentStepForStatus('CANCELLED'), PaymentStep.cancelled);
      expect(paymentStepForStatus('USERCANCELLED'), PaymentStep.cancelled);
      expect(paymentStepForStatus('REJECTED'), PaymentStep.rejected);
      expect(paymentStepForStatus('FAILED'), PaymentStep.failed);
      expect(paymentStepForStatus('NOT_FOUND'), PaymentStep.failed);
      for (final pending in ['PENDING', 'INPROGRESS', 'UNKNOWN', 'ERROR', '']) {
        expect(paymentStepForStatus(pending), isNull, reason: pending);
      }
    });
  });

  group('PaymentController (real FimiPay flow)', () {
    testWidgets('create_order SUCCESS is not trusted: keeps waiting for check-status', (tester) async {
      final controller = setUpController(
        createResult: const FimipayPaymentResult(
          success: true,
          orderId: 'fp_order_1',
          paymentReference: 'FP-REF-1',
          status: 'SUCCESS', // FimiPay test mode answers this before anything is activated
        ),
        statuses: [_status('PENDING')],
      );

      await controller.startPayment();
      expect(current().step, PaymentStep.waitingPrompt);
      expect(current().orderId, 'fp_order_1');

      await tester.pump(const Duration(seconds: 9));
      expect(repo.statusCalls, 2);
      expect(current().step, PaymentStep.waitingPrompt);
      expect(profile.refreshes, 0);
      container.dispose();
    });

    testWidgets('success only once check-status reports SUCCESS, then refreshes the profile', (tester) async {
      final controller = setUpController(
        createResult: _created,
        statuses: [_status('PENDING'), _status('SUCCESS', isActive: true)],
      );

      await controller.startPayment();
      await tester.pump(const Duration(seconds: 4));
      expect(current().step, PaymentStep.waitingPrompt);

      await tester.pump(const Duration(seconds: 4));
      expect(current().step, PaymentStep.success);
      expect(profile.refreshes, 1);

      await tester.pump(const Duration(seconds: 8));
      expect(repo.statusCalls, 2, reason: 'polling stops once settled');
      container.dispose();
    });

    testWidgets('is_active from the free trial is never treated as paid; times out instead', (tester) async {
      final controller = setUpController(
        createResult: _created,
        statuses: [_status('PENDING', isActive: true)],
        pollWindowSeconds: 10,
      );

      await controller.startPayment();
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(current().step, PaymentStep.failed);
      expect(current().errorMessage, contains('Bado hatujapokea uthibitisho'));
      expect(profile.refreshes, 0);
      container.dispose();
    });

    for (final entry in {
      'CANCELLED': PaymentStep.cancelled,
      'REJECTED': PaymentStep.rejected,
      'FAILED': PaymentStep.failed,
    }.entries) {
      testWidgets('check-status ${entry.key} ends on ${entry.value.name}', (tester) async {
        final controller = setUpController(
          createResult: _created,
          statuses: [_status(entry.key)],
        );

        await controller.startPayment();
        await tester.pump(const Duration(seconds: 4));

        expect(current().step, entry.value);
        expect(current().errorMessage, isNotNull);
        expect(profile.refreshes, 0);
        container.dispose();
      });
    }

    testWidgets('Cancel / Try another number returns to the form and stops polling', (tester) async {
      final controller = setUpController(
        createResult: _created,
        statuses: [_status('PENDING')],
      );

      await controller.startPayment();
      await tester.pump(const Duration(seconds: 4));
      expect(repo.statusCalls, 1);

      controller.cancelWaiting();
      expect(current().step, PaymentStep.idle);
      expect(current().phoneNumber, '0712345678');
      expect(current().operator, MobileOperator.tigo);
      expect(current().orderId, isEmpty);

      await tester.pump(const Duration(seconds: 20));
      expect(repo.statusCalls, 1);
      expect(current().step, PaymentStep.idle);
      container.dispose();
    });

    testWidgets('payment_in_progress keeps waiting on the open order instead of failing', (tester) async {
      final controller = setUpController(
        createResult: FimipayPaymentResult.fromJson(const {
          'success': false,
          'code': 'payment_in_progress',
          'order_id': 'fp_open_order',
          'payment_reference': 'FP-OPEN',
          'error': 'Una malipo yanayosubiri.',
        }),
        statuses: [_status('PENDING')],
      );

      await controller.startPayment();
      expect(current().step, PaymentStep.waitingPrompt);
      expect(current().orderId, 'fp_open_order');
      expect(current().errorMessage, 'Una malipo yanayosubiri.');

      await tester.pump(const Duration(seconds: 1));
      expect(current().errorMessage, 'Una malipo yanayosubiri.', reason: 'countdown keeps the notice');
      container.dispose();
    });

    testWidgets('create-payment error ends on failed without polling', (tester) async {
      final controller = setUpController(
        createResult: FimipayPaymentResult.error('Salio halitoshi'),
        statuses: [_status('SUCCESS')],
      );

      await controller.startPayment();
      expect(current().step, PaymentStep.failed);
      expect(current().errorMessage, 'Salio halitoshi');

      await tester.pump(const Duration(seconds: 8));
      expect(repo.statusCalls, 0);
      container.dispose();
    });
  });
}
