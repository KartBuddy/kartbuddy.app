import 'dart:convert';

class BankingDetailsResponse {
  final bool success;
  final String message;
  final List<BankingDetail> data;

  BankingDetailsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BankingDetailsResponse.fromJson(Map<String, dynamic> json) {
    return BankingDetailsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => BankingDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BankingDetail {
  final String bankId;
  final String upiId;
  final String qrCodeImage;
  final String bankName;
  final String accountName;
  final String ifscCode;
  final String additionDate;
  final bool primaryStatus;
  final String status;
  final String statusRemark;
  final String accountNumber;

  BankingDetail({
    required this.bankId,
    required this.upiId,
    required this.qrCodeImage,
    required this.bankName,
    required this.accountName,
    required this.ifscCode,
    required this.additionDate,
    required this.primaryStatus,
    required this.status,
    required this.statusRemark,
    required this.accountNumber,
  });

  factory BankingDetail.fromJson(Map<String, dynamic> json) {
    return BankingDetail(
      bankId: json['bank_id'] ?? '',
      upiId: json['upi_id'] ?? '',
      qrCodeImage: json['qr_code_image'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountName: json['account_name'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      additionDate: json['addition_date'] ?? '',
      primaryStatus: json['primary_status'] ?? false,
      status: json['status'] ?? '',
      statusRemark: json['status_remark'] ?? '',
      accountNumber: json['account_number'] ?? '',
    );
  }
}

