import 'dart:convert';

class WalletHistoryResponse {
  final bool success;
  final String message;
  final List<WalletTransaction> data;

  WalletHistoryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory WalletHistoryResponse.fromJson(Map<String, dynamic> json) {
    return WalletHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WalletTransaction {
  final String serialNumber;
  final String transactionDate;
  final String transactionTime;
  final String transactionId;
  final String? portalTransactionId;
  final String? portalTransactionRemarks1;
  final String? portalTransactionRemarks2;
  final String creditDebit;
  final String transactionType;
  final String amount;
  final String paymentMethod;
  final String customerId;
  final String userWalletBalance;
  final String remarks;
  final String centralBalance;
  final String createdAt;
  final String updatedAt;

  WalletTransaction({
    required this.serialNumber,
    required this.transactionDate,
    required this.transactionTime,
    required this.transactionId,
    this.portalTransactionId,
    this.portalTransactionRemarks1,
    this.portalTransactionRemarks2,
    required this.creditDebit,
    required this.transactionType,
    required this.amount,
    required this.paymentMethod,
    required this.customerId,
    required this.userWalletBalance,
    required this.remarks,
    required this.centralBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      serialNumber: json['serial_number']?.toString() ?? '',
      transactionDate: json['transaction_date'] ?? '',
      transactionTime: json['transaction_time'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      portalTransactionId: json['portal_transaction_id'],
      portalTransactionRemarks1: json['portal_transaction_remarks_1'],
      portalTransactionRemarks2: json['portal_transaction_remarks_2'],
      creditDebit: json['credit_debit'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      amount: json['amount']?.toString() ?? '0',
      paymentMethod: json['payment_method'] ?? '',
      customerId: json['customer_id'] ?? '',
      userWalletBalance: json['user_wallet_balance']?.toString() ?? '0.00',
      remarks: json['remarks'] ?? '',
      centralBalance: json['central_balance']?.toString() ?? '0',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  String formatDateTime() {
    try {
      final dateTime = DateTime.parse(createdAt);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = dateTime.hour >= 12 ? 'pm' : 'am';
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, $hour:$minute $amPm';
    } catch (e) {
      return createdAt;
    }
  }
}

