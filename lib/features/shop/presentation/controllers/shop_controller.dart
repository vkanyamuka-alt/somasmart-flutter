import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somasmart_flutter/core/utils/phone_utils.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/shop/data/repositories/shop_repository.dart';
import 'package:somasmart_flutter/features/shop/domain/models/shop_models.dart';

/// Payment Flow Steps
enum PaymentStep {
  idle,
  initiating,
  waitingPrompt,
  stkSimulator,
  verifying,
  success,
  cancelled,
  rejected,
  failed,
}

/// State for the mobile payment checkout session.
class PaymentState {
  final PaymentStep step;
  final MobileOperator operator;
  final String phoneNumber;
  final String orderId;
  final String paymentReference;
  final String pinCode;
  final bool isSimulated;
  final int pollSecondsRemaining;
  final String? errorMessage;

  const PaymentState({
    this.step = PaymentStep.idle,
    this.operator = MobileOperator.mpesa,
    this.phoneNumber = '',
    this.orderId = '',
    this.paymentReference = '',
    this.pinCode = '',
    this.isSimulated = false,
    this.pollSecondsRemaining = 120,
    this.errorMessage,
  });

  PaymentState copyWith({
    PaymentStep? step,
    MobileOperator? operator,
    String? phoneNumber,
    String? orderId,
    String? paymentReference,
    String? pinCode,
    bool? isSimulated,
    int? pollSecondsRemaining,
    String? errorMessage,
  }) {
    return PaymentState(
      step: step ?? this.step,
      operator: operator ?? this.operator,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      orderId: orderId ?? this.orderId,
      paymentReference: paymentReference ?? this.paymentReference,
      pinCode: pinCode ?? this.pinCode,
      isSimulated: isSimulated ?? this.isSimulated,
      pollSecondsRemaining: pollSecondsRemaining ?? this.pollSecondsRemaining,
      errorMessage: errorMessage,
    );
  }
}

/// Maps a `payment_status` from `fimipay-check-status` to a final step, or null while still pending.
/// Only the payment's own status counts: `is_active` can be true because of the free trial.
PaymentStep? paymentStepForStatus(String paymentStatus) {
  switch (paymentStatus.toUpperCase()) {
    case 'SUCCESS':
    case 'COMPLETED':
    case 'PAID':
      return PaymentStep.success;
    case 'CANCELLED':
    case 'USERCANCELLED':
      return PaymentStep.cancelled;
    case 'REJECTED':
      return PaymentStep.rejected;
    case 'FAILED':
    case 'NOT_FOUND':
      return PaymentStep.failed;
    default:
      return null;
  }
}

/// Controller managing payment initiation, FimiPay push reconciliation, and simulated fallback.
class PaymentController extends StateNotifier<PaymentState> {
  final ShopRepository _repository;
  final Ref _ref;
  final Duration pollInterval;
  final int pollWindowSeconds;
  Timer? _pollTimer;
  Timer? _countdownTimer;

  PaymentController(
    this._repository,
    this._ref, {
    this.pollInterval = const Duration(seconds: 4),
    this.pollWindowSeconds = 120,
  }) : super(const PaymentState());

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void init(String initialPhone) {
    if (state.step == PaymentStep.idle && initialPhone.isNotEmpty && state.phoneNumber.isEmpty) {
      state = state.copyWith(phoneNumber: initialPhone);
    }
  }

