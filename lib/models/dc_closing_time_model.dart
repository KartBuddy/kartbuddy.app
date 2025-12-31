import 'dart:convert';

class DcClosingTimeResponse {
  final bool success;
  final String message;
  final DcClosingTimeData data;

  DcClosingTimeResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DcClosingTimeResponse.fromJson(Map<String, dynamic> json) {
    return DcClosingTimeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: DcClosingTimeData.fromJson(json['data'] ?? {}),
    );
  }
}

class DcClosingTimeData {
  final String maxOrderTime;

  DcClosingTimeData({
    required this.maxOrderTime,
  });

  factory DcClosingTimeData.fromJson(Map<String, dynamic> json) {
    return DcClosingTimeData(
      maxOrderTime: json['max_order_time'] ?? '09:00:00',
    );
  }
}

class NearestDcRequest {
  final double lat;
  final double lng;
  final String rangeType;

  NearestDcRequest({
    required this.lat,
    required this.lng,
    required this.rangeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'rangeType': rangeType,
    };
  }
}

class NearestDcResponse {
  final bool success;
  final String message;
  final NearestDcData data;

  NearestDcResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory NearestDcResponse.fromJson(Map<String, dynamic> json) {
    return NearestDcResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: NearestDcData.fromJson(json['data'] ?? {}),
    );
  }
}

class NearestDcData {
  final String dcId;
  final String dcName;
  final double distanceKm;

  NearestDcData({
    required this.dcId,
    required this.dcName,
    required this.distanceKm,
  });

  factory NearestDcData.fromJson(Map<String, dynamic> json) {
    return NearestDcData(
      dcId: json['dc_id'] ?? '',
      dcName: json['dc_name'] ?? '',
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
    );
  }
}

class CheckDropServiceRequest {
  final double lat;
  final double lng;

  CheckDropServiceRequest({
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

class CheckDropServiceResponse {
  final bool success;
  final String message;
  final DropServiceData data;

  CheckDropServiceResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CheckDropServiceResponse.fromJson(Map<String, dynamic> json) {
    return CheckDropServiceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: DropServiceData.fromJson(json['data'] ?? {}),
    );
  }
}

class DropServiceData {
  final bool covered;
  final String dcId;
  final String dcName;
  final double distanceKm;

  DropServiceData({
    required this.covered,
    required this.dcId,
    required this.dcName,
    required this.distanceKm,
  });

  factory DropServiceData.fromJson(Map<String, dynamic> json) {
    return DropServiceData(
      covered: json['covered'] ?? false,
      dcId: json['dc_id'] ?? '',
      dcName: json['dc_name'] ?? '',
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
    );
  }
}

