import 'dart:convert';

class FixedPriceDimensionsResponse {
  final bool success;
  final String message;
  final List<FixedPriceDimension> data;

  FixedPriceDimensionsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FixedPriceDimensionsResponse.fromJson(Map<String, dynamic> json) {
    return FixedPriceDimensionsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => FixedPriceDimension.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FixedPriceDimension {
  final String id;
  final String customerId;
  final String customerName;
  final String dimensionId;
  final String dimensionName;
  final String length;
  final String breadth;
  final String height;
  final String weight;
  final String dimensionCharge;
  final String volumetricFactor;
  final String chalaanReturnCharges;
  final String expressDeliveryPercentage;
  final String gstPercentage;
  final String minimumOrderValue;
  final CodRange? codRange1;
  final String? codCharge1;
  final CodRange? codRange2;
  final String? codCharge2;
  final CodRange? codRange3;
  final String? codCharge3;
  final CodRange? codRange4;
  final String? codCharge4;
  final CodRange? codRange5;
  final String? codCharge5;
  final CodRange? codRange6;
  final String? codCharge6;
  final String status;
  final String statusRemarks;
  final String createdDateTime;
  final String updatedDateTime;

  FixedPriceDimension({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.dimensionId,
    required this.dimensionName,
    required this.length,
    required this.breadth,
    required this.height,
    required this.weight,
    required this.dimensionCharge,
    required this.volumetricFactor,
    required this.chalaanReturnCharges,
    required this.expressDeliveryPercentage,
    required this.gstPercentage,
    required this.minimumOrderValue,
    this.codRange1,
    this.codCharge1,
    this.codRange2,
    this.codCharge2,
    this.codRange3,
    this.codCharge3,
    this.codRange4,
    this.codCharge4,
    this.codRange5,
    this.codCharge5,
    this.codRange6,
    this.codCharge6,
    required this.status,
    required this.statusRemarks,
    required this.createdDateTime,
    required this.updatedDateTime,
  });

  factory FixedPriceDimension.fromJson(Map<String, dynamic> json) {
    return FixedPriceDimension(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      dimensionId: json['dimension_id'] ?? '',
      dimensionName: json['dimension_name'] ?? '',
      length: json['length']?.toString() ?? '0',
      breadth: json['breadth']?.toString() ?? '0',
      height: json['height']?.toString() ?? '0',
      weight: json['weight']?.toString() ?? '0',
      dimensionCharge: json['dimension_charge']?.toString() ?? '0',
      volumetricFactor: json['volumetric_factor']?.toString() ?? '6000',
      chalaanReturnCharges: json['chalaan_return_charges']?.toString() ?? '0',
      expressDeliveryPercentage: json['express_delivery_percentage']?.toString() ?? '0',
      gstPercentage: json['gst_percentage']?.toString() ?? '0',
      minimumOrderValue: json['minimum_order_value']?.toString() ?? '0',
      codRange1: json['cod_range_1'] != null
          ? CodRange.fromJson(json['cod_range_1'] as Map<String, dynamic>)
          : null,
      codCharge1: json['cod_charge_1']?.toString(),
      codRange2: json['cod_range_2'] != null
          ? CodRange.fromJson(json['cod_range_2'] as Map<String, dynamic>)
          : null,
      codCharge2: json['cod_charge_2']?.toString(),
      codRange3: json['cod_range_3'] != null
          ? CodRange.fromJson(json['cod_range_3'] as Map<String, dynamic>)
          : null,
      codCharge3: json['cod_charge_3']?.toString(),
      codRange4: json['cod_range_4'] != null
          ? CodRange.fromJson(json['cod_range_4'] as Map<String, dynamic>)
          : null,
      codCharge4: json['cod_charge_4']?.toString(),
      codRange5: json['cod_range_5'] != null
          ? CodRange.fromJson(json['cod_range_5'] as Map<String, dynamic>)
          : null,
      codCharge5: json['cod_charge_5']?.toString(),
      codRange6: json['cod_range_6'] != null
          ? CodRange.fromJson(json['cod_range_6'] as Map<String, dynamic>)
          : null,
      codCharge6: json['cod_charge_6']?.toString(),
      status: json['status'] ?? '',
      statusRemarks: json['status_remarks'] ?? '',
      createdDateTime: json['created_date_time'] ?? '',
      updatedDateTime: json['updated_date_time'] ?? '',
    );
  }
}

class CodRange {
  final int min;
  final int max;

  CodRange({
    required this.min,
    required this.max,
  });

  factory CodRange.fromJson(Map<String, dynamic> json) {
    return CodRange(
      min: json['min'] ?? 0,
      max: json['max'] ?? 0,
    );
  }
}

