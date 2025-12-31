class CustomerDetailsResponse {
  final bool success;
  final String message;
  final CustomerDetails data;

  CustomerDetailsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CustomerDetailsResponse.fromJson(Map<String, dynamic> json) {
    return CustomerDetailsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: CustomerDetails.fromJson(json['data'] ?? {}),
    );
  }
}

class CustomerDetails {
  final String customerId;
  final String appRole;
  final String firstName;
  final String lastName;
  final String fullName;
  final String mobileNumber;
  final String? alternateNumber;
  final String? email;
  final String? companyName;
  final String? firstLineAddress;
  final String? secondLineAddress;
  final String? state;
  final String? city;
  final String? pinCode;
  final String? fullAddress;
  final String? gstNo;
  final String? adharNo;
  final String? adharFrontPhoto;
  final String? adharBackPhoto;
  final String? panCardNo;
  final String? panCardPhoto;
  final String? profilePicture;
  final String walletBalance;
  final String referralCode;
  final String referenceCode;
  final String status;
  final String? statusRemarks;
  final String createdAt;
  final String updatedAt;

  CustomerDetails({
    required this.customerId,
    required this.appRole,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.mobileNumber,
    this.alternateNumber,
    this.email,
    this.companyName,
    this.firstLineAddress,
    this.secondLineAddress,
    this.state,
    this.city,
    this.pinCode,
    this.fullAddress,
    this.gstNo,
    this.adharNo,
    this.adharFrontPhoto,
    this.adharBackPhoto,
    this.panCardNo,
    this.panCardPhoto,
    this.profilePicture,
    required this.walletBalance,
    required this.referralCode,
    required this.referenceCode,
    required this.status,
    this.statusRemarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      customerId: json['customer_id'] ?? '',
      appRole: json['app_role'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      alternateNumber: json['alternate_number'],
      email: json['email'],
      companyName: json['company_name'],
      firstLineAddress: json['first_line_address'],
      secondLineAddress: json['second_line_address'],
      state: json['state'],
      city: json['city'],
      pinCode: json['pin_code'],
      fullAddress: json['full_address'],
      gstNo: json['gst_no'],
      adharNo: json['adhar_no'],
      adharFrontPhoto: json['adhar_front_photo'],
      adharBackPhoto: json['adhar_back_photo'],
      panCardNo: json['pan_card_no'],
      panCardPhoto: json['pan_card_photo'],
      profilePicture: json['profile_picture'],
      walletBalance: json['wallet_balance'] ?? '0.00',
      referralCode: json['referral_code'] ?? '',
      referenceCode: json['reference_code'] ?? '',
      status: json['status'] ?? '',
      statusRemarks: json['status_remarks'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // Helper method to format date
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not provided';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Helper method to format date with time
  String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not provided';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

class CustomerUpdateRequest {
  final String firstName;
  final String lastName;
  final String? companyName;
  final String? panCardNo;
  final String referenceCode;
  final String? alternateNumber;
  final String? firstLineAddress;
  final String? secondLineAddress;
  final String? state;
  final String? city;
  final String? pinCode;
  final String? gstNo;
  final String? adharNo;

  CustomerUpdateRequest({
    required this.firstName,
    required this.lastName,
    this.companyName,
    this.panCardNo,
    required this.referenceCode,
    this.alternateNumber,
    this.firstLineAddress,
    this.secondLineAddress,
    this.state,
    this.city,
    this.pinCode,
    this.gstNo,
    this.adharNo,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      if (companyName != null && companyName!.isNotEmpty) 'company_name': companyName,
      if (panCardNo != null && panCardNo!.isNotEmpty) 'pan_card_no': panCardNo,
      'reference_code': referenceCode,
      if (alternateNumber != null && alternateNumber!.isNotEmpty) 'alternate_number': alternateNumber,
      if (firstLineAddress != null && firstLineAddress!.isNotEmpty) 'first_line_address': firstLineAddress,
      if (secondLineAddress != null && secondLineAddress!.isNotEmpty) 'second_line_address': secondLineAddress,
      if (state != null && state!.isNotEmpty) 'state': state,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (pinCode != null && pinCode!.isNotEmpty) 'pin_code': pinCode,
      if (gstNo != null && gstNo!.isNotEmpty) 'gst_no': gstNo,
      if (adharNo != null && adharNo!.isNotEmpty) 'adhar_no': adharNo,
    };
  }
}

class CustomerUpdateResponse {
  final bool success;
  final String message;
  final CustomerDetails data;

  CustomerUpdateResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CustomerUpdateResponse.fromJson(Map<String, dynamic> json) {
    return CustomerUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: CustomerDetails.fromJson(json['data'] ?? {}),
    );
  }
}

