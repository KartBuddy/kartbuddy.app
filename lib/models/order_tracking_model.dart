import 'dart:convert';

class OrderTrackingResponse {
  final bool success;
  final String message;
  final OrderTrackingData data;

  OrderTrackingResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OrderTrackingResponse.fromJson(Map<String, dynamic> json) {
    return OrderTrackingResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: OrderTrackingData.fromJson(json['data'] ?? {}),
    );
  }
}

class OrderTrackingData {
  final String orderId;
  final List<TrackingStep> tracking;

  OrderTrackingData({
    required this.orderId,
    required this.tracking,
  });

  factory OrderTrackingData.fromJson(Map<String, dynamic> json) {
    return OrderTrackingData(
      orderId: json['order_id'] ?? '',
      tracking: (json['tracking'] as List<dynamic>?)
              ?.map((item) => TrackingStep.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TrackingStep {
  final String key;
  final String label;
  final String status; // 'completed', 'pending', etc.
  final TrackingMeta? meta;

  TrackingStep({
    required this.key,
    required this.label,
    required this.status,
    this.meta,
  });

  factory TrackingStep.fromJson(Map<String, dynamic> json) {
    return TrackingStep(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      status: json['status'] ?? 'pending',
      meta: json['meta'] != null
          ? TrackingMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
}

class TrackingMeta {
  final String? text;

  TrackingMeta({
    this.text,
  });

  factory TrackingMeta.fromJson(Map<String, dynamic> json) {
    return TrackingMeta(
      text: json['text'],
    );
  }
}

