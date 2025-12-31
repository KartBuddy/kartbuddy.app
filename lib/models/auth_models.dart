class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class Customer {
  final String id;
  final String? email;
  final String? mobileNumber;
  final String fullName;
  final String appRole;

  Customer({
    required this.id,
    this.email,
    this.mobileNumber,
    required this.fullName,
    required this.appRole,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    // Handle both 'id' and 'customer_id' fields
    final id = json['id'] ?? json['customer_id'] ?? '';
    return Customer(
      id: id,
      email: json['email'],
      mobileNumber: json['mobile_number'],
      fullName: json['full_name'] ?? '',
      appRole: json['app_role'] ?? '',
    );
  }
}

class LoginResponse {
  final String message;
  final LoginData data;

  LoginResponse({
    required this.message,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? '',
      data: LoginData.fromJson(json['data'] ?? {}),
    );
  }
}

class LoginData {
  final Customer customer;
  final String token;

  LoginData({
    required this.customer,
    required this.token,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      customer: Customer.fromJson(json['customer'] ?? {}),
      token: json['token'] ?? '',
    );
  }
}

// Registration Models
class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String password;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile_number': mobileNumber,
      'password': password,
    };
  }
}

class RegisterResponse {
  final bool success;
  final String message;
  final RegisterData data;

  RegisterResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: RegisterData.fromJson(json['data'] ?? {}),
    );
  }
}

class RegisterData {
  final Customer customer;
  final String token;

  RegisterData({
    required this.customer,
    required this.token,
  });

  factory RegisterData.fromJson(Map<String, dynamic> json) {
    return RegisterData(
      customer: Customer.fromJson(json['customer'] ?? {}),
      token: json['token'] ?? '',
    );
  }
}

// Driver Models
class Driver {
  final String id;
  final String driverId;
  final String? email;
  final String? mobileNumber;
  final String fullName;
  final String appRole;
  final String? profilePicture;
  final String? currentAddressProof;
  final String? panCardPhoto;
  final String? aadharFrontPhoto;
  final String? aadharBackPhoto;
  final String? drivingLicencePhoto;

  Driver({
    required this.id,
    required this.driverId,
    this.email,
    this.mobileNumber,
    required this.fullName,
    required this.appRole,
    this.profilePicture,
    this.currentAddressProof,
    this.panCardPhoto,
    this.aadharFrontPhoto,
    this.aadharBackPhoto,
    this.drivingLicencePhoto,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      driverId: json['driver_id'] ?? '',
      email: json['email'],
      mobileNumber: json['mobile_number'],
      fullName: json['full_name'] ?? '',
      appRole: json['app_role'] ?? '',
      profilePicture: json['profile_picture'],
      currentAddressProof: json['current_address_proof'],
      panCardPhoto: json['pan_card_photo'],
      aadharFrontPhoto: json['aadhar_front_photo'],
      aadharBackPhoto: json['aadhar_back_photo'],
      drivingLicencePhoto: json['driving_licence_photo'],
    );
  }
}

class DriverLoginResponse {
  final bool success;
  final String message;
  final DriverLoginData data;

  DriverLoginResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DriverLoginResponse.fromJson(Map<String, dynamic> json) {
    return DriverLoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: DriverLoginData.fromJson(json['data'] ?? {}),
    );
  }
}

class DriverLoginData {
  final Driver driver;
  final String token;

  DriverLoginData({
    required this.driver,
    required this.token,
  });

  factory DriverLoginData.fromJson(Map<String, dynamic> json) {
    return DriverLoginData(
      driver: Driver.fromJson(json['driver'] ?? {}),
      token: json['token'] ?? '',
    );
  }
}

// Driver Profile Models
class DriverProfileResponse {
  final bool success;
  final String message;
  final DriverProfileDetails data;

  DriverProfileResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DriverProfileResponse.fromJson(Map<String, dynamic> json) {
    return DriverProfileResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: DriverProfileDetails.fromJson(json['data'] ?? {}),
    );
  }
}

