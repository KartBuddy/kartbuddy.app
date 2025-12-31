import 'dart:convert';

class PlaceManagerResponse {
  final bool success;
  final String message;
  final List<PlaceManagerData> data;

  PlaceManagerResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PlaceManagerResponse.fromJson(Map<String, dynamic> json) {
    return PlaceManagerResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => PlaceManagerData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PlaceManagerData {
  final String id;
  final String placeId;
  final String companyName;
  final String placeType;
  final String addressLine1;
  final String addressLine2;
  final String nearestRailwayStation;
  final String nearestBusStop;
  final String landmark;
  final String city;
  final String state;
  final int pincode;
  final String fullAddress;
  final String latitude;
  final String longitude;
  final String contactPersonName;
  final String contactPersonMobile;
  final String alternateNumber;
  final String parkingPlaceAvailability;
  final String createdAt;
  final String updatedAt;
  final String placeSource;
  final String placeSourceName;
  final String createdBy;
  final String status;
  final String? statusRemarks;
  final String? gstNo;
  final String connectedHub;
  final String searchIdentifier;

  PlaceManagerData({
    required this.id,
    required this.placeId,
    required this.companyName,
    required this.placeType,
    required this.addressLine1,
    required this.addressLine2,
    required this.nearestRailwayStation,
    required this.nearestBusStop,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.contactPersonName,
    required this.contactPersonMobile,
    required this.alternateNumber,
    required this.parkingPlaceAvailability,
    required this.createdAt,
    required this.updatedAt,
    required this.placeSource,
    required this.placeSourceName,
    required this.createdBy,
    required this.status,
    this.statusRemarks,
    this.gstNo,
    required this.connectedHub,
    required this.searchIdentifier,
  });

  factory PlaceManagerData.fromJson(Map<String, dynamic> json) {
    return PlaceManagerData(
      id: json['id'] ?? '',
      placeId: json['place_id'] ?? '',
      companyName: json['company_name'] ?? '',
      placeType: json['place_type'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'] ?? '',
      nearestRailwayStation: json['nearest_railway_station'] ?? '',
      nearestBusStop: json['nearest_bus_stop'] ?? '',
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? 0,
      fullAddress: json['full_address'] ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      contactPersonName: json['contact_person_name'] ?? '',
      contactPersonMobile: json['contact_person_mobile']?.toString() ?? '',
      alternateNumber: json['alternate_number']?.toString() ?? '',
      parkingPlaceAvailability: json['parking_place_availability'] ?? 'NO',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      placeSource: json['place_source'] ?? '',
      placeSourceName: json['place_source_name'] ?? '',
      createdBy: json['created_by'] ?? '',
      status: json['status'] ?? '',
      statusRemarks: json['status_remarks'],
      gstNo: json['gst_no'],
      connectedHub: json['connected_hub'] ?? '',
      searchIdentifier: json['search_identifier'] ?? '',
    );
  }
}

class PlaceRegisterRequest {
  final String contactPersonName;
  final String companyName;
  final String? gstNo;
  final String addressLine1;
  final String addressLine2;
  final String alternateNumber;
  final String city;
  final String connectedHub;
  final String contactPersonMobile;
  final String createdBy;
  final double latitude;
  final double longitude;
  final String nearestBusStop;
  final String nearestRailwayStation;
  final String landmark;
  final String parkingPlaceAvailability;
  final int pincode;
  final String placeSource;
  final String placeSourceName;
  final String placeType;
  final String state;
  final String status;

  PlaceRegisterRequest({
    required this.contactPersonName,
    required this.companyName,
    this.gstNo,
    required this.addressLine1,
    required this.addressLine2,
    required this.alternateNumber,
    required this.city,
    required this.connectedHub,
    required this.contactPersonMobile,
    required this.createdBy,
    required this.latitude,
    required this.longitude,
    required this.nearestBusStop,
    required this.nearestRailwayStation,
    required this.landmark,
    required this.parkingPlaceAvailability,
    required this.pincode,
    required this.placeSource,
    required this.placeSourceName,
    required this.placeType,
    required this.state,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'contact_person_name': contactPersonName,
      'company_name': companyName,
      if (gstNo != null && gstNo!.isNotEmpty) 'gst_no': gstNo,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'alternate_number': alternateNumber,
      'city': city,
      'connected_hub': connectedHub,
      'contact_person_mobile': contactPersonMobile,
      'created_by': createdBy,
      'latitude': latitude,
      'longitude': longitude,
      'nearest_bus_stop': nearestBusStop,
      'nearest_railway_station': nearestRailwayStation,
      'landmark': landmark,
      'parking_place_availability': parkingPlaceAvailability,
      'pincode': pincode,
      'place_source': placeSource,
      'place_source_name': placeSourceName,
      'place_type': placeType,
      'state': state,
      'status': status,
    };
  }
}

class PlaceRegisterResponse {
  final bool success;
  final String message;
  final dynamic data;

  PlaceRegisterResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PlaceRegisterResponse.fromJson(Map<String, dynamic> json) {
    return PlaceRegisterResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: json['data'],
    );
  }
}

class PlaceDeleteResponse {
  final bool success;
  final String message;
  final PlaceManagerData data;

  PlaceDeleteResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PlaceDeleteResponse.fromJson(Map<String, dynamic> json) {
    return PlaceDeleteResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: PlaceManagerData.fromJson(json['data'] ?? {}),
    );
  }
}

class PlaceUpdateRequest {
  final String contactPersonName;
  final String companyName;
  final String? gstNo;
  final String addressLine1;
  final String addressLine2;
  final String alternateNumber;
  final String city;
  final String connectedHub;
  final String contactPersonMobile;
  final String createdBy;
  final double latitude;
  final double longitude;
  final String nearestBusStop;
  final String nearestRailwayStation;
  final String landmark;
  final String parkingPlaceAvailability;
  final int pincode;
  final String placeSource;
  final String placeSourceName;
  final String state;
  final String status;

  PlaceUpdateRequest({
    required this.contactPersonName,
    required this.companyName,
    this.gstNo,
    required this.addressLine1,
    required this.addressLine2,
    required this.alternateNumber,
    required this.city,
    required this.connectedHub,
    required this.contactPersonMobile,
    required this.createdBy,
    required this.latitude,
    required this.longitude,
    required this.nearestBusStop,
    required this.nearestRailwayStation,
    required this.landmark,
    required this.parkingPlaceAvailability,
    required this.pincode,
    required this.placeSource,
    required this.placeSourceName,
    required this.state,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'contact_person_name': contactPersonName,
      'company_name': companyName,
      if (gstNo != null && gstNo!.isNotEmpty) 'gst_no': gstNo,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'alternate_number': alternateNumber,
      'city': city,
      'connected_hub': connectedHub,
      'contact_person_mobile': contactPersonMobile,
      'created_by': createdBy,
      'latitude': latitude,
      'longitude': longitude,
      'nearest_bus_stop': nearestBusStop,
      'nearest_railway_station': nearestRailwayStation,
      'landmark': landmark,
      'parking_place_availability': parkingPlaceAvailability,
      'pincode': pincode,
      'place_source': placeSource,
      'place_source_name': placeSourceName,
      'state': state,
      'status': status,
    };
  }
}

class PlaceUpdateResponse {
  final bool success;
  final String message;
  final PlaceManagerData data;

  PlaceUpdateResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PlaceUpdateResponse.fromJson(Map<String, dynamic> json) {
    return PlaceUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: PlaceManagerData.fromJson(json['data'] ?? {}),
    );
  }
}

