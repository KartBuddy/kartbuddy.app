import 'dart:convert';

class RedeemGiftCodeRequest {
  final String customerId;
  final String giftCode;

  RedeemGiftCodeRequest({
    required this.customerId,
    required this.giftCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'gift_code': giftCode,
    };
  }
}

class RedeemGiftCodeResponse {
  final bool success;
  final String message;
  final GiftCodeData data;

  RedeemGiftCodeResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RedeemGiftCodeResponse.fromJson(Map<String, dynamic> json) {
    return RedeemGiftCodeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: GiftCodeData.fromJson(json['data'] ?? {}),
    );
  }
}

class GiftCodeData {
  final bool success;
  final String giftValue;
  final String message;

  GiftCodeData({
    required this.success,
    required this.giftValue,
    required this.message,
  });

  factory GiftCodeData.fromJson(Map<String, dynamic> json) {
    return GiftCodeData(
      success: json['success'] ?? false,
      giftValue: json['gift_value']?.toString() ?? '0.00',
      message: json['message'] ?? '',
    );
  }
}

