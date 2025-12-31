class DcManagerResponse {
  final bool success;
  final String message;
  final List<DcManager> data;

  DcManagerResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DcManagerResponse.fromJson(Map<String, dynamic> json) {
    return DcManagerResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => DcManager.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DcManager {
  final String id;
  final String branchId;
  final String branchName;
  final String? nearestStation;
  final String? nearestBusStop;
  final String? state;
  final String? city;
  final int? pinCode;
  final double? latitude;
  final double? longitude;
  final String? latLong;
  final String? fullAddress;
  final String? mobileNumber;
  final String? status;
  final String? remark;
  final List<PickupRange>? pickUpRange;
  final List<ConsigneeUpRange>? consigneeUpRange;
  final List<StaffLoginRange>? staffLoginRange;
  final List<DriverLoginRange>? driverLoginRange;
  final String? createdAt;
  final String? updatedAt;

  DcManager({
    required this.id,
    required this.branchId,
    required this.branchName,
    this.nearestStation,
    this.nearestBusStop,
    this.state,
    this.city,
    this.pinCode,
    this.latitude,
    this.longitude,
    this.latLong,
    this.fullAddress,
    this.mobileNumber,
    this.status,
    this.remark,
    this.pickUpRange,
    this.consigneeUpRange,
    this.staffLoginRange,
    this.driverLoginRange,
    this.createdAt,
    this.updatedAt,
  });

  factory DcManager.fromJson(Map<String, dynamic> json) {
    return DcManager(
      id: json['id'] ?? '',
      branchId: json['branch_id'] ?? '',
      branchName: json['branch_name'] ?? '',
      nearestStation: json['nearest_station'],
      nearestBusStop: json['nearest_bus_stop'],
      state: json['state'],
      city: json['city'],
      pinCode: json['pin_code'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      latLong: json['lat_long'],
      fullAddress: json['full_address'],
      mobileNumber: json['mobile_number'],
      status: json['status'],
      remark: json['remark'],
      pickUpRange: json['pick_up_range'] != null
          ? (json['pick_up_range'] as List<dynamic>)
              .map((item) => PickupRange.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      consigneeUpRange: json['consignee_up_range'] != null
          ? (json['consignee_up_range'] as List<dynamic>)
              .map((item) => ConsigneeUpRange.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      staffLoginRange: json['staff_login_range'] != null
          ? (json['staff_login_range'] as List<dynamic>)
              .map((item) => StaffLoginRange.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      driverLoginRange: json['driver_login_range'] != null
          ? (json['driver_login_range'] as List<dynamic>)
              .map((item) => DriverLoginRange.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class PickupRange {
  final double lat;
  final double lng;
  final double radiusKm;
  final String? input;
  final String? id;

  PickupRange({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    this.input,
    this.id,
  });

  factory PickupRange.fromJson(Map<String, dynamic> json) {
    return PickupRange(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radiusKm: (json['radius_km'] as num).toDouble(),
      input: json['input'],
      id: json['id'],
    );
  }
}

class ConsigneeUpRange {
  final double lat;
  final double lng;
  final double radiusKm;
  final String? input;
  final String? id;

  ConsigneeUpRange({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    this.input,
    this.id,
  });

  factory ConsigneeUpRange.fromJson(Map<String, dynamic> json) {
    return ConsigneeUpRange(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radiusKm: (json['radius_km'] as num).toDouble(),
      input: json['input'],
      id: json['id'],
    );
  }
}

class StaffLoginRange {
  final double lat;
  final double lng;
  final double radiusKm;
  final String? input;
  final String? id;

  StaffLoginRange({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    this.input,
    this.id,
  });

  factory StaffLoginRange.fromJson(Map<String, dynamic> json) {
    return StaffLoginRange(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radiusKm: (json['radius_km'] as num).toDouble(),
      input: json['input'],
      id: json['id'],
    );
  }
}

class DriverLoginRange {
  final double lat;
  final double lng;
  final double radiusKm;
  final String? input;
  final String? id;

  DriverLoginRange({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    this.input,
    this.id,
  });

  factory DriverLoginRange.fromJson(Map<String, dynamic> json) {
    return DriverLoginRange(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radiusKm: (json['radius_km'] as num).toDouble(),
      input: json['input'],
      id: json['id'],
    );
  }
}

