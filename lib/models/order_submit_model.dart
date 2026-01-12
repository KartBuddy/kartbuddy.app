import 'dart:convert';

class OrderSubmitRequest {
  final String customerId;
  final String pickupPlaceId;
  final String dropPlaceId;
  final String scheduleDate;
  final String preferredPickupTime;
  final String consigneeClosingTime;
  final String pickupNote;
  final String dropNote;
  final List<String> commodity;
  final String priceModuleType;
  final bool expressDelivery;
  final String expressCharges;
  final bool challanReturn;
  final String challanCharges;
  final String challanReturnStatus;
  final bool codCollection;
  final String? codAmount;
  final String codStatus;
  final String codCharges;
  final List<DimensionData> dimensions;
  final int totalUnits;
  final String totalGrossWeight;
  final String totalVolWeight;
  final String totalVolume;
  final String chargeableWeight;
  final String transportationCharges;
  final String couponDiscount;
  final String preTaxAmount;
  final String gstPercentage;
  final String gstAmount;
  final String finalPayable;
  final String totalCommodityValue;
  final String paymentMode;

  OrderSubmitRequest({
    required this.customerId,
    required this.pickupPlaceId,
    required this.dropPlaceId,
    required this.scheduleDate,
    required this.preferredPickupTime,
    required this.consigneeClosingTime,
    required this.pickupNote,
    required this.dropNote,
    required this.commodity,
    required this.priceModuleType,
    required this.expressDelivery,
    required this.expressCharges,
    required this.challanReturn,
    required this.challanCharges,
    required this.challanReturnStatus,
    required this.codCollection,
    this.codAmount,
    required this.codStatus,
    required this.codCharges,
    required this.dimensions,
    required this.totalUnits,
    required this.totalGrossWeight,
    required this.totalVolWeight,
    required this.totalVolume,
    required this.chargeableWeight,
    required this.transportationCharges,
    required this.couponDiscount,
    required this.preTaxAmount,
    required this.gstPercentage,
    required this.gstAmount,
    required this.finalPayable,
    required this.totalCommodityValue,
    required this.paymentMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'pickup_place_id': pickupPlaceId,
      'drop_place_id': dropPlaceId,
      'schedule_date': scheduleDate,
      'preferred_pickup_time': preferredPickupTime,
      'consignee_closing_time': consigneeClosingTime,
      'pickup_note': pickupNote,
      'drop_note': dropNote,
      'commodity': jsonEncode(commodity),
      'price_module_type': priceModuleType,
      'express_delivery': expressDelivery,
      'express_charges': expressCharges,
      'challan_return': challanReturn,
      'challan_charges': challanCharges,
      'challan_return_status': challanReturnStatus,
      'cod_collection': codCollection,
      if (codAmount != null) 'cod_amount': codAmount,
      'cod_status': codStatus,
      'cod_charges': codCharges,
      'dimensions': jsonEncode(dimensions.map((d) => d.toJson()).toList()),
      'total_units': totalUnits,
      'total_gross_weight': totalGrossWeight,
      'total_vol_weight': totalVolWeight,
      'total_volume': totalVolume,
      'chargeable_weight': chargeableWeight,
      'transportation_charges': transportationCharges,
      'coupon_discount': couponDiscount,
      'pre_tax_amount': preTaxAmount,
      'gst_percentage': gstPercentage,
      'gst_amount': gstAmount,
      'final_payable': finalPayable,
      'total_commodity_value': totalCommodityValue,
      'payment_mode': paymentMode,
    };
  }
}

class DimensionData {
  final int id;
  final String length;
  final String breadth;
  final String height;
  final int units;
  final String perUnitWeight;
  final String volumetricWeightPerUnit;
  final String totalVolume;
  final String totalWeight;

  DimensionData({
    required this.id,
    required this.length,
    required this.breadth,
    required this.height,
    required this.units,
    required this.perUnitWeight,
    required this.volumetricWeightPerUnit,
    required this.totalVolume,
    required this.totalWeight,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'length': double.parse(length),
      'breadth': double.parse(breadth),
      'height': double.parse(height),
      'units': units,
      'perUnitWeight': double.parse(perUnitWeight),
      'volumetricWeightPerUnit': double.parse(volumetricWeightPerUnit),
      'totalVolume': double.parse(totalVolume),
      'totalWeight': double.parse(totalWeight),
    };
  }
}

class OrderSubmitResponse {
  final bool success;
  final String message;
  final OrderData data;

  OrderSubmitResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OrderSubmitResponse.fromJson(Map<String, dynamic> json) {
    return OrderSubmitResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: OrderData.fromJson(json['data'] ?? {}),
    );
  }
}

class OrderData {
  final String id;
  final String orderId;
  final String? tripId;
  final String customerId;
  final String pickupPlaceId;
  final String dropPlaceId;
  final String? driverId;
  final String? driverName;
  final Map<String, dynamic> customerSnapshot;
  final Map<String, dynamic> pickupSnapshot;
  final Map<String, dynamic> dropSnapshot;
  final String pickupLatitude;
  final String pickupLongitude;
  final String dropLatitude;
  final String dropLongitude;
  final String hub;
  final String orderStatus;
  final String scheduleDate;
  final String preferredPickupTime;
  final String consigneeClosingTime;
  final String pickupNote;
  final String dropNote;
  final String commodity;
  final String priceModuleType;
  final bool expressDelivery;
  final String expressCharges;
  final bool challanReturn;
  final String challanReturnStatus;
  final String challanCharges;
  final bool codCollection;
  final String codAmount;
  final String codStatus;
  final String codCharges;
  final List<dynamic> dimensions;
  final int totalUnits;
  final String totalGrossWeight;
  final String totalVolWeight;
  final String totalVolume;
  final String chargeableWeight;
  final String transportationCharges;
  final String? appliedCoupon;
  final String couponDiscount;
  final String preTaxAmount;
  final String gstPercentage;
  final String gstAmount;
  final String finalPayable;
  final String orderCreationDate;
  final String updatedAt;
  final String? lastUpdatedBy;
  final String currentHub;
  final List<dynamic> proofOfPickup;
  final List<dynamic> proofOfDelivery;
  final List<dynamic> podChallan;
  final List<String> challanFiles;
  final String? currentTripId;
  final String? hubId;
  final String? pickupTime;
  final String deliveredTime;

