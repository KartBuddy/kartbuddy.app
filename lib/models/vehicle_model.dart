class AvailableVehiclesResponse {
  final bool success;
  final String message;
  final List<Vehicle> data;

  AvailableVehiclesResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AvailableVehiclesResponse.fromJson(Map<String, dynamic> json) {
    return AvailableVehiclesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Vehicle {
  final String id;
  final String vehicleId;
  final String vehicleRegistrationNo;
  final String? ownerName;
  final String? ownerAddress;
  final String? ownerMobileNumber;
  final String? vehicleRcCardUpload;
  final String? vehicleRegistrationDate;
  final String? vehicleBrandManufacturer;
  final String? vehicleType;
  final String? vehicleModelName;
  final String? vehicleSubModelName;
  final String? containerSize;
  final String? payloadCapacity;
  final String? totalVolume;
  final String? totalCbm;
  final String? engineNo;
  final String? chasisNo;
  final String? passingUpto;
  final String? insuranceUpto;
  final String? insuranceCopy;
  final String? pucExpiryDate;
  final String? pucCertificateUpload;
  final String? state;
  final String? city;
  final String? intrasddAccess;
  final String? intranddAccess;
  final String? intrafullAccess;
  final String? intrarentalAccess;
  final String? interpartAccess;
  final String? interfullAccess;
  final String? interbidAccess;
  final String? status;
  final String? statusRemark;
  final String? vendorId;
  final String? assignedDcId;
  final String? currentDriverId;
  final String? claimedDate;
  final bool? isAvailable;
  final String? createdAt;
  final String? updatedAt;
  final String? hubName;
  final String? vendorName;
  final String? bodyType;
  final String? fuelType;
  final String? vehicleFrontPic;
  final String? frontLeft45Photo;
  final String? leftSideView;
  final String? rearLeft45Photo;
  final String? backSideView;
  final String? rearRight45Photo;
  final String? rightSideView;
  final String? frontRight45Photo;
  final String? vendorCode;
  final String? branchId;
  final String? branchName;

  Vehicle({
    required this.id,
    required this.vehicleId,
    required this.vehicleRegistrationNo,
    this.ownerName,
    this.ownerAddress,
    this.ownerMobileNumber,
    this.vehicleRcCardUpload,
    this.vehicleRegistrationDate,
    this.vehicleBrandManufacturer,
    this.vehicleType,
    this.vehicleModelName,
    this.vehicleSubModelName,
    this.containerSize,
    this.payloadCapacity,
    this.totalVolume,
    this.totalCbm,
    this.engineNo,
    this.chasisNo,
    this.passingUpto,
    this.insuranceUpto,
    this.insuranceCopy,
    this.pucExpiryDate,
    this.pucCertificateUpload,
    this.state,
    this.city,
    this.intrasddAccess,
    this.intranddAccess,
    this.intrafullAccess,
    this.intrarentalAccess,
    this.interpartAccess,
    this.interfullAccess,
    this.interbidAccess,
    this.status,
    this.statusRemark,
    this.vendorId,
    this.assignedDcId,
    this.currentDriverId,
    this.claimedDate,
    this.isAvailable,
    this.createdAt,
    this.updatedAt,
    this.hubName,
    this.vendorName,
    this.bodyType,
    this.fuelType,
    this.vehicleFrontPic,
    this.frontLeft45Photo,
    this.leftSideView,
    this.rearLeft45Photo,
    this.backSideView,
    this.rearRight45Photo,
    this.rightSideView,
    this.frontRight45Photo,
    this.vendorCode,
    this.branchId,
    this.branchName,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      vehicleRegistrationNo: json['vehicle_registration_no'] ?? '',
      ownerName: json['owner_name'],
      ownerAddress: json['owner_address'],
      ownerMobileNumber: json['owner_mobile_number'],
      vehicleRcCardUpload: json['vehicle_rc_card_upload'],
      vehicleRegistrationDate: json['vehicle_registration_date'],
      vehicleBrandManufacturer: json['vehicle_brand_manufacturer'],
      vehicleType: json['vehicle_type'],
      vehicleModelName: json['vehicle_model_name'],
      vehicleSubModelName: json['vehicle_sub_model_name'],
      containerSize: json['container_size'],
      payloadCapacity: json['payload_capacity'],
      totalVolume: json['total_volume'],
      totalCbm: json['total_cbm'],
      engineNo: json['engine_no'],
      chasisNo: json['chasis_no'],
      passingUpto: json['passing_upto'],
      insuranceUpto: json['insurance_upto'],
      insuranceCopy: json['insurance_copy'],
      pucExpiryDate: json['puc_expiry_date'],
      pucCertificateUpload: json['puc_certificate_upload'],
      state: json['state'],
      city: json['city'],
      intrasddAccess: json['intrasdd_access'],
      intranddAccess: json['intrandd_access'],
      intrafullAccess: json['intrafull_access'],
      intrarentalAccess: json['intrarental_access'],
      interpartAccess: json['interpart_access'],
      interfullAccess: json['interfull_access'],
      interbidAccess: json['interbid_access'],
      status: json['status'],
      statusRemark: json['status_remark'],
      vendorId: json['vendor_id'],
      assignedDcId: json['assigned_dc_id'],
      currentDriverId: json['current_driver_id'],
      claimedDate: json['claimed_date'],
      isAvailable: json['is_available'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      hubName: json['hub_name'],
      vendorName: json['vendor_name'],
      bodyType: json['body_type'],
      fuelType: json['fuel_type'],
      vehicleFrontPic: json['vehicle_front_pic'],
      frontLeft45Photo: json['front_left_45_photo'],
      leftSideView: json['left_side_view'],
      rearLeft45Photo: json['rear_left_45_photo'],
      backSideView: json['back_side_view'],
      rearRight45Photo: json['rear_right_45_photo'],
      rightSideView: json['right_side_view'],
      frontRight45Photo: json['front_right_45_photo'],
      vendorCode: json['vendor_code'],
      branchId: json['branch_id'],
      branchName: json['branch_name'],
    );
  }
}

