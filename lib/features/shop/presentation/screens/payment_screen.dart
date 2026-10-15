import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:somasmart_flutter/core/theme/app_colors.dart';
import 'package:somasmart_flutter/core/utils/phone_utils.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/settings/presentation/controllers/settings_controller.dart';
import 'package:somasmart_flutter/features/shop/presentation/controllers/shop_controller.dart';
import 'package:somasmart_flutter/features/shop/domain/models/shop_models.dart';

/// Mobile Payment Checkout Screen.
/// Seamlessly integrates FimiPay mobile Push USSD payment for Tanzanian networks.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late TextEditingController _phoneController;
  late TextEditingController _pinController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _initDefaults() {
    if (!_initialized) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null && profile.phone.isNotEmpty) {
        _phoneController.text = profile.phone;
        ref.read(paymentControllerProvider.notifier).setPhoneNumber(profile.phone);
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    _initDefaults();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final paymentState = ref.watch(paymentControllerProvider);
    final paymentNotifier = ref.read(paymentControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang == 'sw' ? 'Malipo ya Simu' : 'Mobile Payment',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBgSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang == 'sw'
                          ? 'Kamilisha Malipo Yako'
                          : 'Complete Your Payment',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang == 'sw'
                          ? 'Lipa salama kupitia pochi yako ya simu (FimiPay).'
                          : 'Secure mobile money checkout via FimiPay.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    const SizedBox(height: 16),

                    // STEP 1: IDLE FORM
                    if (paymentState.step == PaymentStep.idle) ...[
                      // Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SomaSmart Premium',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  lang == 'sw' ? 'Mwezi 1 (Siku 30)' : '1 Month (30 Days)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'TSh 2,500',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Operator Selection
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          lang == 'sw' ? 'Chagua Mtandao wa Simu' : 'Select Mobile Operator',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.8,
                        children: MobileOperator.values.map((op) {
                          final isSelected = paymentState.operator == op;
                          return InkWell(
                            onTap: () => paymentNotifier.setOperator(op),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: op.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      op.label,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Phone Number Input
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          lang == 'sw' ? 'Namba ya Simu ya Malipo' : 'Payment Phone Number',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (val) => paymentNotifier.setPhoneNumber(val),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '07XXXXXXXX au 06XXXXXXXX',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                          filled: true,
                          fillColor: isDark ? AppColors.darkBgBase : AppColors.lightBgContainer,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (paymentState.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            paymentState.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => paymentNotifier.startPayment(),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text(
                            lang == 'sw' ? 'Lipa Sasa (TSh 2,500)' : 'Pay Now (TSh 2,500)',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],

                    // STEP 2: INITIATING LOADER
                    if (paymentState.step == PaymentStep.initiating) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(height: 18),
                            Text(
                              lang == 'sw' ? 'Tunaanzisha malipo...' : 'Initiating payment...',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lang == 'sw'
                                  ? 'Kuwasiliana na mfumo wa FimiPay'
                                  : 'Connecting to FimiPay gateway',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.darkTextMuted),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // STEP 3: WAITING FOR USSD PROMPT ON PHONE (FimiPay real flow)
                    if (paymentState.step == PaymentStep.waitingPrompt) ...[
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phonelink_ring_rounded,
                          color: AppColors.warning,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang == 'sw'
                            ? 'Ombi la Malipo Limetumwa!'
                            : 'Payment Request Sent!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang == 'sw'
                            ? 'Tafadhali kagua simu yako namba ${PhoneUtils.formatForDisplay(paymentState.phoneNumber)} na uweke PIN yako ili kukamilisha malipo ya TSh 2,500.'
                            : 'Please check your phone ${PhoneUtils.formatForDisplay(paymentState.phoneNumber)} and enter your PIN to approve the TSh 2,500 payment.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),

                      // Status Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBgBase : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang == 'sw' ? 'Mtandao:' : 'Operator:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  paymentState.operator.label,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang == 'sw' ? 'Kiasi:' : 'Amount:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const Text(
                                  'TSh 2,500',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang == 'sw' ? 'Kumbukumbu:' : 'Reference:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  paymentState.paymentReference.isNotEmpty
                                      ? paymentState.paymentReference
                                      : paymentState.orderId,
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Animated Waiting Indicator & Countdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lang == 'sw'
                                ? 'Inasubiri uthibitisho (${paymentState.pollSecondsRemaining}s)...'
                                : 'Waiting for confirmation (${paymentState.pollSecondsRemaining}s)...',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      if (paymentState.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          paymentState.errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.warning),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        lang == 'sw'
                            ? 'Simu ikionyesha salio halitoshi au ombi limeghairiwa, unaweza kujaribu namba nyingine.'
                            : 'If your phone shows insufficient balance or the request was cancelled, you can try another number.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      OutlinedButton(
                        key: const Key('payment-cancel-waiting'),
                        onPressed: () => paymentNotifier.cancelWaiting(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          lang == 'sw' ? 'Ghairi / Jaribu namba nyingine' : 'Cancel / Try another number',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],

                    // STEP 4: STK SIMULATOR PIN MODAL (For Simulated Testing)
                    if (paymentState.step == PaymentStep.stkSimulator) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lang == 'sw'
                                    ? 'Ombi la malipo ya majaribio limetumwa.'
                                    : 'Simulated payment prompt ready.',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mobile STK Frame Simulator
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F172A),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    paymentState.operator.label.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'STK Push (Simulated)',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  const Text(
                                    'Lipa TSh 2,500 kwenda SomaSmart kwa ajili ya Subscription.\nWeka PIN yako ya malipo:',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  if (paymentState.errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        paymentState.errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFFF87171),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                  SizedBox(
                                    width: 180,
                                    child: TextField(
                                      controller: _pinController,
                                      keyboardType: TextInputType.number,
                                      obscureText: true,
                                      maxLength: 4,
                                      textAlign: TextAlign.center,
                                      onChanged: (val) => paymentNotifier.setPinCode(val),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        letterSpacing: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        hintText: '••••',
                                        hintStyle: const TextStyle(
                                          color: Colors.white24,
                                          letterSpacing: 8,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFF0F172A),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFF475569)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: () => paymentNotifier.cancelPayment(),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Color(0xFFF87171),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => paymentNotifier.submitPinAndVerify(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Send',
                                          style: TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // STEP 5: VERIFYING LOADER
                    if (paymentState.step == PaymentStep.verifying) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(height: 18),
                            Text(
                              lang == 'sw' ? 'Thibitisho la muamala...' : 'Verifying transaction...',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lang == 'sw'
                                  ? 'Kuhakiki malipo kutoka kwa mtandao wa simu'
                                  : 'Confirming payment from mobile network',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.darkTextMuted),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // STEP 6: SUCCESS STATE
                    if (paymentState.step == PaymentStep.success) ...[
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang == 'sw'
                            ? 'Malipo Yamekamilika Kikamilifu!'
                            : 'Payment Successful!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Transaction Reference: ${paymentState.paymentReference.isNotEmpty ? paymentState.paymentReference : paymentState.orderId}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang == 'sw'
                            ? 'Akaunti yako imesasishwa kuwa SomaSmart Premium kwa siku 30.'
                            : 'Your account has been upgraded to SomaSmart Premium for 30 days.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            lang == 'sw' ? 'Rudi Kwenye Dashibodi' : 'Return to Dashboard',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],

                    // STEP 7: CANCELLED STATE
                    if (paymentState.step == PaymentStep.cancelled) ...[
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.warning,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang == 'sw' ? 'Malipo Yameghairiwa' : 'Payment Cancelled',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        paymentState.errorMessage ??
                            (lang == 'sw'
                                ? 'Umeghairi muamala wa malipo.'
                                : 'The payment transaction was cancelled.'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => paymentNotifier.reset(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            lang == 'sw' ? 'Jaribu Tena (Retry)' : 'Retry Payment',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],

                    // STEP 8: REJECTED STATE
                    if (paymentState.step == PaymentStep.rejected) ...[
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block_rounded,
                          color: AppColors.error,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang == 'sw' ? 'Malipo Yamekataliwa' : 'Payment Rejected',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        paymentState.errorMessage ??
                            (lang == 'sw'
                                ? 'Muamala umekataliwa na mtandao. Tafadhali hakiki salio au namba ya simu.'
                                : 'Transaction rejected by mobile network. Please check your balance or phone number.'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => paymentNotifier.reset(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            lang == 'sw' ? 'Jaribu Tena (Retry)' : 'Retry Payment',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],

                    // STEP 9: FAILED STATE
                    if (paymentState.step == PaymentStep.failed) ...[
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang == 'sw' ? 'Malipo Yamefeli' : 'Payment Failed',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        paymentState.errorMessage ??
                            (lang == 'sw'
                                ? 'Hitilafu wakati wa kuthibitisha malipo.'
                                : 'Failed to verify payment.'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => paymentNotifier.reset(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            lang == 'sw' ? 'Jaribu Tena (Retry)' : 'Retry Payment',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
