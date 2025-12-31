class OrdersResponse {
  final bool success;
  final String message;
  final List<Order> data;

  OrdersResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Order.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Order {
  final String id;
  final String orderId;
  final String? tripId;
  final String customerId;
  final String pickupPlaceId;
  final String dropPlaceId;
  final String? driverId;
  final String? driverName;
  final CustomerSnapshot customerSnapshot;
  final PickupSnapshot pickupSnapshot;
  final DropSnapshot dropSnapshot;
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
  final String? challanReturnStatus;
  final String challanCharges;
  final bool codCollection;
  final String codAmount;
  final String? codStatus;
  final String codCharges;
  final List<Dimension> dimensions;
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
  final List<String> proofOfPickup;
  final List<String> proofOfDelivery;
  final List<String> podChallan;
  final List<String> challanFiles;
  final String? currentTripId;
  final String? hubId;
  final String? pickupTime;
  final String? deliveredTime;

  Order({
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
    this.challanReturnStatus,
    required this.challanCharges,
    required this.codCollection,
    required this.codAmount,
    this.codStatus,
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
    this.deliveredTime,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      tripId: json['trip_id'],
      customerId: json['customer_id'] ?? '',
      pickupPlaceId: json['pickup_place_id'] ?? '',
      dropPlaceId: json['drop_place_id'] ?? '',
      driverId: json['driver_id'],
      driverName: json['driver_name'],
      customerSnapshot: CustomerSnapshot.fromJson(json['customer_snapshot'] ?? {}),
      pickupSnapshot: PickupSnapshot.fromJson(json['pickup_snapshot'] ?? {}),
      dropSnapshot: DropSnapshot.fromJson(json['drop_snapshot'] ?? {}),
      pickupLatitude: json['pickup_latitude'] ?? '',
      pickupLongitude: json['pickup_longitude'] ?? '',
      dropLatitude: json['drop_latitude'] ?? '',
      dropLongitude: json['drop_longitude'] ?? '',
      hub: json['hub'] ?? '',
      orderStatus: json['order_status'] ?? '',
      scheduleDate: json['schedule_date'] ?? '',
      preferredPickupTime: json['preferred_pickup_time'] ?? '',
      consigneeClosingTime: json['consignee_closing_time'] ?? '',
      pickupNote: json['pickup_note'] ?? '',
      dropNote: json['drop_note'] ?? '',
      commodity: json['commodity'] ?? '',
      priceModuleType: json['price_module_type'] ?? '',
      expressDelivery: json['express_delivery'] ?? false,
      expressCharges: json['express_charges'] ?? '0.00',
      challanReturn: json['challan_return'] ?? false,
      challanReturnStatus: json['challan_return_status'],
      challanCharges: json['challan_charges'] ?? '0.00',
      codCollection: json['cod_collection'] ?? false,
      codAmount: json['cod_amount'] ?? '0.00',
      codStatus: json['cod_status'],
      codCharges: json['cod_charges'] ?? '0.00',
      dimensions: (json['dimensions'] as List<dynamic>?)
              ?.map((item) => Dimension.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalUnits: (json['total_units'] is int)
          ? json['total_units']
          : (json['total_units'] is double)
              ? json['total_units'].toInt()
              : int.tryParse(json['total_units'].toString()) ?? 0,
      totalGrossWeight: json['total_gross_weight'] ?? '0.00',
      totalVolWeight: json['total_vol_weight'] ?? '0.00',
      totalVolume: json['total_volume'] ?? '0.00',
      chargeableWeight: json['chargeable_weight'] ?? '0.00',
      transportationCharges: json['transportation_charges'] ?? '0.00',
      appliedCoupon: json['applied_coupon'],
      couponDiscount: json['coupon_discount'] ?? '0.00',
      preTaxAmount: json['pre_tax_amount'] ?? '0.00',
      gstPercentage: json['gst_percentage'] ?? '0.00',
      gstAmount: json['gst_amount'] ?? '0.00',
      finalPayable: json['final_payable'] ?? '0.00',
      orderCreationDate: json['order_creation_date'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      lastUpdatedBy: json['last_updated_by'],
      currentHub: json['current_hub'] ?? '',
      proofOfPickup: (json['proof_of_pickup'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      proofOfDelivery: (json['proof_of_delivery'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      podChallan: (json['pod_challan'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      challanFiles: (json['challan_files'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      currentTripId: json['current_trip_id'],
      hubId: json['hub_id'],
      pickupTime: json['pickup_time'],
      deliveredTime: json['delivered_time'],
    );
  }

  // Helper method to format status
  String get formattedStatus {
    if (orderStatus.isEmpty) return 'Unknown';
    return orderStatus[0].toUpperCase() + orderStatus.substring(1);
  }

  // Helper method to format date
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class CustomerSnapshot {
  final String fullName;
  final String? companyName;
  final String? fullAddress;
  final int mobileNumber;

  CustomerSnapshot({
    required this.fullName,
    this.companyName,
    this.fullAddress,
    required this.mobileNumber,
  });

  factory CustomerSnapshot.fromJson(Map<String, dynamic> json) {
    return CustomerSnapshot(
      fullName: json['full_name'] ?? '',
      companyName: json['company_name'],
      fullAddress: json['full_address'],
      mobileNumber: (json['mobile_number'] is int)
          ? json['mobile_number']
          : (json['mobile_number'] is double)
              ? json['mobile_number'].toInt()
              : int.tryParse(json['mobile_number'].toString()) ?? 0,
    );
  }
}

class PickupSnapshot {
  final String address;
  final String companyName;
  final int contactMobile;
  final String contactPerson;

  PickupSnapshot({
    required this.address,
    required this.companyName,
    required this.contactMobile,
    required this.contactPerson,
  });

  factory PickupSnapshot.fromJson(Map<String, dynamic> json) {
    return PickupSnapshot(
      address: json['address'] ?? '',
      companyName: json['company_name'] ?? '',
      contactMobile: (json['contact_mobile'] is int)
          ? json['contact_mobile']
          : (json['contact_mobile'] is double)
              ? json['contact_mobile'].toInt()
              : int.tryParse(json['contact_mobile'].toString()) ?? 0,
      contactPerson: json['contact_person'] ?? '',
    );
  }
}

class DropSnapshot {
  final String address;
  final String companyName;
  final int contactMobile;
  final String contactPerson;

  DropSnapshot({
    required this.address,
    required this.companyName,
    required this.contactMobile,
    required this.contactPerson,
  });

  factory DropSnapshot.fromJson(Map<String, dynamic> json) {
    return DropSnapshot(
      address: json['address'] ?? '',
      companyName: json['company_name'] ?? '',
      contactMobile: (json['contact_mobile'] is int)
          ? json['contact_mobile']
          : (json['contact_mobile'] is double)
              ? json['contact_mobile'].toInt()
              : int.tryParse(json['contact_mobile'].toString()) ?? 0,
      contactPerson: json['contact_person'] ?? '',
    );
  }
}

class Dimension {
  final int id;
  final int units;
  final int height;
  final int length;
  final int breadth;
  final int totalVolume;
  final double totalWeight;
  final double perUnitWeight;
  final double volumetricWeightPerUnit;

  Dimension({
    required this.id,
    required this.units,
    required this.height,
    required this.length,
    required this.breadth,
    required this.totalVolume,
    required this.totalWeight,
    required this.perUnitWeight,
    required this.volumetricWeightPerUnit,
  });

  factory Dimension.fromJson(Map<String, dynamic> json) {
    // Try both camelCase and snake_case field names
    return Dimension(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      units: (json['units'] is int)
          ? json['units']
          : (json['units'] is double)
              ? json['units'].toInt()
              : int.tryParse(json['units']?.toString() ?? '0') ?? 0,
      height: (json['height'] is int)
          ? json['height']
          : (json['height'] is double)
              ? json['height'].toInt()
              : int.tryParse(json['height']?.toString() ?? '0') ?? 0,
      length: (json['length'] is int)
          ? json['length']
          : (json['length'] is double)
              ? json['length'].toInt()
              : int.tryParse(json['length']?.toString() ?? '0') ?? 0,
      breadth: (json['breadth'] is int)
          ? json['breadth']
          : (json['breadth'] is double)
              ? json['breadth'].toInt()
              : int.tryParse(json['breadth']?.toString() ?? '0') ?? 0,
      totalVolume: (json['total_volume'] ?? json['totalVolume'] ?? 0) is int
          ? (json['total_volume'] ?? json['totalVolume'] ?? 0) as int
          : ((json['total_volume'] ?? json['totalVolume'] ?? 0) is double
              ? ((json['total_volume'] ?? json['totalVolume'] ?? 0) as double).toInt()
              : int.tryParse((json['total_volume'] ?? json['totalVolume'] ?? 0).toString()) ?? 0),
      totalWeight: (json['total_weight'] ?? json['totalWeight'] ?? 0.0) is double
          ? (json['total_weight'] ?? json['totalWeight'] ?? 0.0) as double
          : ((json['total_weight'] ?? json['totalWeight'] ?? 0.0) is int
              ? ((json['total_weight'] ?? json['totalWeight'] ?? 0.0) as int).toDouble()
              : double.tryParse((json['total_weight'] ?? json['totalWeight'] ?? 0.0).toString()) ?? 0.0),
      perUnitWeight: (json['per_unit_weight'] ?? json['perUnitWeight'] ?? 0.0) is double
          ? (json['per_unit_weight'] ?? json['perUnitWeight'] ?? 0.0) as double
          : ((json['per_unit_weight'] ?? json['perUnitWeight'] ?? 0.0) is int
              ? ((json['per_unit_weight'] ?? json['perUnitWeight'] ?? 0.0) as int).toDouble()
              : double.tryParse((json['per_unit_weight'] ?? json['perUnitWeight'] ?? 0.0).toString()) ?? 0.0),
      volumetricWeightPerUnit: (json['volumetric_weight_per_unit'] ?? json['volumetricWeightPerUnit'] ?? 0.0) is double
          ? (json['volumetric_weight_per_unit'] ?? json['volumetricWeightPerUnit'] ?? 0.0) as double
          : ((json['volumetric_weight_per_unit'] ?? json['volumetricWeightPerUnit'] ?? 0.0) is int
              ? ((json['volumetric_weight_per_unit'] ?? json['volumetricWeightPerUnit'] ?? 0.0) as int).toDouble()
              : double.tryParse((json['volumetric_weight_per_unit'] ?? json['volumetricWeightPerUnit'] ?? 0.0).toString()) ?? 0.0),
    );
  }
}

