import 'dart:convert';

class PlaceSearchResponse {
  final bool success;
  final String message;
  final List<PlaceSearchResult> data;

  PlaceSearchResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PlaceSearchResponse.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => PlaceSearchResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PlaceSearchResult {
  final String id;
  final String placeId;
  final String companyName;
  final String contactPersonName;
  final String contactPersonMobile;
  final String placeType;
  final String placeSource;
  final String status;
  final String frontendType;
  final String searchIdentifier;

  PlaceSearchResult({
    required this.id,
    required this.placeId,
    required this.companyName,
    required this.contactPersonName,
    required this.contactPersonMobile,
    required this.placeType,
    required this.placeSource,
    required this.status,
    required this.frontendType,
    required this.searchIdentifier,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResult(
      id: json['id'] ?? '',
      placeId: json['place_id'] ?? '',
      companyName: json['company_name'] ?? '',
      contactPersonName: json['contact_person_name'] ?? '',
      contactPersonMobile: json['contact_person_mobile']?.toString() ?? '',
      placeType: json['place_type'] ?? '',
      placeSource: json['place_source'] ?? '',
      status: json['status'] ?? '',
      frontendType: json['frontend_type'] ?? '',
      searchIdentifier: json['search_identifier'] ?? '',
    );
  }
}

