import 'dart:convert';

class SaveDimensionRequest {
  final String customerId;
  final String dimensionName;
  final String length;
  final String breadth;
  final String height;
  final String weight;
  final String unitType;

  SaveDimensionRequest({
    required this.customerId,
    required this.dimensionName,
    required this.length,
    required this.breadth,
    required this.height,
    required this.weight,
    required this.unitType,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'dimension_name': dimensionName,
      'length': length,
      'breadth': breadth,
      'height': height,
      'weight': weight,
      'unit_type': unitType,
    };
  }
}

class SaveDimensionResponse {
  final bool success;
  final String message;
  final SavedDimension data;

  SaveDimensionResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SaveDimensionResponse.fromJson(Map<String, dynamic> json) {
    return SaveDimensionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: SavedDimension.fromJson(json['data'] ?? {}),
    );
  }
}

class SavedDimensionsResponse {
  final bool success;
  final String message;
  final List<SavedDimension> data;

  SavedDimensionsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SavedDimensionsResponse.fromJson(Map<String, dynamic> json) {
    return SavedDimensionsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => SavedDimension.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SavedDimension {
  final String id;
  final String customerId;
  final String dimensionName;
  final String length;
  final String breadth;
  final String height;
  final String weight;
  final String unitType;
  final String createdAt;
  final String updatedAt;

  SavedDimension({
    required this.id,
    required this.customerId,
    required this.dimensionName,
    required this.length,
    required this.breadth,
    required this.height,
    required this.weight,
    required this.unitType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedDimension.fromJson(Map<String, dynamic> json) {
    return SavedDimension(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      dimensionName: json['dimension_name'] ?? '',
      length: json['length']?.toString() ?? '0',
      breadth: json['breadth']?.toString() ?? '0',
      height: json['height']?.toString() ?? '0',
      weight: json['weight']?.toString() ?? '0',
      unitType: json['unit_type'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

