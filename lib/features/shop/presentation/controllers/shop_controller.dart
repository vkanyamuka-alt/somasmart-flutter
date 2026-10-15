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

/// Controller managing payment initiation, FimiPay push reconciliation, and simulated fallback.
class PaymentController extends StateNotifier<PaymentState> {
  final ShopRepository _repository;
  final Ref _ref;
  Timer? _pollTimer;
  Timer? _countdownTimer;

  PaymentController(this._repository, this._ref) : super(const PaymentState());

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

      if (!result.success) {
        state = state.copyWith(
          step: PaymentStep.failed,
          errorMessage: result.errorMessage ?? 'Imeshindikana kuanzisha malipo ya FimiPay.',
        );
        return;
      }

      // If order was already fulfilled immediately (e.g. instant simulation)
      if (result.status == 'SUCCESS' || result.status == 'PAID' || result.status == 'COMPLETED') {
        await _ref.read(userProfileProvider.notifier).refreshProfile();
        state = state.copyWith(
          step: PaymentStep.success,
          orderId: result.orderId,
          paymentReference: result.paymentReference,
          errorMessage: null,
        );
        return;
      }

      // Transition to waiting for USSD prompt on student's phone
      state = state.copyWith(
        step: PaymentStep.waitingPrompt,
        orderId: result.orderId,
        paymentReference: result.paymentReference,
        pollSecondsRemaining: 120,
        errorMessage: null,
      );

      _startStatusPolling(result.orderId);
    } catch (e) {
      state = state.copyWith(
        step: PaymentStep.failed,
        errorMessage: 'Hitilafu ya mtandao wakati wa kuanzisha malipo.',
      );
    }
  }

  /// Safe, limited interval polling for FimiPay order status (Primary: Webhook, Secondary: Reconcile)
  void _startStatusPolling(String orderId) {
    _stopPolling();

    // 1. Countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (state.pollSecondsRemaining <= 1) {
        timer.cancel();
        if (state.step == PaymentStep.waitingPrompt || state.step == PaymentStep.verifying) {
          // Robust final check before declaring timeout failure
          _repository.checkFimipayPaymentStatus(orderId: orderId).then((finalRes) async {
            if (!mounted) return;
            if (finalRes.isActive ||
                finalRes.paymentStatus == 'SUCCESS' ||
                finalRes.paymentStatus == 'PAID' ||
                finalRes.paymentStatus == 'COMPLETED') {
              _stopPolling();
              await _ref.read(userProfileProvider.notifier).refreshProfile();
              if (mounted) {
                state = state.copyWith(
                  step: PaymentStep.success,
                  errorMessage: null,
                );
              }
            } else {
              _stopPolling();
              if (mounted) {
                state = state.copyWith(
                  step: PaymentStep.failed,
                  errorMessage: 'Muda wa kusubiri malipo umekwisha. Kama umekamilisha malipo kwenye simu, usajili wako utawashwa punde kupitia ujumbe wa mtandao.',
                );
              }
            }
          }).catchError((_) {
            _stopPolling();
            if (mounted) {
              state = state.copyWith(
                step: PaymentStep.failed,
                errorMessage: 'Muda wa kusubiri malipo umekwisha. Kama umekamilisha malipo kwenye simu, usajili wako utawashwa punde kupitia ujumbe wa mtandao.',
              );
            }
          });
        }
      } else {
        state = state.copyWith(pollSecondsRemaining: state.pollSecondsRemaining - 1);
      }
    });

    // 2. Status reconciliation poll every 4 seconds (max 30 attempts in 120s)
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted || state.step != PaymentStep.waitingPrompt) {
        timer.cancel();
        return;
      }

      try {
        final statusRes = await _repository.checkFimipayPaymentStatus(orderId: orderId);

        if (statusRes.isActive ||
            statusRes.paymentStatus == 'SUCCESS' ||
            statusRes.paymentStatus == 'PAID' ||
            statusRes.paymentStatus == 'COMPLETED') {
          _stopPolling();
          await _ref.read(userProfileProvider.notifier).refreshProfile();
          if (mounted) {
            state = state.copyWith(
              step: PaymentStep.success,
              errorMessage: null,
            );
          }
        } else if (statusRes.paymentStatus == 'CANCELLED' || statusRes.paymentStatus == 'USERCANCELLED') {
          _stopPolling();
          if (mounted) {
            state = state.copyWith(
              step: PaymentStep.cancelled,
              errorMessage: 'Malipo yameghairiwa na mtumiaji.',
            );
          }
        } else if (statusRes.paymentStatus == 'REJECTED') {
          _stopPolling();
          if (mounted) {
            state = state.copyWith(
              step: PaymentStep.rejected,
              errorMessage: 'Malipo yamekataliwa. Tafadhali hakiki salio au namba kisha jaribu tena.',
            );
          }
        }
      } catch (_) {
        // Continue waiting on transient network hiccups
      }
    });
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