class DriverProfileDetails {
  final String id;
  final String driverId;
  final String appRole;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? email;
  final String? mobileNumber;
  final String? alternateNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? state;
  final String? city;
  final String? pinCode;
  final String? fullAddress;
  final String? currentAddressProof;
  final String? currentAddress;
  final String? vendorId;
  final String? vendorName;
  final String? vendorCode;
  final String? panCardNo;
  final String? panCardPhoto;
  final String? aadharNo;
  final String? aadharFrontPhoto;
  final String? aadharBackPhoto;
  final String? drivingLicenceNo;
  final String? drivingLicencePhoto;
  final String? profilePicture;
  final String codHoldings;
  final String chalanHoldings;
  final int totalDeliveries;
  final String customerRatings;
  final String? referralCode;
  final String? referenceCode;
  final String status;
  final String? statusRemark;
  final String? lastDeviceUsed;
  final String? currentDeviceUsing;
  final String createdAt;
  final String updatedAt;
  final List<String>? assignedDcId;
  final String? currentVehicleId;
  final bool isActiveToday;
  final String? sessionStartTime;
  final String? lastActiveDate;
  final String? intraSddAccess;
  final String? intraNddAccess;
  final String? intraFtlAccess;
  final String? intraRentalAccess;
  final String? interPtlAccess;
  final String? interFtlAccess;
  final String? interBiddingAccess;

  DriverProfileDetails({
    required this.id,
    required this.driverId,
    required this.appRole,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.email,
    this.mobileNumber,
    this.alternateNumber,
    this.addressLine1,
    this.addressLine2,
    this.state,
    this.city,
    this.pinCode,
    this.fullAddress,
    this.currentAddressProof,
    this.currentAddress,
    this.vendorId,
    this.vendorName,
    this.vendorCode,
    this.panCardNo,
    this.panCardPhoto,
    this.aadharNo,
    this.aadharFrontPhoto,
    this.aadharBackPhoto,
    this.drivingLicenceNo,
    this.drivingLicencePhoto,
    this.profilePicture,
    required this.codHoldings,
    required this.chalanHoldings,
    required this.totalDeliveries,
    required this.customerRatings,
    this.referralCode,
    this.referenceCode,
    required this.status,
    this.statusRemark,
    this.lastDeviceUsed,
    this.currentDeviceUsing,
    required this.createdAt,
    required this.updatedAt,
    this.assignedDcId,
    this.currentVehicleId,
    required this.isActiveToday,
    this.sessionStartTime,
    this.lastActiveDate,
    this.intraSddAccess,
    this.intraNddAccess,
    this.intraFtlAccess,
    this.intraRentalAccess,
    this.interPtlAccess,
    this.interFtlAccess,
    this.interBiddingAccess,
  });

  factory DriverProfileDetails.fromJson(Map<String, dynamic> json) {
    return DriverProfileDetails(
      id: json['id'] ?? '',
      driverId: json['driver_id'] ?? '',
      appRole: json['app_role'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'],
      mobileNumber: json['mobile_number'],
      alternateNumber: json['alternate_number'],
      addressLine1: json['address_line_1'],
      addressLine2: json['address_line_2'],
      state: json['state'],
      city: json['city'],
      pinCode: json['pin_code'],
      fullAddress: json['full_address'],
      currentAddressProof: json['current_address_proof'],
      currentAddress: json['current_address'],
      vendorId: json['vendor_id'],
      vendorName: json['vendor_name'],
      vendorCode: json['vendor_code'],
      panCardNo: json['pan_card_no'],
      panCardPhoto: json['pan_card_photo'],
      aadharNo: json['aadhar_no'],
      aadharFrontPhoto: json['aadhar_front_photo'],
      aadharBackPhoto: json['aadhar_back_photo'],
      drivingLicenceNo: json['driving_licence_no'],
      drivingLicencePhoto: json['driving_licence_photo'],
      profilePicture: json['profile_picture'],
      codHoldings: json['cod_holdings'] ?? '0.00',
      chalanHoldings: json['chalan_holdings'] ?? '0.00',
      totalDeliveries: json['total_deliveries'] ?? 0,
      customerRatings: json['customer_ratings'] ?? '0.0',
      referralCode: json['referral_code'],
      referenceCode: json['reference_code'],
      status: json['status'] ?? '',
      statusRemark: json['status_remark'],
      lastDeviceUsed: json['last_device_used'],
      currentDeviceUsing: json['current_device_using'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      assignedDcId: json['assigned_dc_id'] != null 
          ? List<String>.from(json['assigned_dc_id']) 
          : null,
      currentVehicleId: json['current_vehicle_id'],
      isActiveToday: json['is_active_today'] ?? false,
      sessionStartTime: json['session_start_time'],
      lastActiveDate: json['last_active_date'],
      intraSddAccess: json['intra_sdd_access'],
      intraNddAccess: json['intra_ndd_access'],
      intraFtlAccess: json['intra_ftl_access'],
      intraRentalAccess: json['intra_rental_access'],
      interPtlAccess: json['inter_ptl_access'],
      interFtlAccess: json['inter_ftl_access'],
      interBiddingAccess: json['inter_bidding_access'],
    );
  }
}

