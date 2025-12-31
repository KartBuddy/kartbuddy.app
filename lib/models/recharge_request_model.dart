import 'dart:convert';

class RechargeRequestResponse {
  final bool success;
  final String message;
  final RechargeRequestData data;

  RechargeRequestResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RechargeRequestResponse.fromJson(Map<String, dynamic> json) {
    return RechargeRequestResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: RechargeRequestData.fromJson(json['data'] ?? {}),
    );
  }
}

class RechargeRequestData {
  final String requestId;
  final String customerId;
  final String amount;
  final String screenshot;
  final String selectedBankId;
  final String? bankTransactionId;
  final String status;
  final String statusRemark;
  final String createdAt;
  final String updatedAt;

  RechargeRequestData({
    required this.requestId,
    required this.customerId,
    required this.amount,
    required this.screenshot,
    required this.selectedBankId,
    this.bankTransactionId,
    required this.status,
    required this.statusRemark,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RechargeRequestData.fromJson(Map<String, dynamic> json) {
    return RechargeRequestData(
      requestId: json['request_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      amount: json['amount']?.toString() ?? '',
      screenshot: json['screenshot'] ?? '',
      selectedBankId: json['selected_bank_id'] ?? '',
      bankTransactionId: json['bank_transaction_id'],
      status: json['status'] ?? '',
      statusRemark: json['status_remark'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

