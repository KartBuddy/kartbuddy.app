import 'dart:convert';

class RazorpayVerifyRequest {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
  final int amount;
  final String customerId;

  RazorpayVerifyRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
    required this.amount,
    required this.customerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'amount': amount,
      'customer_id': customerId,
    };
  }
}

class RazorpayVerifyResponse {
  final bool success;
  final String message;
  final String walletBalance;

  RazorpayVerifyResponse({
    required this.success,
    required this.message,
    required this.walletBalance,
  });

  factory RazorpayVerifyResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayVerifyResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      walletBalance: json['wallet_balance']?.toString() ?? '0.00',
    );
  }
}

