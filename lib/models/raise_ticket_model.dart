import 'dart:convert';

class RaiseTicketRequest {
  final String orderId;
  final String subject;
  final String description;
  final String customerId;

  RaiseTicketRequest({
    required this.orderId,
    required this.subject,
    required this.description,
    required this.customerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'subject': subject,
      'description': description,
      'customer_id': customerId,
    };
  }
}

class RaiseTicketResponse {
  final bool success;
  final String message;
  final RaiseTicketData data;

  RaiseTicketResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RaiseTicketResponse.fromJson(Map<String, dynamic> json) {
    return RaiseTicketResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: RaiseTicketData.fromJson(json['data'] ?? {}),
    );
  }
}

class RaiseTicketData {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String orderId;
  final String customerId;
  final String subject;
  final String? otherSubject;
  final String description;
  final String status;
  final String handlerId;
  final Map<String, dynamic> conversations;

  RaiseTicketData({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.orderId,
    required this.customerId,
    required this.subject,
    this.otherSubject,
    required this.description,
    required this.status,
    required this.handlerId,
    required this.conversations,
  });

  factory RaiseTicketData.fromJson(Map<String, dynamic> json) {
    return RaiseTicketData(
      id: json['id'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      orderId: json['order_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      subject: json['subject'] ?? '',
      otherSubject: json['other_subject'],
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      handlerId: json['handler_id'] ?? '',
      conversations: json['conversations'] as Map<String, dynamic>? ?? {},
    );
  }
}

