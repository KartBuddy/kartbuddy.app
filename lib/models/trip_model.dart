class CurrentTripResponse {
  final bool success;
  final String message;
  final CurrentTrip? data;

  CurrentTripResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CurrentTripResponse.fromJson(Map<String, dynamic> json) {
    return CurrentTripResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? CurrentTrip.fromJson(json['data']) : null,
    );
  }
}

class CurrentTrip {
  final String id;
  final String tripId;
  final String tripName;
  final String tripStatus;
  final String driverResponse;
  final String originHub;
  final String? destinationArea;
  final String scheduledDate;
  final int totalOrders;
  final String? notes;
  final String? actualStartTime;
  final String? responseTime;
  final String hubName;
  final String? hubAddress;

  CurrentTrip({
    required this.id,
    required this.tripId,
    required this.tripName,
    required this.tripStatus,
    required this.driverResponse,
    required this.originHub,
    this.destinationArea,
    required this.scheduledDate,
    required this.totalOrders,
    this.notes,
    this.actualStartTime,
    this.responseTime,
    required this.hubName,
    this.hubAddress,
  });

  factory CurrentTrip.fromJson(Map<String, dynamic> json) {
    return CurrentTrip(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      tripName: json['trip_name'] ?? '',
      tripStatus: json['trip_status'] ?? '',
      driverResponse: json['driver_response'] ?? '',
      originHub: json['origin_hub'] ?? '',
      destinationArea: json['destination_area'],
      scheduledDate: json['scheduled_date'] ?? '',
      totalOrders: json['total_orders'] ?? 0,
      notes: json['notes'],
      actualStartTime: json['actual_start_time'],
      responseTime: json['response_time'],
      hubName: json['hub_name'] ?? '',
      hubAddress: json['hub_address'],
    );
  }
}

// Trip History Models
class TripHistoryResponse {
  final bool success;
  final String message;
  final List<TripHistory> data;

  TripHistoryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TripHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TripHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => TripHistory.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TripHistory {
  final String id;
  final String tripId;
  final String tripName;
  final String tripStatus;
  final String driverResponse;
  final String originHub;
  final String? destinationArea;
  final String scheduledDate;
  final int totalOrders;
  final String? notes;
  final String? actualStartTime;
  final String? actualEndTime;
  final String? responseTime;
  final String hubName;
  final String? hubAddress;

  TripHistory({
    required this.id,
    required this.tripId,
    required this.tripName,
    required this.tripStatus,
    required this.driverResponse,
    required this.originHub,
    this.destinationArea,
    required this.scheduledDate,
    required this.totalOrders,
    this.notes,
    this.actualStartTime,
    this.actualEndTime,
    this.responseTime,
    required this.hubName,
    this.hubAddress,
  });

  factory TripHistory.fromJson(Map<String, dynamic> json) {
    return TripHistory(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      tripName: json['trip_name'] ?? '',
      tripStatus: json['trip_status'] ?? '',
      driverResponse: json['driver_response'] ?? '',
      originHub: json['origin_hub'] ?? '',
      destinationArea: json['destination_area'],
      scheduledDate: json['scheduled_date'] ?? '',
      totalOrders: json['total_orders'] ?? 0,
      notes: json['notes'],
      actualStartTime: json['actual_start_time'],
      actualEndTime: json['actual_end_time'],
      responseTime: json['response_time'],
      hubName: json['hub_name'] ?? '',
      hubAddress: json['hub_address'],
    );
  }
}

// Trip Details Models
class TripDetailsResponse {
  final bool success;
  final String message;
  final TripDetails? data;

  TripDetailsResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory TripDetailsResponse.fromJson(Map<String, dynamic> json) {
    return TripDetailsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? TripDetails.fromJson(json['data']) : null,
    );
  }
}

