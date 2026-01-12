import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/auth_models.dart';
import '../models/customer_details_model.dart';
import '../models/support_tickets_model.dart';
import '../models/orders_model.dart';
import '../models/order_history_model.dart';
import '../models/raise_ticket_model.dart';
import '../models/wallet_transaction_model.dart';
import '../models/banking_details_model.dart';
import '../models/recharge_request_model.dart';
import '../models/gift_code_model.dart';
import '../models/gift_code_list_model.dart';
import '../models/razorpay_order_model.dart';
import '../models/razorpay_verify_model.dart';
import '../models/fixed_price_dimensions_model.dart';
import '../models/commodities_model.dart';
import '../models/place_search_model.dart';
import '../models/dc_closing_time_model.dart';
import '../models/saved_dimensions_model.dart';
import '../models/blocked_keywords_model.dart';
import '../models/discount_coupon_model.dart';
import '../models/order_submit_model.dart';
import '../models/place_manager_model.dart';
import '../models/dynamic_price_model.dart';
import '../models/trip_model.dart';
import '../models/dc_model.dart';
import '../models/vehicle_model.dart';
import '../models/order_tracking_model.dart';

class AuthService {
  static const String baseUrl = 'https://api.kartbuddy.in/api';

  Future<LoginResponse> customerLogin(String emailOrPhone, String password, {required bool isPhone}) async {
    try {
      final url = Uri.parse('$baseUrl/auth/customer/login');
      
      // Use mobile_number for phone login, email for email login
      final requestBody = isPhone
          ? {
              'mobile_number': emailOrPhone,
              'password': password,
            }
          : {
              'email': emailOrPhone,
              'password': password,
            };
      
      print('🔵 API Call: POST $url');
      print('🔵 Login Type: ${isPhone ? "Phone" : "Email"}');
      print('🔵 Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Login successful');
        return LoginResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Login failed: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<RegisterResponse> customerRegister({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/customer/register');
      
      final requestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'mobile_number': mobileNumber,
        'password': password,
      };
      
      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Registration successful');
        return RegisterResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Registration failed: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<CustomerDetailsResponse> getCustomerDetails(String token) async {
    try {
      final url = Uri.parse('$baseUrl/auth/customer/me');
      
      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Customer details retrieved successfully');
        return CustomerDetailsResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get customer details: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get customer details');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<SupportTicketsResponse> getSupportTickets(String customerId, String token) async {
    try {
      final url = Uri.parse('$baseUrl/support/$customerId');
      
      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Support tickets retrieved successfully');
        return SupportTicketsResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get support tickets: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get support tickets');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<void> replyToTicket(
    String ticketId,
    String message,
    String customerId,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/support/$ticketId/reply');

      final requestBody = {
        'message': message,
        'customer_id': customerId,
      };

      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${jsonEncode(requestBody)}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Message sent successfully');
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to send message: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<OrdersResponse> getCustomerOrders(String customerId, String token) async {
    try {
      final url = Uri.parse('$baseUrl/order-manager/customer/$customerId');
      
      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      final responseBody = response.body;
      print('🔵 Response Body length: ${responseBody.length}');
      if (responseBody.length > 2000) {
        print('🔵 Response Body (first 2000 chars): ${responseBody.substring(0, 2000)}');
      } else {
        print('🔵 Response Body: $responseBody');
      }

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Orders retrieved successfully');
        // Debug: Print first order's dimensions and totals
        if (jsonResponse['data'] != null && (jsonResponse['data'] as List).isNotEmpty) {
          final firstOrder = (jsonResponse['data'] as List)[0];
          print('🔵 First order dimensions: ${firstOrder['dimensions']}');
          print('🔵 First order total_units: ${firstOrder['total_units']}');
          print('🔵 First order total_gross_weight: ${firstOrder['total_gross_weight']}');
          print('🔵 First order total_vol_weight: ${firstOrder['total_vol_weight']}');
        }
        return OrdersResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get orders: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get orders');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<OrderHistoryResponse> getOrderHistory(String orderId, String token) async {
    try {
      final url = Uri.parse('$baseUrl/order-history/$orderId');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Order history retrieved successfully');
        return OrderHistoryResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get order history: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get order history');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<RaiseTicketResponse> raiseTicket(
    String orderId,
    String subject,
    String description,
    String customerId,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/support');

      final requestBody = {
        'order_id': orderId,
        'subject': subject,
        'description': description,
        'customer_id': customerId,
      };

      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${jsonEncode(requestBody)}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Support ticket created successfully');
        return RaiseTicketResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to raise ticket: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to raise ticket');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<WalletHistoryResponse> getWalletHistory(String customerId, String token) async {
    try {
      final url = Uri.parse('$baseUrl/wallet-manager/$customerId');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Wallet history retrieved successfully');
        return WalletHistoryResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get wallet history: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get wallet history');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<BankingDetailsResponse> getBankingDetails(String token) async {
    try {
      final url = Uri.parse('$baseUrl/wallet-manager/banking-details');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Banking details retrieved successfully');
        return BankingDetailsResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get banking details: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get banking details');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<RechargeRequestResponse> submitRechargeRequest(
    String amount,
    String selectedBankId,
    File screenshot,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/wallet-manager/recharge-request');

      print('🔵 API Call: POST $url');
      print('🔵 Amount: $amount');
      print('🔵 Selected Bank ID: $selectedBankId');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add fields
      request.fields['amount'] = amount;
      request.fields['selected_bank_id'] = selectedBankId;
      
      // Add file with proper MIME type
      final fileName = screenshot.path.split('/').last;
      final extension = fileName.toLowerCase().split('.').last;
      
      MediaType contentType;
      if (['jpg', 'jpeg'].contains(extension)) {
        contentType = MediaType('image', 'jpeg');
      } else if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'gif') {
        contentType = MediaType('image', 'gif');
      } else if (extension == 'webp') {
        contentType = MediaType('image', 'webp');
      } else {
        print('⚠️ Unknown file extension: $extension, defaulting to image/jpeg');
        contentType = MediaType('image', 'jpeg');
      }
      
      var multipartFile = await http.MultipartFile.fromPath(
        'screenshot',
        screenshot.path,
        contentType: contentType,
      );
      request.files.add(multipartFile);

      print('🔵 Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Check if response is JSON
        if (response.body.trim().startsWith('{') || response.body.trim().startsWith('[')) {
          try {
            final jsonResponse = jsonDecode(response.body);
            print('✅ Recharge request submitted successfully');
            return RechargeRequestResponse.fromJson(jsonResponse);
          } catch (e) {
            print('❌ Error parsing JSON response: $e');
            throw Exception('Invalid response format from server');
          }
        } else {
          print('❌ Server returned non-JSON response');
          throw Exception('Server returned an invalid response format');
        }
      } else {
        // Handle error response - check if it's JSON or HTML
        String errorMessage = 'Failed to submit recharge request';
        
        if (response.body.trim().startsWith('{') || response.body.trim().startsWith('[')) {
          try {
            final errorResponse = jsonDecode(response.body);
            errorMessage = errorResponse['message'] ?? errorResponse['error'] ?? errorMessage;
            print('❌ Failed to submit recharge request: $errorMessage');
          } catch (e) {
            print('❌ Error parsing error response: $e');
            errorMessage = 'Server error (${response.statusCode})';
          }
        } else if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          // Server returned HTML (likely an error page)
          print('❌ Server returned HTML error page (Status: ${response.statusCode})');
          if (response.statusCode == 404) {
            errorMessage = 'API endpoint not found. Please contact support.';
          } else if (response.statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            errorMessage = 'Authentication failed. Please login again.';
          } else {
            errorMessage = 'Server error (${response.statusCode}). Please try again.';
          }
        } else {
          errorMessage = 'Server error (${response.statusCode})';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      // Don't wrap the exception if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<RedeemGiftCodeResponse> redeemGiftCode(
    String customerId,
    String giftCode,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/gift-code/redeem');

      final requestBody = {
        'customer_id': customerId,
        'gift_code': giftCode,
      };

      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${jsonEncode(requestBody)}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Gift code redeemed successfully');
        return RedeemGiftCodeResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to redeem gift code: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to redeem gift code');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<GiftCodeListResponse> getGiftCodes(String token) async {
    try {
      final url = Uri.parse('$baseUrl/gift-code');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Gift codes retrieved successfully');
        return GiftCodeListResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get gift codes: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get gift codes');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<RazorpayOrderResponse> createRazorpayOrder(
    int amount,
    String customerId,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/razorpay/create-order');

      final requestBody = {
        'amount': amount,
        'customer_id': customerId,
      };

      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${jsonEncode(requestBody)}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Razorpay order created successfully');
        return RazorpayOrderResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to create Razorpay order: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to create Razorpay order');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<RazorpayVerifyResponse> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int amount,
    required String customerId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/razorpay/verify-payment');

      final requestBody = {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'amount': amount,
        'customer_id': customerId,
      };

      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${jsonEncode(requestBody)}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Payment verified successfully');
        return RazorpayVerifyResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to verify payment: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to verify payment');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<FixedPriceDimensionsResponse> getFixedPriceDimensions(
    String customerId,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/price-manager/customer/$customerId');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Fixed price dimensions retrieved successfully');
        return FixedPriceDimensionsResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get fixed price dimensions: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get fixed price dimensions');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<CommoditiesResponse> getCommodities(String token) async {
    try {
      final url = Uri.parse('$baseUrl/commodities-routes');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Commodities retrieved successfully');
        print('🔵 Response structure: success=${jsonResponse['success']}, data type=${jsonResponse['data'].runtimeType}');
        if (jsonResponse['data'] != null && (jsonResponse['data'] as List).isNotEmpty) {
          print('🔵 First commodity in response: ${(jsonResponse['data'] as List)[0]}');
        }
        return CommoditiesResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get commodities: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get commodities');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<PlaceSearchResponse> searchPlaces({
    required String term,
    required String type,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/place-manager/search').replace(
        queryParameters: {
          'term': term,
          'type': type,
        },
      );

      print('🔵 API Call: GET $url');
      print('🔵 Search term: $term, Type: $type');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Places search completed successfully');
        return PlaceSearchResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to search places: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to search places');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<DcClosingTimeResponse> getDcClosingTime(
    String placeId,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/dc-manager/closing-time/$placeId');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ DC closing time retrieved successfully');
        return DcClosingTimeResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get DC closing time: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get DC closing time');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<SavedDimensionsResponse> getSavedDimensions(
    String customerId,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/dynamic-price-manager/saved-dimensions/$customerId');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Saved dimensions retrieved successfully');
        return SavedDimensionsResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get saved dimensions: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get saved dimensions');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<SaveDimensionResponse> saveDimension(
    SaveDimensionRequest request,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/dynamic-price-manager/saved-dimensions');

      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${request.toJson()}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Dimension saved successfully');
        return SaveDimensionResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to save dimension: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to save dimension');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<SaveDimensionResponse> deleteSavedDimension(
    String dimensionId,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/dynamic-price-manager/saved-dimensions/$dimensionId');

      print('🔵 API Call: DELETE $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Dimension deleted successfully');
        return SaveDimensionResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to delete dimension: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to delete dimension');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<DiscountCouponsResponse> getDiscountCoupons(String token) async {
    try {
      final url = Uri.parse('$baseUrl/discount-coupon');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Discount coupons retrieved successfully');
        return DiscountCouponsResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get discount coupons: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get discount coupons');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<CouponValidationResponse> validateCoupon({
    required String couponCode,
    required String customerId,
    required double orderAmount,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/discount-coupon/validate/$couponCode').replace(
        queryParameters: {
          'customer_id': customerId,
          'order_amount': orderAmount.toStringAsFixed(2),
        },
      );

      print('🔵 API Call: GET $url');
      print('🔵 Coupon Code: $couponCode');
      print('🔵 Customer ID: $customerId');
      print('🔵 Order Amount: $orderAmount');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Coupon validated successfully');
        return CouponValidationResponse.fromJson(jsonResponse);
      } else {
        // Even on error (400, etc.), return the response with success=false
        print('❌ Coupon validation failed: ${jsonResponse['message'] ?? 'Unknown error'}');
        return CouponValidationResponse.fromJson(jsonResponse);
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<BlockedKeywordsResponse> getBlockedKeywords(String token) async {
    try {
      final url = Uri.parse('$baseUrl/commodities-routes/block');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Blocked keywords retrieved successfully');
        return BlockedKeywordsResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get blocked keywords: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get blocked keywords');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<OrderSubmitResponse> submitOrder({
    required OrderSubmitRequest request,
    required String token,
    List<String>? challanFilePaths,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/order-manager');

      print('🔵 API Call: POST $url');
      print('🔵 Request: ${request.toJson()}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      if (challanFilePaths != null && challanFilePaths.isNotEmpty) {
        print('🔵 Challan files: ${challanFilePaths.length} file(s)');
      }

      // Create multipart request if files are provided, otherwise use JSON
      if (challanFilePaths != null && challanFilePaths.isNotEmpty) {
        var multipartRequest = http.MultipartRequest('POST', url);
        
        // Add headers
        multipartRequest.headers['Authorization'] = 'Bearer $token';
        
        // Add all fields from request
        final requestJson = request.toJson();
        requestJson.forEach((key, value) {
          multipartRequest.fields[key] = value.toString();
        });
        
        // Add files with proper MIME types
        final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'];
        for (var filePath in challanFilePaths) {
          var file = File(filePath);
          if (await file.exists()) {
            // Get file extension and determine MIME type
            final fileName = filePath.split('/').last;
            final extension = fileName.toLowerCase().split('.').last;
            
            // Validate file extension
            if (!validExtensions.contains(extension)) {
              print('⚠️ Invalid file type: $fileName (extension: $extension). Skipping...');
              continue;
            }
            
            MediaType contentType;
            
            // Set MIME type based on extension
            if (['jpg', 'jpeg'].contains(extension)) {
              contentType = MediaType('image', 'jpeg');
            } else if (extension == 'png') {
              contentType = MediaType('image', 'png');
            } else if (extension == 'gif') {
              contentType = MediaType('image', 'gif');
            } else if (extension == 'webp') {
              contentType = MediaType('image', 'webp');
            } else if (extension == 'pdf') {
              contentType = MediaType('application', 'pdf');
            } else {
              // This shouldn't happen due to validation above, but just in case
              print('⚠️ Unknown file extension: $extension, defaulting to image/jpeg');
              contentType = MediaType('image', 'jpeg');
            }
            
            // Create multipart file with explicit content type
            var multipartFile = await http.MultipartFile.fromPath(
              'challan_files',
              filePath,
              contentType:  contentType,
            );
            multipartRequest.files.add(multipartFile);
            print('🔵 Added file: $fileName, MIME type: ${contentType.toString()}');
          } else {
            print('⚠️ File does not exist: $filePath');
          }
        }
        
        if (multipartRequest.files.isEmpty) {
          throw Exception('No valid files to upload. Please select image or PDF files only.');
        }

        print('🔵 Sending multipart request...');
        final streamedResponse = await multipartRequest.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('🔵 Response Status Code: ${response.statusCode}');
        print('🔵 Response Body: ${response.body}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          // Check if response is HTML (error page)
          if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
            print('❌ Server returned HTML instead of JSON. Status: ${response.statusCode}');
            throw Exception('Server error: Received HTML response. Please check your connection and try again.');
          }
          final jsonResponse = jsonDecode(response.body);
          print('✅ Order submitted successfully');
          return OrderSubmitResponse.fromJson(jsonResponse);
        } else {
          // Check if response is HTML (error page)
          if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
            print('❌ Server returned HTML error page. Status: ${response.statusCode}');
            throw Exception('Server error (${response.statusCode}): Please check your connection and try again.');
          }
          try {
          final errorResponse = jsonDecode(response.body);
          print('❌ Failed to submit order: ${errorResponse['message'] ?? 'Unknown error'}');
          throw Exception(errorResponse['message'] ?? 'Failed to submit order');
          } catch (jsonError) {
            print('❌ Failed to parse error response: $jsonError');
            throw Exception('Server error (${response.statusCode}): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
          }
        }
      } else {
        // No files, use regular JSON POST
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(request.toJson()),
        );

        print('🔵 Response Status Code: ${response.statusCode}');
        print('🔵 Response Body: ${response.body}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          // Check if response is HTML (error page)
          if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
            print('❌ Server returned HTML instead of JSON. Status: ${response.statusCode}');
            throw Exception('Server error: Received HTML response. Please check your connection and try again.');
          }
          final jsonResponse = jsonDecode(response.body);
          print('✅ Order submitted successfully');
          return OrderSubmitResponse.fromJson(jsonResponse);
        } else {
          // Check if response is HTML (error page)
          if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
            print('❌ Server returned HTML error page. Status: ${response.statusCode}');
            throw Exception('Server error (${response.statusCode}): Please check your connection and try again.');
          }
          try {
          final errorResponse = jsonDecode(response.body);
          print('❌ Failed to submit order: ${errorResponse['message'] ?? 'Unknown error'}');
          throw Exception(errorResponse['message'] ?? 'Failed to submit order');
          } catch (jsonError) {
            print('❌ Failed to parse error response: $jsonError');
            throw Exception('Server error (${response.statusCode}): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
          }
        }
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      // If it's already a formatted exception, rethrow it
      if (e.toString().contains('Server error')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<PlaceManagerResponse> getPlaceManagerPlaces(
    String customerId,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/place-manager/singleSource/$customerId');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Place manager places retrieved successfully');
        return PlaceManagerResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get place manager places: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get place manager places');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<PlaceRegisterResponse> registerPlace(
    PlaceRegisterRequest request,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/place-manager/register');

      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${jsonEncode(request.toJson())}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Place registered successfully');
        return PlaceRegisterResponse.fromJson(jsonResponse);
      } else {
        print('❌ Failed to register place: ${jsonResponse['message'] ?? 'Unknown error'}');
        throw Exception(jsonResponse['message'] ?? 'Failed to register place');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<NearestDcResponse> findNearestDc(
    NearestDcRequest request,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/dc-manager/find-nearest-dc');

      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${jsonEncode(request.toJson())}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Nearest DC found successfully');
        return NearestDcResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to find nearest DC: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to find nearest DC');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<CheckDropServiceResponse> checkDropService(
    CheckDropServiceRequest request,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/dc-manager/check-drop-service');

      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${jsonEncode(request.toJson())}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Drop service check completed successfully');
        return CheckDropServiceResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to check drop service: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to check drop service');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<PlaceDeleteResponse> deletePlace(
    String placeId,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/place-manager/place/$placeId');

      print('🔵 API Call: DELETE $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Place deleted successfully');
        return PlaceDeleteResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to delete place: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to delete place');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<PlaceUpdateResponse> updatePlace(
    String placeId,
    PlaceUpdateRequest request,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/place-manager/place/$placeId');

      print('🔵 API Call: PUT $url');
      print('🔵 Request Body: ${jsonEncode(request.toJson())}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Place updated successfully');
        return PlaceUpdateResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to update place: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to update place');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<CustomerUpdateResponse> uploadProfilePicture(
    String customerId,
    File profileImage,
    String token,
  ) async {
    try {
      // Try the customer update endpoint with multipart for profile picture
      final url = Uri.parse('$baseUrl/auth/customer/$customerId');

      print('🔵 API Call: PUT (multipart) $url');
      print('🔵 Customer ID: $customerId');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      // Create multipart request
      var request = http.MultipartRequest('PUT', url);
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add file with proper MIME type
      final fileName = profileImage.path.split('/').last;
      final extension = fileName.toLowerCase().split('.').last;
      
      MediaType contentType;
      if (['jpg', 'jpeg'].contains(extension)) {
        contentType = MediaType('image', 'jpeg');
      } else if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'gif') {
        contentType = MediaType('image', 'gif');
      } else if (extension == 'webp') {
        contentType = MediaType('image', 'webp');
      } else {
        // Default to jpeg if unknown
        print('⚠️ Unknown file extension: $extension, defaulting to image/jpeg');
        contentType = MediaType('image', 'jpeg');
      }
      
      var multipartFile = await http.MultipartFile.fromPath(
        'profile_picture',
        profileImage.path,
        contentType: contentType,
      );
      request.files.add(multipartFile);
      print('🔵 Added profile picture: $fileName, MIME type: ${contentType.toString()}');

      print('🔵 Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          print('❌ Server returned HTML instead of JSON. Status: ${response.statusCode}');
          throw Exception('Server error: Received HTML response. Please check your connection and try again.');
        }
        final jsonResponse = jsonDecode(response.body);
        print('✅ Profile picture uploaded successfully');
        return CustomerUpdateResponse.fromJson(jsonResponse);
      } else {
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          print('❌ Server returned HTML error page. Status: ${response.statusCode}');
          throw Exception('Server error (${response.statusCode}): Please check your connection and try again.');
        }
        try {
          final errorResponse = jsonDecode(response.body);
          print('❌ Failed to upload profile picture: ${errorResponse['message'] ?? 'Unknown error'}');
          throw Exception(errorResponse['message'] ?? 'Failed to upload profile picture');
        } catch (jsonError) {
          print('❌ Failed to parse error response: $jsonError');
          throw Exception('Server error (${response.statusCode}): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      if (e.toString().contains('Server error')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
    String token,
  ) async {
    try {
      // Try driver endpoint first, fallback to customer endpoint
      final url = Uri.parse('$baseUrl/auth/driver/change-password');

      print('🔵 API Call: POST $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final requestBody = {
        'current_password': currentPassword,
        'new_password': newPassword,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          print('❌ Server returned HTML instead of JSON. Status: ${response.statusCode}');
          throw Exception('Server error: Received HTML response. Please check your connection and try again.');
        }
        if (response.body.isEmpty || response.statusCode == 204) {
          print('✅ Password changed successfully (204 No Content)');
          return {'success': true, 'message': 'Password changed successfully'};
        }
        final jsonResponse = jsonDecode(response.body);
        print('✅ Password changed successfully');
        return jsonResponse;
      } else {
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          print('❌ Server returned HTML error page. Status: ${response.statusCode}');
          throw Exception('Server error (${response.statusCode}): Please check your connection and try again.');
        }
        try {
          final errorResponse = jsonDecode(response.body);
          print('❌ Failed to change password: ${errorResponse['message'] ?? 'Unknown error'}');
          throw Exception(errorResponse['message'] ?? 'Failed to change password');
        } catch (jsonError) {
          print('❌ Failed to parse error response: $jsonError');
          throw Exception('Server error (${response.statusCode}): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      if (e.toString().contains('Server error')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<CustomerUpdateResponse> uploadPanCardPhoto(
    String customerId,
    File panCardImage,
    String token,
  ) async {
    try {
      // Use the customer update endpoint with multipart for PAN card photo
      final url = Uri.parse('$baseUrl/auth/customer/$customerId');

      print('🔵 API Call: PUT (multipart) $url');
      print('🔵 Customer ID: $customerId');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      // Create multipart request
      var request = http.MultipartRequest('PUT', url);
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add file with proper MIME type
      final fileName = panCardImage.path.split('/').last;
      final extension = fileName.toLowerCase().split('.').last;
      
      MediaType contentType;
      if (['jpg', 'jpeg'].contains(extension)) {
        contentType = MediaType('image', 'jpeg');
      } else if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'gif') {
        contentType = MediaType('image', 'gif');
      } else if (extension == 'webp') {
        contentType = MediaType('image', 'webp');
      } else {
        // Default to jpeg if unknown
        print('⚠️ Unknown file extension: $extension, defaulting to image/jpeg');
        contentType = MediaType('image', 'jpeg');
      }
      
      var multipartFile = await http.MultipartFile.fromPath(
        'pan_card_photo',
        panCardImage.path,
        contentType: contentType,
      );
      request.files.add(multipartFile);
      print('🔵 Added PAN card photo: $fileName, MIME type: ${contentType.toString()}');

      print('🔵 Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          print('❌ Server returned HTML instead of JSON. Status: ${response.statusCode}');
          throw Exception('Server error: Received HTML response. Please check your connection and try again.');
        }
        final jsonResponse = jsonDecode(response.body);
        print('✅ PAN card photo uploaded successfully');
        return CustomerUpdateResponse.fromJson(jsonResponse);
      } else {
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          print('❌ Server returned HTML error page. Status: ${response.statusCode}');
          throw Exception('Server error (${response.statusCode}): Please check your connection and try again.');
        }
        try {
          final errorResponse = jsonDecode(response.body);
          print('❌ Failed to upload PAN card photo: ${errorResponse['message'] ?? 'Unknown error'}');
          throw Exception(errorResponse['message'] ?? 'Failed to upload PAN card photo');
        } catch (jsonError) {
          print('❌ Failed to parse error response: $jsonError');
          throw Exception('Server error (${response.statusCode}): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      if (e.toString().contains('Server error')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<CustomerUpdateResponse> updateCustomer(
    String customerId,
    CustomerUpdateRequest request,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/auth/customer/$customerId');

      print('🔵 API Call: PUT $url');
      print('🔵 Request Body: ${jsonEncode(request.toJson())}');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Customer updated successfully');
        return CustomerUpdateResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to update customer: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to update customer');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<DynamicPriceResponse> getActiveDynamicPrice(String token) async {
    try {
      final url = Uri.parse('$baseUrl/dynamic-price-manager/active');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Active dynamic price retrieved successfully');
        return DynamicPriceResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get active dynamic price: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get active dynamic price');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<DriverLoginResponse> driverRegister({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/driver/register');
      
      final requestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'mobile_number': mobileNumber,
        'password': password,
      };
      
      print('🔵 API Call: POST $url');
      print('🔵 Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Driver registration successful');
        return DriverLoginResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Driver registration failed: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<DriverLoginResponse> driverLogin(String emailOrPhone, String password, {required bool isPhone}) async {
    try {
      final url = Uri.parse('$baseUrl/auth/driver/login');
      
      // Use mobile_number for phone login, email for email login
      final requestBody = isPhone
          ? {
              'mobile_number': emailOrPhone,
              'password': password,
            }
          : {
              'email': emailOrPhone,
              'password': password,
            };
      
      print('🔵 API Call: POST $url');
      print('🔵 Login Type: ${isPhone ? "Phone" : "Email"}');
      print('🔵 Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Driver login successful');
        return DriverLoginResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Driver login failed: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<DriverProfileResponse> getDriverProfile(String token) async {
    try {
      final url = Uri.parse('$baseUrl/auth/driver/me');
      
      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Driver profile retrieved successfully');
        return DriverProfileResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get driver profile: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get driver profile');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<CurrentTripResponse> getCurrentTrip(String token) async {
    try {
      final url = Uri.parse('$baseUrl/trip-manager/driver/current');
      
      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Current trip retrieved successfully');
        print('   📋 Response data:');
        if (jsonResponse['data'] != null) {
          print('      - driver_response: "${jsonResponse['data']['driver_response']}"');
          print('      - trip_status: "${jsonResponse['data']['trip_status']}"');
          print('      - actual_start_time: ${jsonResponse['data']['actual_start_time']}');
          print('      - trip_id: "${jsonResponse['data']['trip_id']}"');
        }
        return CurrentTripResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get current trip: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get current trip');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<TripHistoryResponse> getTripHistory(String token) async {
    try {
      final url = Uri.parse('$baseUrl/trip-manager/driver/trips');
      
      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Trip history retrieved successfully');
        return TripHistoryResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get trip history: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get trip history');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<DcManagerResponse> getDcManagers(String token) async {
    try {
      final url = Uri.parse('$baseUrl/dc-manager');
      
      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ DC managers retrieved successfully');
        return DcManagerResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get DC managers: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get DC managers');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<AvailableVehiclesResponse> getAvailableVehicles(
    String token,
    String vendorId,
    String dcId,
    String serviceType,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/vehicle-manager/available')
          .replace(queryParameters: {
        'vendor_id': vendorId,
        'dc_id': dcId,
        'service_type': serviceType,
      });
      
      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Available vehicles retrieved successfully');
        return AvailableVehiclesResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get available vehicles: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get available vehicles');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> claimVehicle(
    String token,
    String driverId,
    String vehicleId,
    String dcId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/vehicle-manager/claim');
      
      print('🔵 API Call: POST $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      print('🔵 Body: {driver_id: $driverId, vehicle_id: $vehicleId, dc_id: $dcId}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'driver_id': driverId,
          'vehicle_id': vehicleId,
          'dc_id': dcId,
        }),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      // Parse the response regardless of status code
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Vehicle claimed successfully');
        return jsonResponse;
      } else {
        // Return the response even for error status codes so the caller can handle it
        print('⚠️ Claim vehicle response: ${jsonResponse['message'] ?? 'Unknown error'}');
        return jsonResponse;
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> releaseVehicle(
    String token,
    String driverId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/vehicle-manager/release');
      
      print('🔵 API Call: POST $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      print('🔵 Body: {driver_id: $driverId}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'driver_id': driverId,
        }),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      // Parse the response regardless of status code
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Vehicle released successfully');
        return jsonResponse;
      } else {
        // Return the response even for error status codes so the caller can handle it
        print('⚠️ Release vehicle response: ${jsonResponse['message'] ?? 'Unknown error'}');
        return jsonResponse;
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> acceptTrip(
    String token,
    String tripId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/trip-manager/$tripId/accept');
      
      print('🔵 API Call: POST $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Trip accepted successfully');
        return jsonResponse as Map<String, dynamic>;
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to accept trip: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to accept trip');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> rejectTrip(
    String token,
    String tripId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/trip-manager/$tripId/reject');
      
      print('🔵 API Call: POST $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Trip rejected successfully');
        return jsonResponse as Map<String, dynamic>;
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to reject trip: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to reject trip');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<TripDetailsResponse> getTripDetails(
    String token,
    String tripId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/trip-manager/$tripId');
      
      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Trip details retrieved successfully');
        return TripDetailsResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get trip details: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get trip details');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> startTrip(
    String token,
    String tripId,
    String plannedKm,
    String startKm,
    File? startKmPic,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/trip-manager/$tripId/start');
      
      print('🔵 API Call: POST (multipart) $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      print('🔵 Body: {planned_km: $plannedKm, start_km: $startKm}');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add fields
      request.fields['planned_km'] = plannedKm;
      request.fields['start_km'] = startKm;
      
      // Add image file if provided
      if (startKmPic != null && await startKmPic.exists()) {
        // Get file extension and determine MIME type
        final fileName = startKmPic.path.split('/').last;
        final extension = fileName.toLowerCase().split('.').last;
        
        MediaType contentType;
        if (['jpg', 'jpeg'].contains(extension)) {
          contentType = MediaType('image', 'jpeg');
        } else if (extension == 'png') {
          contentType = MediaType('image', 'png');
        } else {
          // Default to jpeg for any other case
          print('⚠️ Unknown file extension: $extension, defaulting to image/jpeg');
          contentType = MediaType('image', 'jpeg');
        }
        
        var multipartFile = await http.MultipartFile.fromPath(
          'start_km_pic',
          startKmPic.path,
          filename: fileName,
          contentType: contentType,
        );
        request.files.add(multipartFile);
        print('🔵 Added start_km_pic file: $fileName, MIME type: ${contentType.toString()}');
      }
      
      print('🔵 Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Trip started successfully');
        return jsonResponse as Map<String, dynamic>;
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to start trip: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to start trip');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> endTrip(
    String token,
    String tripId,
    String endKm,
    File? endKmPic,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/trip-manager/$tripId/end');
      
      print('🔵 API Call: POST (multipart) $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      print('🔵 Body: {end_km: $endKm}');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add fields
      request.fields['end_km'] = endKm;
      
      // Add image file if provided
      if (endKmPic != null && await endKmPic.exists()) {
        // Get file extension and determine MIME type
        final fileName = endKmPic.path.split('/').last;
        final extension = fileName.toLowerCase().split('.').last;
        
        MediaType contentType;
        if (['jpg', 'jpeg'].contains(extension)) {
          contentType = MediaType('image', 'jpeg');
        } else if (extension == 'png') {
          contentType = MediaType('image', 'png');
        } else {
          // Default to jpeg for any other case
          print('⚠️ Unknown file extension: $extension, defaulting to image/jpeg');
          contentType = MediaType('image', 'jpeg');
        }
        
        var multipartFile = await http.MultipartFile.fromPath(
          'end_km_pic',
          endKmPic.path,
          filename: fileName,
          contentType: contentType,
        );
        request.files.add(multipartFile);
        print('🔵 Added end_km_pic file: $fileName, MIME type: ${contentType.toString()}');
      }
      
      print('🔵 Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Trip ended successfully');
        return jsonResponse as Map<String, dynamic>;
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to end trip: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to end trip');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> uploadOrderProof(
    String token,
    String orderId,
    String field,
    File proofFile,
  ) async {
    // Call the multiple files version with a single file
    return uploadOrderProofMultiple(token, orderId, field, [proofFile]);
  }

  Future<Map<String, dynamic>> uploadOrderProofMultiple(
    String token,
    String orderId,
    String field,
    List<File> proofFiles,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/order-manager/$orderId/upload-proof');
      
      print('🔵 API Call: POST (multipart) $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      print('🔵 Field: $field');
      print('🔵 Number of files: ${proofFiles.length}');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add field
      request.fields['field'] = field;
      
      // Add all files
      for (var proofFile in proofFiles) {
        if (await proofFile.exists()) {
          var multipartFile = await http.MultipartFile.fromPath(
            'files',
            proofFile.path,
            filename: proofFile.path.split('/').last,
          );
          request.files.add(multipartFile);
          print('🔵 Added proof file: ${proofFile.path}');
        } else {
          print('⚠️ File does not exist: ${proofFile.path}');
        }
      }
      
      if (request.files.isEmpty) {
        throw Exception('No valid files to upload');
      }
      
      print('🔵 Sending multipart request with ${request.files.length} file(s)...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Proof uploaded successfully');
        return jsonResponse as Map<String, dynamic>;
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to upload proof: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to upload proof');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> collectCod(
    String token,
    String orderId,
    double codAmount,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/order-manager/$orderId/collect-cod');
      
      print('🔵 API Call: POST $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      print('🔵 COD Amount: $codAmount');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'cod_amount': codAmount,
        }),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ COD collected successfully');
        return jsonResponse as Map<String, dynamic>;
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to collect COD: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to collect COD');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> collectToPay(
    String token,
    String orderId,
    double toPayAmount,
    String paymentMethod,
    File? paymentProof,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/order-manager/$orderId/collect-to-pay');
      
      print('🔵 API Call: POST (multipart) $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');
      print('🔵 To-Pay Amount: $toPayAmount');
      print('🔵 Payment Method: $paymentMethod');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add fields
      request.fields['to_pay_amount'] = toPayAmount.toString();
      request.fields['payment_method'] = paymentMethod;
      
      // Add payment proof if provided
      if (paymentProof != null && await paymentProof.exists()) {
        var multipartFile = await http.MultipartFile.fromPath(
          'payment_proof',
          paymentProof.path,
          filename: paymentProof.path.split('/').last,
        );
        request.files.add(multipartFile);
        print('🔵 Added payment proof: ${paymentProof.path}');
      }
      
      print('🔵 Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ To-Pay collected successfully');
        return jsonResponse as Map<String, dynamic>;
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to collect To-Pay: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to collect To-Pay');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<OrderTrackingResponse> getOrderTracking(
    String orderId,
    String token,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/order-manager/$orderId/tracking');

      print('🔵 API Call: GET $url');
      print('🔵 Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final jsonResponse = jsonDecode(response.body);
        print('✅ Order tracking retrieved successfully');
        return OrderTrackingResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        print('❌ Failed to get order tracking: ${errorResponse['message'] ?? 'Unknown error'}');
        throw Exception(errorResponse['message'] ?? 'Failed to get order tracking');
      }
    } catch (e) {
      print('❌ Network error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }
}

