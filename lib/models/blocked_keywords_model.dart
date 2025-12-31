import 'dart:convert';

class BlockedKeywordsResponse {
  final bool success;
  final String message;
  final List<String> data;

  BlockedKeywordsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BlockedKeywordsResponse.fromJson(Map<String, dynamic> json) {
    return BlockedKeywordsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown message',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