class TripDetails {
  final String id;
  final String tripId;
  final String tripName;
  final String tripStatus;
  final String? assignedDc;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedVehicleId;
  final String? vehicleType;
  final String? city;
  final String originHub;
  final String? destinationArea;
  final String scheduledDate;
  final String? startTime;
  final String? endTime;
  final String? estimatedDuration;
  final int totalOrders;
  final String? color;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? createdBy;
  final String? lastUpdatedBy;
  final String? hubId;
  final String? vendorId;
  final String? assignedDriverUuid;
  final String? assignedVehicleUuid;
  final String? assignedDcUuid;
  final String? driverResponse;
  final String? responseTime;
  final String? rejectionReason;
  final String? actualStartTime;
  final String? actualEndTime;
  final String? actualDuration;
  final String? plannedKm;
  final String? startKm;
  final String? startKmPic;
  final String? endKm;
  final String? endKmPic;
  final String? actualKmDriven;
  final String? kmByGoogle;
  final String hubName;
  final String? hubAddress;
  final double? hubLatitude;
  final double? hubLongitude;
  final List<Order> orders;

  TripDetails({
    required this.id,
    required this.tripId,
    required this.tripName,
    required this.tripStatus,
    this.assignedDc,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedVehicleId,
    this.vehicleType,
    this.city,
    required this.originHub,
    this.destinationArea,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.estimatedDuration,
    required this.totalOrders,
    this.color,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastUpdatedBy,
    this.hubId,
    this.vendorId,
    this.assignedDriverUuid,
    this.assignedVehicleUuid,
    this.assignedDcUuid,
    this.driverResponse,
    this.responseTime,
    this.rejectionReason,
    this.actualStartTime,
    this.actualEndTime,
    this.actualDuration,
    this.plannedKm,
    this.startKm,
    this.startKmPic,
    this.endKm,
    this.endKmPic,
    this.actualKmDriven,
    this.kmByGoogle,
    required this.hubName,
    this.hubAddress,
    this.hubLatitude,
    this.hubLongitude,
    required this.orders,
  });

