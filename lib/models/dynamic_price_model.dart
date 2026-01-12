import 'dart:convert';

class DynamicPriceResponse {
  final bool success;
  final String message;
  final DynamicPriceData data;

  DynamicPriceResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DynamicPriceResponse.fromJson(Map<String, dynamic> json) {
    return DynamicPriceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: DynamicPriceData.fromJson(json['data'] ?? {}),
    );
  }
}

class DynamicPriceData {
  final String dynamicPriceId;
  final double baseFarePerKg;
  final double volumetricFactor;
  final double chalaanReturnCharges;
  final double expressDeliverySurchargePercentage;
  final double gstPercentage;
  final double minimumOrderValue;
  final String status;
  final String statusRemark;
  final String createdDateTime;
  final String updatedDateTime;
  final List<CodRange> codRanges;

  DynamicPriceData({
    required this.dynamicPriceId,
    required this.baseFarePerKg,
    required this.volumetricFactor,
    required this.chalaanReturnCharges,
    required this.expressDeliverySurchargePercentage,
    required this.gstPercentage,
    required this.minimumOrderValue,
    required this.status,
    required this.statusRemark,
    required this.createdDateTime,
    required this.updatedDateTime,
    required this.codRanges,
  });

  factory DynamicPriceData.fromJson(Map<String, dynamic> json) {
    return DynamicPriceData(
      dynamicPriceId: json['dynamic_price_id'] ?? '',
      baseFarePerKg: (json['base_fare_per_kg'] != null)
          ? double.tryParse(json['base_fare_per_kg'].toString()) ?? 0.0
          : 0.0,
      volumetricFactor: (json['volumetric_factor'] != null)
          ? double.tryParse(json['volumetric_factor'].toString()) ?? 5000.0
          : 5000.0,
      chalaanReturnCharges: (json['chalaan_return_charges'] != null)
          ? double.tryParse(json['chalaan_return_charges'].toString()) ?? 0.0
          : 0.0,
      expressDeliverySurchargePercentage: (json['express_delivery_surcharge_percentage'] != null)
          ? double.tryParse(json['express_delivery_surcharge_percentage'].toString()) ?? 0.0
          : 0.0,
      gstPercentage: (json['gst_percentage'] != null)
          ? double.tryParse(json['gst_percentage'].toString()) ?? 18.0
          : 18.0,
      minimumOrderValue: (json['minimum_order_value'] != null)
          ? double.tryParse(json['minimum_order_value'].toString()) ?? 0.0
          : 0.0,
      status: json['status'] ?? '',
      statusRemark: json['status_remark'] ?? '',
      createdDateTime: json['created_date_time'] ?? '',
      updatedDateTime: json['updated_date_time'] ?? '',
      codRanges: (json['cod_ranges'] as List<dynamic>?)
              ?.map((e) => CodRange.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CodRange {
  final String id;
  final List<int> range;
  final double charge;

  CodRange({
    required this.id,
    required this.range,
    required this.charge,
  });

  factory CodRange.fromJson(Map<String, dynamic> json) {
    return CodRange(
      id: json['id'] ?? '',
      range: (json['range'] as List<dynamic>?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .toList() ??
          [0, 0],
      charge: (json['charge'] != null)
          ? double.tryParse(json['charge'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

