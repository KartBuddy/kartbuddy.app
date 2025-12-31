import 'dart:convert';

class CommoditiesResponse {
  final bool success;
  final String message;
  final List<Commodity> data;

  CommoditiesResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CommoditiesResponse.fromJson(Map<String, dynamic> json) {
    return CommoditiesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Commodity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Commodity {
  final String id;
  final String name;
  final String? description;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  Commodity({
    required this.id,
    required this.name,
    this.description,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Commodity.fromJson(Map<String, dynamic> json) {
    print('🔵 Parsing commodity JSON: $json');
    print('🔵 Available keys: ${json.keys.toList()}');
    
    // API returns 'keyword' field, not 'name'
    final commodityName = json['keyword'] ?? 
                          json['name'] ?? 
                          json['commodity_name'] ?? 
                          json['commodityName'] ?? 
                          json['title'] ?? 
                          json['commodity'] ??
                          '';
    
    final commodityId = json['id']?.toString() ?? 
                        json['_id']?.toString() ??
                        json['commodity_id']?.toString() ??
                        '';
    
    print('🔵 Commodity ID parsed: "$commodityId"');
    print('🔵 Commodity name (keyword) parsed: "$commodityName"');
    
    return Commodity(
      id: commodityId,
      name: commodityName.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
    );
  }
}

