import 'dart:convert';

class RazorpayOrderRequest {
  final int amount;
  final String customerId;

  RazorpayOrderRequest({
    required this.amount,
    required this.customerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'customer_id': customerId,
    };
  }
}

class RazorpayOrderResponse {
  final bool success;
  final String orderId;
  final int amount;
  final String currency;
  final String keyId;

  RazorpayOrderResponse({
    required this.success,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
  });

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponse(
      success: json['success'] ?? false,
      orderId: json['order_id'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'INR',
      keyId: json['key_id'] ?? '',
    );
  }
}

