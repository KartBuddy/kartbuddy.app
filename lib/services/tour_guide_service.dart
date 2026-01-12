import 'package:shared_preferences/shared_preferences.dart';

class TourGuideService {
  static const String _tourCompletedKey = 'tour_completed';
  static const String _tourSkippedKey = 'tour_skipped';
  
  // Page-specific tour keys
  static const String _homeTourKey = 'tour_home';
  static const String _walletTourKey = 'tour_wallet';
  static const String _placeManagerTourKey = 'tour_place_manager';
  static const String _myOrdersTourKey = 'tour_my_orders';
  static const String _placeOrderTourKey = 'tour_place_order';
  static const String _bookPartloadTourKey = 'tour_book_partload';
  static const String _trackOrderTourKey = 'tour_track_order';
  static const String _supportTourKey = 'tour_support';

  /// Check if user has completed or skipped the main tour
  static Future<bool> shouldShowTour() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_tourCompletedKey) ?? false;
    final skipped = prefs.getBool(_tourSkippedKey) ?? false;
    return !completed && !skipped;
  }

  /// Mark main tour as completed
  static Future<void> completeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourCompletedKey, true);
  }

  /// Mark main tour as skipped
  static Future<void> skipTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourSkippedKey, true);
  }

  /// Reset main tour (for testing purposes)
  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tourCompletedKey);
    await prefs.remove(_tourSkippedKey);
  }

  /// Check if page-specific tour should be shown
  static Future<bool> shouldShowPageTour(String pageKey) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(pageKey) ?? false);
  }

  /// Mark page-specific tour as completed
  static Future<void> completePageTour(String pageKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pageKey, true);
  }

  /// Reset all tours (including page-specific)
  static Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tourCompletedKey);
    await prefs.remove(_tourSkippedKey);
    await prefs.remove(_homeTourKey);
    await prefs.remove(_walletTourKey);
    await prefs.remove(_placeManagerTourKey);
    await prefs.remove(_myOrdersTourKey);
    await prefs.remove(_placeOrderTourKey);
    await prefs.remove(_bookPartloadTourKey);
    await prefs.remove(_trackOrderTourKey);
    await prefs.remove(_supportTourKey);
  }

  // Page keys as constants for easy access
  static const String homeTour = _homeTourKey;
  static const String walletTour = _walletTourKey;
  static const String placeManagerTour = _placeManagerTourKey;
  static const String myOrdersTour = _myOrdersTourKey;
  static const String placeOrderTour = _placeOrderTourKey;
  static const String bookPartloadTour = _bookPartloadTourKey;
  static const String trackOrderTour = _trackOrderTourKey;
  static const String supportTour = _supportTourKey;
}

