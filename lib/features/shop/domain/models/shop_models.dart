import 'package:flutter/material.dart';

/// Supported Tanzanian mobile wallet operators.
enum MobileOperator {
  mpesa('mpesa', 'M-Pesa', Color(0xFFEF4444)),
  airtel('airtel', 'Airtel Money', Color(0xFFF59E0B)),
  tigo('tigopesa', 'Mixx / Tigo', Color(0xFF06B6D4)),
  halopesa('halopesa', 'HaloPesa', Color(0xFFF97316));

  final String code;
  final String label;
  final Color color;

  const MobileOperator(this.code, this.label, this.color);

  static MobileOperator fromCode(String code) {
    final lower = code.toLowerCase();
    if (lower == 'airtel') return MobileOperator.airtel;
    if (lower == 'tigo' || lower == 'tigopesa' || lower == 'yas' || lower == 'mixx') return MobileOperator.tigo;
    if (lower == 'halopesa' || lower == 'halo') return MobileOperator.halopesa;
    return MobileOperator.mpesa;
  }
}

/// Domain model for Shop items / Books / Learning materials.
class ShopItem {
  final String id;
  final String titleEn;
  final String titleSw;
  final String descEn;
  final String descSw;
  final String category;
  final double price;
  final double? discountPrice;
  final String currency;
  final String coverImage;
  final int stockQuantity;
  final bool isFeatured;
  final bool isRecommended;
  final bool isEditorsChoice;
  final bool isOnSale;
  final bool isStaffPick;
  final DateTime? createdAt;
  final bool isPurchased;

  const ShopItem({
    required this.id,
    required this.titleEn,
    required this.titleSw,
    required this.descEn,
    required this.descSw,
    required this.category,
    required this.price,
    this.discountPrice,
    this.currency = 'TZS',
    required this.coverImage,
    this.stockQuantity = 100,
    this.isFeatured = false,
    this.isRecommended = false,
    this.isEditorsChoice = false,
    this.isOnSale = false,
    this.isStaffPick = false,
    this.createdAt,
    this.isPurchased = false,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json, {bool isPurchased = false}) {
    final title = json['title']?.toString() ?? '';
    final titleEn = json['title_en']?.toString() ?? (title.isNotEmpty ? title : 'Book Item');
    final titleSw = json['title_sw']?.toString() ?? titleEn;

    final desc = json['description']?.toString() ?? '';
    final descEn = json['desc_en']?.toString() ?? desc;
    final descSw = json['desc_sw']?.toString() ?? descEn;

    final priceNum = (json['price'] as num?)?.toDouble() ?? 0.0;
    final discountNum = (json['discount_price'] as num?)?.toDouble();

    final cover = json['cover_image']?.toString() ??
        json['thumbnail_url']?.toString() ??
        json['external_url']?.toString() ??
        '';

    return ShopItem(
      id: json['id']?.toString() ?? '',
      titleEn: titleEn,
      titleSw: titleSw,
      descEn: descEn,
      descSw: descSw,
      category: json['category']?.toString() ?? 'Books',
      price: priceNum,
      discountPrice: discountNum,
      currency: json['currency']?.toString() ?? 'TZS',
      coverImage: cover,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 100,
      isFeatured: json['is_featured'] == true,
      isRecommended: json['is_recommended'] == true,
      isEditorsChoice: json['is_editors_choice'] == true,
      isOnSale: json['is_on_sale'] == true,
      isStaffPick: json['is_staff_pick'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isPurchased: isPurchased,
    );
  }

  String getTitle(String lang) {
    if (lang == 'sw') return titleSw.isNotEmpty ? titleSw : titleEn;
    return titleEn.isNotEmpty ? titleEn : titleSw;
  }

  String getDesc(String lang) {
    if (lang == 'sw') return descSw.isNotEmpty ? descSw : descEn;
    return descEn.isNotEmpty ? descEn : descSw;
  }

  String get formattedPrice {
    if (price == 0) return 'BURE';
    return '$currency ${price.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  ShopItem copyWith({bool? isPurchased, int? stockQuantity}) {
    return ShopItem(
      id: id,
      titleEn: titleEn,
      titleSw: titleSw,
      descEn: descEn,
      descSw: descSw,
      category: category,
      price: price,
      discountPrice: discountPrice,
      currency: currency,
      coverImage: coverImage,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isFeatured: isFeatured,
      isRecommended: isRecommended,
      isEditorsChoice: isEditorsChoice,
      isOnSale: isOnSale,
      isStaffPick: isStaffPick,
      createdAt: createdAt,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}

/// Domain model for server-authoritative payment transactions.
class PaymentRecord {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentReference;
  final String provider;
  final String? orderId;
  final String? transid;
  final String? channel;
  final String? phone;
  final String status;
  final String type;
  final DateTime createdAt;

  const PaymentRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentReference,
    this.provider = 'simulated',
    this.orderId,
    this.transid,
    this.channel,
    this.phone,
    required this.status,
    required this.type,
    required this.createdAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 2500.00,
      currency: json['currency']?.toString() ?? 'TZS',
      paymentMethod: json['payment_method']?.toString() ?? 'mpesa',
      paymentReference: json['payment_reference']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'simulated',
      orderId: json['order_id']?.toString(),
      transid: json['transid']?.toString(),
      channel: json['channel']?.toString(),
      phone: json['phone']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      type: json['type']?.toString() ?? 'subscription',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Result returned from FimiPay payment creation / initialization.
class FimipayPaymentResult {
  final bool success;
  final String orderId;
  final String paymentReference;
  final String status;
  final String message;
  final String? errorMessage;

  /// Machine-readable reason from the Edge Function, e.g. `payment_in_progress`.
  final String? code;

  const FimipayPaymentResult({
    required this.success,
    this.orderId = '',
    this.paymentReference = '',
    this.status = 'PENDING',
    this.message = '',
    this.errorMessage,
    this.code,
  });

  /// The server refused a second prompt because an order is still open; [orderId] is that order.
  bool get isInProgress => code == 'payment_in_progress';

  factory FimipayPaymentResult.fromJson(Map<String, dynamic> json) {
    final isSuccess = json['success'] == true;
    return FimipayPaymentResult(
      success: isSuccess,
      orderId: json['order_id']?.toString() ?? '',
      paymentReference: json['payment_reference']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
      message: json['message']?.toString() ?? '',
      errorMessage: json['error']?.toString() ?? json['errorMessage']?.toString(),
      code: json['code']?.toString(),
    );
  }

  factory FimipayPaymentResult.error(String error) {
    return FimipayPaymentResult(
      success: false,
      status: 'FAILED',
      errorMessage: error,
    );
  }
}

/// Result from checking FimiPay payment order status.
class FimipayStatusResult {
  final bool success;
  final String paymentStatus;
  final bool isActive;
  final String? paymentReference;
  final String? errorMessage;

  const FimipayStatusResult({
    required this.success,
    required this.paymentStatus,
    required this.isActive,
    this.paymentReference,
    this.errorMessage,
  });

  factory FimipayStatusResult.fromJson(Map<String, dynamic> json) {
    final isSuccess = json['success'] == true;
    return FimipayStatusResult(
      success: isSuccess,
      paymentStatus: (json['payment_status']?.toString() ?? json['status']?.toString() ?? 'PENDING').toUpperCase(),
      isActive: json['is_active'] == true || json['isActive'] == true,
      paymentReference: json['payment_reference']?.toString(),
      errorMessage: json['error']?.toString(),
    );
  }
}
