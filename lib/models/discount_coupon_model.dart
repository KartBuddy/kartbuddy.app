import 'dart:convert';

class DiscountCouponsResponse {
  final bool success;
  final String message;
  final List<DiscountCoupon> data;

  DiscountCouponsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DiscountCouponsResponse.fromJson(Map<String, dynamic> json) {
    return DiscountCouponsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => DiscountCoupon.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DiscountCoupon {
  final String id;
  final String couponCode;
  final String description;
  final String discountType; // "percentage" or "fixed"
  final String discountValue;
  final String minOrderValue;
  final String? maxDiscountCap;
  final String startDate;
  final String? endDate;
  final int totalUsageLimit;
  final int perCustomerLimit;
  final int totalUsed;
  final String usableBy;
  final bool isActive;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;

  DiscountCoupon({
    required this.id,
    required this.couponCode,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.maxDiscountCap,
    required this.startDate,
    this.endDate,
    required this.totalUsageLimit,
    required this.perCustomerLimit,
    required this.totalUsed,
    required this.usableBy,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiscountCoupon.fromJson(Map<String, dynamic> json) {
    return DiscountCoupon(
      id: json['id'] ?? '',
      couponCode: json['coupon_code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discount_type'] ?? '',
      discountValue: json['discount_value']?.toString() ?? '0',
      minOrderValue: json['min_order_value']?.toString() ?? '0',
      maxDiscountCap: json['max_discount_cap']?.toString(),
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'],
      totalUsageLimit: json['total_usage_limit'] ?? 0,
      perCustomerLimit: json['per_customer_limit'] ?? 0,
      totalUsed: json['total_used'] ?? 0,
      usableBy: json['usable_by'] ?? '',
      isActive: json['is_active'] ?? false,
      createdBy: json['created_by'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isExpired {
    if (endDate == null) return false;
    try {
      final expiry = DateTime.parse(endDate!);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return false;
    }
  }

  bool get isFullyUsed {
    return totalUsed >= totalUsageLimit;
  }

  bool get isValid {
    return isActive && !isExpired && !isFullyUsed;
  }
}

class CouponValidationResponse {
  final bool success;
  final String message;
  final CouponValidationData? data;

  CouponValidationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CouponValidationResponse.fromJson(Map<String, dynamic> json) {
    return CouponValidationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: json['data'] != null
          ? CouponValidationData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CouponValidationData {
  final String couponCode;
  final String discountType;
  final String discountValue;
  final String discountAmount;
  final String? maxDiscountCap;

  CouponValidationData({
    required this.couponCode,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    this.maxDiscountCap,
  });

  factory CouponValidationData.fromJson(Map<String, dynamic> json) {
    return CouponValidationData(
      couponCode: json['coupon_code'] ?? '',
      discountType: json['discount_type'] ?? '',
      discountValue: json['discount_value']?.toString() ?? '0',
      discountAmount: json['discount_amount']?.toString() ?? '0',
      maxDiscountCap: json['max_discount_cap']?.toString(),
    );
  }
}


