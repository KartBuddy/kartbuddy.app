class SupportTicketsResponse {
  final bool success;
  final String message;
  final List<SupportTicket> data;

  SupportTicketsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SupportTicketsResponse.fromJson(Map<String, dynamic> json) {
    return SupportTicketsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => SupportTicket.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SupportTicket {
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

  SupportTicket({
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

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
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

