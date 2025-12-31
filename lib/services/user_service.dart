import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class UserService {
  static const String _keyCustomer = 'customer_data';
  static const String _keyDriver = 'driver_data';
  static const String _keyToken = 'auth_token';
  static const String _keyUserType = 'user_type'; // 'customer' or 'driver'

  // Save user data and token
  static Future<void> saveUserData(Customer customer, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomer, jsonEncode({
      'id': customer.id,
      'email': customer.email,
      'mobile_number': customer.mobileNumber,
      'full_name': customer.fullName,
      'app_role': customer.appRole,
    }));
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserType, 'customer');
  }

  // Get customer data
  static Future<Customer?> getCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    final customerJson = prefs.getString(_keyCustomer);
    if (customerJson != null) {
      final customerData = jsonDecode(customerJson);
      return Customer(
        id: customerData['id'] ?? '',
        email: customerData['email'],
        mobileNumber: customerData['mobile_number'],
        fullName: customerData['full_name'] ?? '',
        appRole: customerData['app_role'] ?? '',
      );
    }
    return null;
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Get user's display name (first name or full name)
  static Future<String> getUserDisplayName() async {
    final customer = await getCustomer();
    if (customer != null) {
      // Extract first name from full name
      final nameParts = customer.fullName.split(' ');
      return nameParts.isNotEmpty ? nameParts[0] : customer.fullName;
    }
    return 'User';
  }

  // Get user's full name
  static Future<String> getUserFullName() async {
    final customer = await getCustomer();
    return customer?.fullName ?? 'User';
  }

  // Get user's email
  static Future<String> getUserEmail() async {
    final customer = await getCustomer();
    return customer?.email ?? customer?.mobileNumber ?? '';
  }

  // Get user's initial for avatar
  static Future<String> getUserInitial() async {
    final customer = await getCustomer();
    if (customer != null && customer.fullName.isNotEmpty) {
      return customer.fullName[0].toUpperCase();
    }
    return 'U';
  }

  // Save driver data and token
  static Future<void> saveDriverData(Driver driver, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDriver, jsonEncode({
      'id': driver.id,
      'driver_id': driver.driverId,
      'email': driver.email,
      'mobile_number': driver.mobileNumber,
      'full_name': driver.fullName,
      'app_role': driver.appRole,
      'profile_picture': driver.profilePicture,
      'current_address_proof': driver.currentAddressProof,
      'pan_card_photo': driver.panCardPhoto,
      'aadhar_front_photo': driver.aadharFrontPhoto,
      'aadhar_back_photo': driver.aadharBackPhoto,
      'driving_licence_photo': driver.drivingLicencePhoto,
    }));
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserType, 'driver');
  }

  // Get driver data
  static Future<Driver?> getDriver() async {
    final prefs = await SharedPreferences.getInstance();
    final driverJson = prefs.getString(_keyDriver);
    if (driverJson != null) {
      final driverData = jsonDecode(driverJson);
      return Driver(
        id: driverData['id'] ?? '',
        driverId: driverData['driver_id'] ?? '',
        email: driverData['email'],
        mobileNumber: driverData['mobile_number'],
        fullName: driverData['full_name'] ?? '',
        appRole: driverData['app_role'] ?? '',
        profilePicture: driverData['profile_picture'],
        currentAddressProof: driverData['current_address_proof'],
        panCardPhoto: driverData['pan_card_photo'],
        aadharFrontPhoto: driverData['aadhar_front_photo'],
        aadharBackPhoto: driverData['aadhar_back_photo'],
        drivingLicencePhoto: driverData['driving_licence_photo'],
      );
    }
    return null;
  }

  // Get user type
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserType);
  }

  // Clear user data (logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomer);
    await prefs.remove(_keyDriver);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserType);
  }
}