  OrderData({
    required this.id,
    required this.orderId,
    this.tripId,
    required this.customerId,
    required this.pickupPlaceId,
    required this.dropPlaceId,
    this.driverId,
    this.driverName,
    required this.customerSnapshot,
    required this.pickupSnapshot,
    required this.dropSnapshot,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropLatitude,
    required this.dropLongitude,
    required this.hub,
    required this.orderStatus,
    required this.scheduleDate,
    required this.preferredPickupTime,
    required this.consigneeClosingTime,
    required this.pickupNote,
    required this.dropNote,
    required this.commodity,
    required this.priceModuleType,
    required this.expressDelivery,
    required this.expressCharges,
    required this.challanReturn,
    required this.challanReturnStatus,
    required this.challanCharges,
    required this.codCollection,
    required this.codAmount,
    required this.codStatus,
    required this.codCharges,
    required this.dimensions,
    required this.totalUnits,
    required this.totalGrossWeight,
    required this.totalVolWeight,
    required this.totalVolume,
    required this.chargeableWeight,
    required this.transportationCharges,
    this.appliedCoupon,
    required this.couponDiscount,
    required this.preTaxAmount,
    required this.gstPercentage,
    required this.gstAmount,
    required this.finalPayable,
    required this.orderCreationDate,
    required this.updatedAt,
    this.lastUpdatedBy,
    required this.currentHub,
    required this.proofOfPickup,
    required this.proofOfDelivery,
    required this.podChallan,
    required this.challanFiles,
    this.currentTripId,
    this.hubId,
    this.pickupTime,
    required this.deliveredTime,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      tripId: json['trip_id'],
      customerId: json['customer_id'] ?? '',
      pickupPlaceId: json['pickup_place_id'] ?? '',
      dropPlaceId: json['drop_place_id'] ?? '',
      driverId: json['driver_id'],
      driverName: json['driver_name'],
      customerSnapshot: json['customer_snapshot'] as Map<String, dynamic>? ?? {},
      pickupSnapshot: json['pickup_snapshot'] as Map<String, dynamic>? ?? {},
      dropSnapshot: json['drop_snapshot'] as Map<String, dynamic>? ?? {},
      pickupLatitude: json['pickup_latitude']?.toString() ?? '',
      pickupLongitude: json['pickup_longitude']?.toString() ?? '',
      dropLatitude: json['drop_latitude']?.toString() ?? '',
      dropLongitude: json['drop_longitude']?.toString() ?? '',
      hub: json['hub'] ?? '',
      orderStatus: json['order_status'] ?? '',
      scheduleDate: json['schedule_date'] ?? '',
      preferredPickupTime: json['preferred_pickup_time'] ?? '',
      consigneeClosingTime: json['consignee_closing_time'] ?? '',
      pickupNote: json['pickup_note'] ?? '',
      dropNote: json['drop_note'] ?? '',
      commodity: json['commodity']?.toString() ?? '',
      priceModuleType: json['price_module_type'] ?? '',
      expressDelivery: json['express_delivery'] ?? false,
      expressCharges: json['express_charges']?.toString() ?? '0',
      challanReturn: json['challan_return'] ?? false,
      challanReturnStatus: json['challan_return_status'] ?? '',
      challanCharges: json['challan_charges']?.toString() ?? '0',
      codCollection: json['cod_collection'] ?? false,
      codAmount: json['cod_amount']?.toString() ?? '0',
      codStatus: json['cod_status'] ?? '',
      codCharges: json['cod_charges']?.toString() ?? '0',
      dimensions: json['dimensions'] as List<dynamic>? ?? [],
      totalUnits: json['total_units'] ?? 0,
      totalGrossWeight: json['total_gross_weight']?.toString() ?? '0',
      totalVolWeight: json['total_vol_weight']?.toString() ?? '0',
      totalVolume: json['total_volume']?.toString() ?? '0',
      chargeableWeight: json['chargeable_weight']?.toString() ?? '0',
      transportationCharges: json['transportation_charges']?.toString() ?? '0',
      appliedCoupon: json['applied_coupon'],
      couponDiscount: json['coupon_discount']?.toString() ?? '0',
      preTaxAmount: json['pre_tax_amount']?.toString() ?? '0',
      gstPercentage: json['gst_percentage']?.toString() ?? '18',
      gstAmount: json['gst_amount']?.toString() ?? '0',
      finalPayable: json['final_payable']?.toString() ?? '0',
      orderCreationDate: json['order_creation_date'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      lastUpdatedBy: json['last_updated_by'],
      currentHub: json['current_hub'] ?? '',
      proofOfPickup: json['proof_of_pickup'] as List<dynamic>? ?? [],
      proofOfDelivery: json['proof_of_delivery'] as List<dynamic>? ?? [],
      podChallan: json['pod_challan'] as List<dynamic>? ?? [],
      challanFiles: (json['challan_files'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      currentTripId: json['current_trip_id'],
      hubId: json['hub_id'],
      pickupTime: json['pickup_time'],
      deliveredTime: json['delivered_time'] ?? '',
    );
  }
}