  void setOperator(MobileOperator op) {
    state = state.copyWith(operator: op, errorMessage: null);
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone, errorMessage: null);
  }

  void setPinCode(String pin) {
    state = state.copyWith(pinCode: pin, errorMessage: null);
  }

  void setSimulatedMode(bool simulated) {
    state = state.copyWith(isSimulated: simulated, errorMessage: null);
  }

  /// Initiates payment (FimiPay real flow or simulated flow).
  Future<void> startPayment() async {
    _stopPolling();
    final rawPhone = state.phoneNumber.trim();

    if (rawPhone.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Tafadhali ingiza namba ya simu ya malipo.',
      );
      return;
    }

    if (!PhoneUtils.isValidTanzaniaPhone(rawPhone)) {
      state = state.copyWith(
        errorMessage: 'Namba ya simu si sahihi. Tumia mfano 07XXXXXXXX au 06XXXXXXXX',
      );
      return;
    }

    final normalizedPhone = PhoneUtils.normalizeTanzaniaPhone(rawPhone);

    // 1. SIMULATED FALLBACK FLOW (for test/offline preservation)
    if (state.isSimulated) {
      state = state.copyWith(step: PaymentStep.initiating, errorMessage: null);
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final record = await _repository.createSubscriptionPayment(state.operator.code);
        state = state.copyWith(
          step: PaymentStep.stkSimulator,
          paymentReference: record.paymentReference,
          orderId: record.paymentReference,
          pinCode: '',
          errorMessage: null,
        );
      } catch (e) {
        state = state.copyWith(
          step: PaymentStep.failed,
          errorMessage: 'Imeshindikana kuanzisha malipo ya majaribio.',
        );
      }
      return;
    }

    // 2. REAL FIMIPAY PRODUCTION INTEGRATION FLOW
    state = state.copyWith(step: PaymentStep.initiating, errorMessage: null);

    try {
      final result = await _repository.initiateFimipayPayment(
        phone: normalizedPhone,
        operator: state.operator.code,
      );

      // A prompt sent within the last 2 minutes is still open: keep waiting on that order
      // instead of sending a second prompt.
      if ((!result.success && !result.isInProgress) || result.orderId.isEmpty) {
        state = state.copyWith(
          step: PaymentStep.failed,
          errorMessage: result.errorMessage ?? 'Imeshindikana kuanzisha malipo ya FimiPay.',
        );
        return;
      }

      // Never trust create_order's own status: FimiPay (test mode) can answer SUCCESS
      // before the subscription is activated. fimipay-check-status confirms and, if the
      // webhook is late, activates — so always wait for it.
      state = state.copyWith(
        step: PaymentStep.waitingPrompt,
        orderId: result.orderId,
        paymentReference: result.paymentReference,
        pollSecondsRemaining: pollWindowSeconds,
        errorMessage: result.isInProgress ? result.errorMessage : null,
      );

      _startStatusPolling(result.orderId);
    } catch (e) {
      state = state.copyWith(
        step: PaymentStep.failed,
        errorMessage: 'Hitilafu ya mtandao wakati wa kuanzisha malipo.',
      );
    }
  }

  /// Polls `fimipay-check-status` (backup to the webhook) until the order settles or the window ends.
  void _startStatusPolling(String orderId) {
    _stopPolling();
    var inFlight = false;

    // Returns true once the order has settled and the state has moved on.
    Future<bool> checkOnce() async {
      if (inFlight) return false;
      inFlight = true;
      try {
        final statusRes = await _repository.checkFimipayPaymentStatus(orderId: orderId);
        if (!mounted || state.step != PaymentStep.waitingPrompt || state.orderId != orderId) {
          return true;
        }
        final next = paymentStepForStatus(statusRes.paymentStatus);
        if (next == null) return false;
        await _settle(next);
        return true;
      } catch (_) {
        return false; // Keep waiting on transient network hiccups
      } finally {
        inFlight = false;
      }
    }

    // 1. Countdown, with one last check before declaring a timeout
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || state.step != PaymentStep.waitingPrompt) {
        timer.cancel();
        return;
      }
      if (state.pollSecondsRemaining > 1) {
        state = state.copyWith(
          pollSecondsRemaining: state.pollSecondsRemaining - 1,
          errorMessage: state.errorMessage,
        );
        return;
      }
      _stopPolling();
      inFlight = false;
      if (await checkOnce()) return;
      if (mounted && state.step == PaymentStep.waitingPrompt && state.orderId == orderId) {
        state = state.copyWith(
          step: PaymentStep.failed,
          errorMessage: 'Bado hatujapokea uthibitisho. Kama umelipa, usajili wako utawashwa punde. Angalia "Malipo Yangu" kwenye Akaunti.',
        );
      }
    });

    // 2. Status reconciliation poll
    _pollTimer = Timer.periodic(pollInterval, (timer) async {
      if (!mounted || state.step != PaymentStep.waitingPrompt) {
        timer.cancel();
        return;
      }
      await checkOnce();
    });
  }

  Future<void> _settle(PaymentStep next) async {
    _stopPolling();
    if (next == PaymentStep.success) {
      await _ref.read(userProfileProvider.notifier).refreshProfile();
    }
    if (!mounted) return;
    state = state.copyWith(
      step: next,
      errorMessage: switch (next) {
        PaymentStep.cancelled => 'Malipo yameghairiwa. Kama salio halitoshi, ongeza salio au tumia namba nyingine.',
        PaymentStep.rejected => 'Malipo yamekataliwa. Tafadhali hakiki salio au namba kisha jaribu tena.',
        PaymentStep.failed => 'Malipo hayakukamilika. Tafadhali jaribu tena.',
        _ => null,
      },
    );
  }

  /// "Cancel / Try another number" while waiting: stop waiting and go back to the form.
  /// FimiPay can report a cancellation (e.g. insufficient balance) minutes after the phone shows it.
  /// The order itself stays open server-side; if it is approved later the webhook still activates it.
  void cancelWaiting() {
    _stopPolling();
    state = state.copyWith(
      step: PaymentStep.idle,
      orderId: '',
      paymentReference: '',
      pollSecondsRemaining: pollWindowSeconds,
      errorMessage: null,
    );
  }

  /// Simulates PIN entry submission and verifies with Edge Function webhook (Simulated mode).
  Future<void> submitPinAndVerify() async {
    if (state.pinCode.length < 4) {
      state = state.copyWith(errorMessage: 'Weka PIN ya tarakimu 4');
      return;
    }

    state = state.copyWith(step: PaymentStep.verifying, errorMessage: null);

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      final isSuccess = await _repository.simulatePaymentWebhook(state.paymentReference);

      if (isSuccess) {
        await _ref.read(userProfileProvider.notifier).refreshProfile();
        state = state.copyWith(step: PaymentStep.success, errorMessage: null);
      } else {
        state = state.copyWith(
          step: PaymentStep.failed,
          errorMessage: 'Malipo yamefeli. Tafadhali jaribu tena.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        step: PaymentStep.failed,
        errorMessage: 'Hitilafu ya mtandao wakati wa kuhakiki malipo.',
      );
    }
  }

  void cancelPayment() {
    _stopPolling();
    state = state.copyWith(
      step: PaymentStep.cancelled,
      errorMessage: 'Umeghairi muamala wa malipo.',
    );
  }

  void reset() {
    _stopPolling();
    state = PaymentState(
      phoneNumber: state.phoneNumber,
      operator: state.operator,
      isSimulated: state.isSimulated,
    );
  }
}

/// Provider for PaymentController.
final paymentControllerProvider =
    StateNotifierProvider.autoDispose<PaymentController, PaymentState>((ref) {
  final repo = ref.watch(shopRepositoryProvider);
  return PaymentController(repo, ref);
});

/// Provider fetching shop items for catalog.
final shopItemsProvider = FutureProvider.autoDispose<List<ShopItem>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  final repo = ref.watch(shopRepositoryProvider);
  return repo.getShopItems(user?.id);
});
