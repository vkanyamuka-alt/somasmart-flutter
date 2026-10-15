import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:somasmart_flutter/core/services/supabase_service.dart';
import 'package:somasmart_flutter/features/shop/domain/models/shop_models.dart';

/// Repository for Shop items, purchases, and server-authoritative payment transactions.
class ShopRepository {
  final SupabaseClient _client;

  ShopRepository(this._client);

  /// Fetch all available shop items and check unlock status for logged in user.
  Future<List<ShopItem>> getShopItems(String? userId) async {
    try {
      final purchasedIds = <String>{};

      // 1. Fetch purchased item IDs if user is logged in
      if (userId != null && userId.isNotEmpty && userId != 'guest') {
        try {
          final purchasesRes = await _client
              .from('shop_purchases')
              .select('item_id')
              .eq('user_id', userId);
          final pList = purchasesRes as List<dynamic>;
          for (final row in pList) {
            final id = (row as Map<String, dynamic>)['item_id']?.toString();
            if (id != null) purchasedIds.add(id);
          }
        } catch (_) {
          // Graceful fallback if table is not cached
        }
      }

      // 2. Fetch catalog from shop_items with fallback to learning_materials
      try {
        final response = await _client
            .from('shop_items')
            .select('*')
            .eq('is_archived', false)
            .order('display_priority', ascending: false)
            .order('created_at', ascending: false);

        final list = response as List<dynamic>;
        return list.map((json) {
          final map = json as Map<String, dynamic>;
          final id = map['id']?.toString() ?? '';
          return ShopItem.fromJson(map, isPurchased: purchasedIds.contains(id));
        }).toList();
      } catch (_) {
        // Fallback to learning_materials if shop_items is unavailable
        final matResponse = await _client
            .from('learning_materials')
            .select('*')
            .order('created_at', ascending: false);

        final matList = matResponse as List<dynamic>;
        return matList.map((json) {
          final map = json as Map<String, dynamic>;
          final id = map['id']?.toString() ?? '';
          return ShopItem.fromJson(map, isPurchased: purchasedIds.contains(id));
        }).toList();
      }
    } catch (e) {
      return [];
    }
  }

  /// Purchase an individual shop item.
  Future<bool> purchaseShopItem({
    required String userId,
    required String itemId,
    required double amount,
  }) async {
    if (userId.isEmpty || userId == 'guest') return false;

    try {
      await _client.from('shop_purchases').insert({
        'user_id': userId,
        'item_id': itemId,
        'amount': amount,
      });

      // Update analytics counter on shop_items
      try {
        await _client.from('shop_items').update({
          'last_purchase_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', itemId);
      } catch (_) {}

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Initiates a real FimiPay mobile payment via Edge Function `fimipay-create-payment`.
  Future<FimipayPaymentResult> initiateFimipayPayment({
    required String phone,
    required String operator,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'fimipay-create-payment',
        body: {
          'phone': phone,
          'operator': operator,
          'payment_method': 'mobile',
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return FimipayPaymentResult.fromJson(data);
        } else if (data is Map) {
          return FimipayPaymentResult.fromJson(Map<String, dynamic>.from(data));
        }
      }

      final errorMsg = response.data is Map
          ? (response.data['error']?.toString() ?? 'Imeshindikana kuanzisha malipo.')
          : 'Imeshindikana kuwasiliana na seva ya malipo.';
      return FimipayPaymentResult.error(errorMsg);
    } on FunctionException catch (e) {
      // Non-2xx replies (409 payment_in_progress, 4xx/5xx with an `error` text) carry JSON in details.
      final details = e.details;
      if (details is Map) {
        final result = FimipayPaymentResult.fromJson(Map<String, dynamic>.from(details));
        if (result.isInProgress || result.errorMessage != null) return result;
      }
      return FimipayPaymentResult.error('Imeshindikana kuanzisha malipo. Tafadhali jaribu tena.');
    } catch (e) {
      return FimipayPaymentResult.error('Hitilafu ya mtandao wakati wa kuanzisha malipo: $e');
    }
  }

  /// Reconciles or checks order status via Edge Function `fimipay-check-status`.
  Future<FimipayStatusResult> checkFimipayPaymentStatus({
    required String orderId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'fimipay-check-status',
        body: {'order_id': orderId},
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return FimipayStatusResult.fromJson(data);
        } else if (data is Map) {
          return FimipayStatusResult.fromJson(Map<String, dynamic>.from(data));
        }
      }

      return FimipayStatusResult(
        success: false,
        paymentStatus: 'UNKNOWN',
        isActive: false,
        errorMessage: 'Unable to verify payment status.',
      );
    } on FunctionException catch (e) {
      return FimipayStatusResult(
        success: false,
        // 404: the order is not this student's (or does not exist) — stop waiting on it.
        paymentStatus: e.status == 404 ? 'NOT_FOUND' : 'ERROR',
        isActive: false,
        errorMessage: e.toString(),
      );
    } catch (e) {
      return FimipayStatusResult(
        success: false,
        paymentStatus: 'ERROR',
        isActive: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Initiates a server-authoritative subscription payment record in Supabase.
  /// Calls the `create_subscription_payment` RPC with `p_payment_method`.
  Future<PaymentRecord> createSubscriptionPayment(String paymentMethod) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Unauthenticated caller. Please log in.');
    }

    try {
      // 1. Primary: Server-authoritative RPC
      final response = await _client.rpc(
        'create_subscription_payment',
        params: {'p_payment_method': paymentMethod},
      );

      if (response != null) {
        if (response is List && response.isNotEmpty) {
          return PaymentRecord.fromJson(response.first as Map<String, dynamic>);
        } else if (response is Map<String, dynamic>) {
          return PaymentRecord.fromJson(response);
        }
      }
    } catch (_) {
      // Fallback: Direct restricted INSERT adhering to Migration 27 RLS
      final ref = 'TXN-${100000 + Random().nextInt(900000)}';
      final insertRes = await _client
          .from('payments')
          .insert({
            'user_id': user.id,
            'amount': 2500.00,
            'currency': 'TZS',
            'payment_method': paymentMethod,
            'payment_reference': ref,
            'status': 'pending',
            'type': 'subscription',
          })
          .select()
          .single();

      return PaymentRecord.fromJson(insertRes);
    }

    throw Exception('Failed to create subscription payment record.');
  }

  /// Verifies and fulfills a simulated subscription payment via Edge Function `simulate-payment-webhook`.
  Future<bool> simulatePaymentWebhook(String paymentReference) async {
    try {
      final response = await _client.functions.invoke(
        'simulate-payment-webhook',
        body: {'payment_reference': paymentReference},
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for ShopRepository.
final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ShopRepository(client);
});