  factory TripDetails.fromJson(Map<String, dynamic> json) {
    return TripDetails(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      tripName: json['trip_name'] ?? '',
      tripStatus: json['trip_status'] ?? '',
      assignedDc: json['assigned_dc'],
      assignedDriverId: json['assigned_driver_id'],
      assignedDriverName: json['assigned_driver_name'],
      assignedVehicleId: json['assigned_vehicle_id'],
      vehicleType: json['vehicle_type'],
      city: json['city'],
      originHub: json['origin_hub'] ?? '',
      destinationArea: json['destination_area'],
      scheduledDate: json['scheduled_date'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      estimatedDuration: json['estimated_duration'],
      totalOrders: json['total_orders'] ?? 0,
      color: json['color'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      createdBy: json['created_by'],
      lastUpdatedBy: json['last_updated_by'],
      hubId: json['hub_id'],
      vendorId: json['vendor_id'],
      assignedDriverUuid: json['assigned_driver_uuid'],
      assignedVehicleUuid: json['assigned_vehicle_uuid'],
      assignedDcUuid: json['assigned_dc_uuid'],
      driverResponse: json['driver_response'],
      responseTime: json['response_time'],
      rejectionReason: json['rejection_reason'],
      actualStartTime: json['actual_start_time'],
      actualEndTime: json['actual_end_time'],
      actualDuration: json['actual_duration'],
      plannedKm: json['planned_km'],
      startKm: json['start_km'],
      startKmPic: json['start_km_pic'],
      endKm: json['end_km'],
      endKmPic: json['end_km_pic'],
      actualKmDriven: json['actual_km_driven'],
      kmByGoogle: json['km_by_google'],
      hubName: json['hub_name'] ?? '',
      hubAddress: json['hub_address'],
      hubLatitude: json['hub_latitude'] != null ? (json['hub_latitude'] as num).toDouble() : null,
      hubLongitude: json['hub_longitude'] != null ? (json['hub_longitude'] as num).toDouble() : null,
      orders: (json['orders'] as List<dynamic>?)
              ?.map((item) => Order.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Order {
  final String orderId;
  final int pickupSequence;
  final int deliverySequence;
  final String orderStatusInTrip;
  final String pickupAddress;
  final String dropAddress;
  final String pickupContact;
  final String dropContact;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropLatitude;
  final double dropLongitude;
  final bool express;
  final bool codCollection;
  final double codAmount;
  final String? codStatus;
  final int totalUnits;
  final double totalGrossWeight;
  final String hub;
  final String currentHub;
  final String orderStatus;
  final String? tripOrderNotes;
  final String assignedAt;
  final String? pickedUpAt;
  final String? deliveredAt;
  final List<String>? proofOfPickup;
  final List<String>? proofOfDelivery;
  final List<String>? podChallan;

  Order({
    required this.orderId,
    required this.pickupSequence,
    required this.deliverySequence,
    required this.orderStatusInTrip,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupContact,
    required this.dropContact,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropLatitude,
    required this.dropLongitude,
    required this.express,
    required this.codCollection,
    required this.codAmount,
    this.codStatus,
    required this.totalUnits,
    required this.totalGrossWeight,
    required this.hub,
    required this.currentHub,
    required this.orderStatus,
    this.tripOrderNotes,
    required this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.proofOfPickup,
    this.proofOfDelivery,
    this.podChallan,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Parse proof arrays and convert to full URLs
    // Backend returns relative paths like "challans/file-123.png"
    // We need to convert to "https://api.kartbuddy.in/challans/file-123.png"
    List<String>? parseProofUrls(dynamic value) {
      if (value == null) return null;
      
      const String baseUrl = 'https://api.kartbuddy.in/';
      List<String> paths = [];
      
      if (value is List) {
        paths = value.map((e) => e.toString()).toList();
      } else if (value is String && value.isNotEmpty) {
        paths = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      
      if (paths.isEmpty) return null;
      
      // Convert relative paths to full URLs
      return paths.map((path) {
        // If already a full URL, return as is
        if (path.startsWith('http://') || path.startsWith('https://')) {
          return path;
        }
        // Otherwise, prepend base URL
        return baseUrl + path;
      }).toList();
    }

    return Order(
      orderId: json['order_id'] ?? '',
      pickupSequence: json['pickup_sequence'] ?? 0,
      deliverySequence: json['delivery_sequence'] ?? 0,
      orderStatusInTrip: json['order_status_in_trip'] ?? '',
      pickupAddress: json['pickup_address'] ?? '',
      dropAddress: json['drop_address'] ?? '',
      pickupContact: json['pickup_contact'] ?? '',
      dropContact: json['drop_contact'] ?? '',
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble() ?? 0.0,
      dropLatitude: (json['drop_latitude'] as num?)?.toDouble() ?? 0.0,
      dropLongitude: (json['drop_longitude'] as num?)?.toDouble() ?? 0.0,
      express: json['express'] ?? false,
      codCollection: json['cod_collection'] ?? false,
      codAmount: (json['cod_amount'] as num?)?.toDouble() ?? 0.0,
      codStatus: json['cod_status'],
      totalUnits: json['total_units'] ?? 0,
      totalGrossWeight: (json['total_gross_weight'] as num?)?.toDouble() ?? 0.0,
      hub: json['hub'] ?? '',
      currentHub: json['current_hub'] ?? '',
      orderStatus: json['order_status'] ?? '',
      tripOrderNotes: json['trip_order_notes'],
      assignedAt: json['assigned_at'] ?? '',
      pickedUpAt: json['picked_up_at'],
      deliveredAt: json['delivered_at'],
      proofOfPickup: parseProofUrls(json['proof_of_pickup']),
      proofOfDelivery: parseProofUrls(json['proof_of_delivery']),
      podChallan: parseProofUrls(json['pod_challan']),
    );
  }
}
