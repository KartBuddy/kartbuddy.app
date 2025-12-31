import 'dart:convert';

class GiftCodeListResponse {
  final bool success;
  final String message;
  final List<GiftCode> data;

  GiftCodeListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory GiftCodeListResponse.fromJson(Map<String, dynamic> json) {
    return GiftCodeListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => GiftCode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GiftCode {
  final String id;
  final String giftCode;
  final String description;
  final String giftValue;
  final int totalUseLimit;
  final int perCustomerLimit;
  final int totalUsed;
  final String usableBy;
  final String expirationDate;
  final String termsAndConditions;
  final bool isActive;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;

  GiftCode({
    required this.id,
    required this.giftCode,
    required this.description,
    required this.giftValue,
    required this.totalUseLimit,
    required this.perCustomerLimit,
    required this.totalUsed,
    required this.usableBy,
    required this.expirationDate,
    required this.termsAndConditions,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GiftCode.fromJson(Map<String, dynamic> json) {
    return GiftCode(
      id: json['id'] ?? '',
      giftCode: json['gift_code'] ?? '',
      description: json['description'] ?? '',
      giftValue: json['gift_value']?.toString() ?? '0.00',
      totalUseLimit: json['total_use_limit'] ?? 0,
      perCustomerLimit: json['per_customer_limit'] ?? 0,
      totalUsed: json['total_used'] ?? 0,
      usableBy: json['usable_by'] ?? '',
      expirationDate: json['expiration_date'] ?? '',
      termsAndConditions: json['terms_and_conditions'] ?? '',
      isActive: json['is_active'] ?? false,
      createdBy: json['created_by'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isExpired {
    try {
      final expiryDate = DateTime.parse(expirationDate);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return false;
    }
  }

  bool get isFullyUsed {
    return totalUsed >= totalUseLimit;
  }
}

