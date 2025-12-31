import 'dart:convert';

class OrderHistoryResponse {
  final bool success;
  final String message;
  final List<OrderHistoryEvent> data;

  OrderHistoryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OrderHistoryResponse.fromJson(Map<String, dynamic> json) {
    return OrderHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => OrderHistoryEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OrderHistoryEvent {
  final String id;
  final String orderId;
  final String timestamp;
  final String eventType;
  final Map<String, dynamic> eventDetails;
  final String userType;
  final String? userId;
  final String remarks;
  final Map<String, dynamic>? locationSnapshot;
  final Map<String, dynamic>? hubSnapshot;
  final List<dynamic>? attachmentRefs;

  OrderHistoryEvent({
    required this.id,
    required this.orderId,
    required this.timestamp,
    required this.eventType,
    required this.eventDetails,
    required this.userType,
    this.userId,
    required this.remarks,
    this.locationSnapshot,
    this.hubSnapshot,
    this.attachmentRefs,
  });

  factory OrderHistoryEvent.fromJson(Map<String, dynamic> json) {
    return OrderHistoryEvent(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      eventType: json['event_type'] ?? '',
      eventDetails: json['event_details'] as Map<String, dynamic>? ?? {},
      userType: json['user_type'] ?? '',
      userId: json['user_id'],
      remarks: json['remarks'] ?? '',
      locationSnapshot: json['location_snapshot'] as Map<String, dynamic>?,
      hubSnapshot: json['hub_snapshot'] as Map<String, dynamic>?,
      attachmentRefs: json['attachment_refs'] as List<dynamic>?,
    );
  }

  String get formattedEventType {
    if (eventType.isEmpty) return 'N/A';
    return eventType.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String formatTimestamp(String isoString) {
    if (isoString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = dateTime.hour >= 12 ? 'pm' : 'am';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, $hour:$minute $amPm';
    } catch (e) {
      return isoString;
    }
  }

  String get activityBy {
    if (userId != null && userId!.isNotEmpty) {
      return '$userType ($userId)';
    }
    return userType;
  }
}

