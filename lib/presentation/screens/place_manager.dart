import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'customer_home.dart';
import 'customer_wallet.dart';
//go for the page that appears after the user clicks on the book partload button make him understand the difference fixed price and the dynamic price and also about the prepaid and to pay 
import 'place_order.dart';
import 'my_orders.dart';
import 'track_order.dart';
import 'support.dart';
import 'user_profile.dart';
import '../../auth/login.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../models/place_manager_model.dart';
import '../../models/dc_closing_time_model.dart';
import '../../utils/responsive.dart';

class PlaceManager extends StatefulWidget {
  const PlaceManager({super.key});

  @override
  State<PlaceManager> createState() => _PlaceManagerState();
}

class _PlaceManagerState extends State<PlaceManager> {
  String _selectedTab = 'Registered Addresses';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _userName = 'User';
  String _userInitial = 'U';
  String _userFullName = 'User';
  String _userEmail = '';
  
  // Add Pickup Address form controllers
  final TextEditingController _contactPersonNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _contactPersonMobileController = TextEditingController();
  final TextEditingController _alternateNumberController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _nearestRailwayStationController = TextEditingController();
  final TextEditingController _nearestBusStopController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  
  bool _sameAsContactPerson = false;
  String _parkingPlaceAvailability = 'NO';
  String _dcHub = 'Not available';
  
  // Add Consignee Address form controllers
  final TextEditingController _consigneeContactPersonNameController = TextEditingController();
  final TextEditingController _consigneeCompanyNameController = TextEditingController();
  final TextEditingController _consigneeContactPersonMobileController = TextEditingController();
  final TextEditingController _consigneeAlternateNumberController = TextEditingController();
  final TextEditingController _consigneeGstNumberController = TextEditingController();
  final TextEditingController _consigneeAddressLine1Controller = TextEditingController();
  final TextEditingController _consigneeAddressLine2Controller = TextEditingController();
  final TextEditingController _consigneeNearestRailwayStationController = TextEditingController();
  final TextEditingController _consigneeNearestBusStopController = TextEditingController();
  final TextEditingController _consigneeLandmarkController = TextEditingController();
  final TextEditingController _consigneePincodeController = TextEditingController();
  final TextEditingController _consigneeStateController = TextEditingController();
  final TextEditingController _consigneeCityController = TextEditingController();
  final TextEditingController _consigneeLatitudeController = TextEditingController();
  final TextEditingController _consigneeLongitudeController = TextEditingController();
  
  bool _consigneeSameAsContactPerson = false;
  String _consigneeParkingPlaceAvailability = 'NO';
  String _consigneeDcHub = 'Not available';

  final AuthService _authService = AuthService();
  List<PlaceManagerData> _places = [];
  bool _isLoadingPlaces = false;
  bool _isFindingDc = false;
  bool _isFindingConsigneeDc = false;
  
  // Map controllers
  GoogleMapController? _pickupMapController;
  GoogleMapController? _consigneeMapController;
  MapType _pickupMapType = MapType.normal;
  MapType _consigneeMapType = MapType.normal;
  
  // Map markers
  Set<Marker> _pickupMarkers = {};
  Set<Marker> _consigneeMarkers = {};
  
  // Current location tracking
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // Search controllers for maps
  final TextEditingController _pickupSearchController = TextEditingController();
  final TextEditingController _consigneeSearchController = TextEditingController();
  
  // Autocomplete suggestions
  List<Map<String, dynamic>> _pickupSuggestions = [];
  List<Map<String, dynamic>> _consigneeSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showConsigneeSuggestions = false;
  
  // Debounce timers
  Timer? _pickupSearchTimer;
  Timer? _consigneeSearchTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPlaces();
    _contactPersonNameController.addListener(() {
      if (_sameAsContactPerson) {
        _companyNameController.text = _contactPersonNameController.text;
      }
    });
    _consigneeContactPersonNameController.addListener(() {
      if (_consigneeSameAsContactPerson) {
        _consigneeCompanyNameController.text = _consigneeContactPersonNameController.text;
      }
    });
    // Add listeners to find DC when coordinates are entered
    _latitudeController.addListener(_onPickupCoordinatesChanged);
    _longitudeController.addListener(_onPickupCoordinatesChanged);
    _consigneeLatitudeController.addListener(_onConsigneeCoordinatesChanged);
    _consigneeLongitudeController.addListener(_onConsigneeCoordinatesChanged);
    
    // Add listeners for autocomplete
    _pickupSearchController.addListener(_onPickupSearchChanged);
    _consigneeSearchController.addListener(_onConsigneeSearchChanged);
    
    // Start location tracking
    _startLocationTracking();
  }
  
  Future<void> _startLocationTracking() async {
    try {
      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateCurrentLocationMarkers();

      // Listen to position updates
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        _currentPosition = position;
        _updateCurrentLocationMarkers();
      });
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }
  
  void _updateCurrentLocationMarkers() {
    if (_currentPosition != null && mounted) {
      setState(() {
        // Add blue marker for current location to pickup map
        final currentLocationMarker = Marker(
          markerId: const MarkerId('current_location_pickup'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'My Current Location',
            snippet: 'Your live location',
          ),
        );
        
        // Add blue marker for current location to consignee map
        final currentLocationMarkerConsignee = Marker(
          markerId: const MarkerId('current_location_consignee'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'My Current Location',
            snippet: 'Your live location',
          ),
        );
        
        // Update pickup markers - keep all existing markers except the old blue marker, then add new blue marker
        _pickupMarkers = {
          ..._pickupMarkers.where((m) => m.markerId.value != 'current_location_pickup'),
          currentLocationMarker,
        };
        
        // Update consignee markers - keep all existing markers except the old blue marker, then add new blue marker
        _consigneeMarkers = {
          ..._consigneeMarkers.where((m) => m.markerId.value != 'current_location_consignee'),
          currentLocationMarkerConsignee,
        };
      });
    }
  }
  
  
  void _onPickupSearchChanged() {
    // Cancel previous timer
    _pickupSearchTimer?.cancel();
    
    final query = _pickupSearchController.text.trim();
    if (query.length >= 1) {
      // Debounce: wait 300ms before fetching
      _pickupSearchTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _pickupSearchController.text.trim().length >= 1) {
          print('🔵 Fetching pickup suggestions for: ${_pickupSearchController.text.trim()}');
          _fetchPlaceSuggestions(_pickupSearchController.text.trim(), true, showSuggestions: true);
        }
      });
    } else {
      setState(() {
        _pickupSuggestions = [];
        _showPickupSuggestions = false;
      });
    }
  }
  
  void _onConsigneeSearchChanged() {
    // Cancel previous timer
    _consigneeSearchTimer?.cancel();
    
    final query = _consigneeSearchController.text.trim();
    if (query.length >= 1) {
      // Debounce: wait 300ms before fetching
      _consigneeSearchTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _consigneeSearchController.text.trim().length >= 1) {
          print('🔵 Fetching consignee suggestions for: ${_consigneeSearchController.text.trim()}');
          _fetchPlaceSuggestions(_consigneeSearchController.text.trim(), false, showSuggestions: true);
        }
      });
    } else {
      setState(() {
        _consigneeSuggestions = [];
        _showConsigneeSuggestions = false;
      });
    }
  }
  
  Future<void> _fetchPlaceSuggestions(String query, bool isPickup, {bool showSuggestions = false}) async {
    if (query.trim().isEmpty) {
      setState(() {
        if (isPickup) {
          _pickupSuggestions = [];
          _showPickupSuggestions = false;
        } else {
          _consigneeSuggestions = [];
          _showConsigneeSuggestions = false;
        }
      });
      return;
    }

    try {
      final apiKey = 'AIzaSyB1tKNFxigZ5II4PqyHAXQSCgwOL2zsiwg';
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$apiKey&components=country:in',
      );

      print('🔵 API Call: GET $url');
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      
      print('🔵 Autocomplete response status: ${data['status']}');

      if (data['status'] == 'OK' && data['predictions'] != null) {
        final predictions = data['predictions'] as List;
        final suggestions = predictions.take(5).map((prediction) {
          return {
            'description': prediction['description'] ?? '',
            'place_id': prediction['place_id'] ?? '',
          };
        }).toList();

        print('✅ Found ${suggestions.length} suggestions');
        if (mounted) {
          setState(() {
            if (isPickup) {
              _pickupSuggestions = suggestions;
              // Only show suggestions if explicitly requested (e.g., when search bar is clicked)
              _showPickupSuggestions = showSuggestions;
              print('✅ Pickup suggestions updated: ${_pickupSuggestions.length} (showSuggestions: $showSuggestions)');
            } else {
              _consigneeSuggestions = suggestions;
              // Only show suggestions if explicitly requested (e.g., when search bar is clicked)
              _showConsigneeSuggestions = showSuggestions;
              print('✅ Consignee suggestions updated: ${_consigneeSuggestions.length} (showSuggestions: $showSuggestions)');
            }
          });
        }
      } else {
        print('❌ No suggestions. Status: ${data['status']}, Error: ${data['error_message'] ?? 'N/A'}');
        if (mounted) {
          setState(() {
            if (isPickup) {
              _pickupSuggestions = [];
              _showPickupSuggestions = false;
            } else {
              _consigneeSuggestions = [];
              _showConsigneeSuggestions = false;
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching suggestions: $e');
      if (mounted) {
        setState(() {
          if (isPickup) {
            _pickupSuggestions = [];
            _showPickupSuggestions = false;
          } else {
            _consigneeSuggestions = [];
            _showConsigneeSuggestions = false;
          }
        });
      }
    }
  }

  void _onPickupCoordinatesChanged() {
    // Debounce: find DC after a short delay when both coordinates are available
    if (_latitudeController.text.trim().isNotEmpty &&
        _longitudeController.text.trim().isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted &&
            _latitudeController.text.trim().isNotEmpty &&
            _longitudeController.text.trim().isNotEmpty) {
          _findNearestDcForPickup();
        }
      });
    }
  }

  void _onConsigneeCoordinatesChanged() {
    // Debounce: find DC after a short delay when both coordinates are available
    if (_consigneeLatitudeController.text.trim().isNotEmpty &&
        _consigneeLongitudeController.text.trim().isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted &&
            _consigneeLatitudeController.text.trim().isNotEmpty &&
            _consigneeLongitudeController.text.trim().isNotEmpty) {
          _findNearestDcForConsignee();
        }
      });
    }
  }

  Future<void> _loadPlaces() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPlaces = true;
    });

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        throw Exception('Authentication token or customer ID not found.');
      }

      print('🔵 Fetching places for customer: ${customer.id}');
      final response = await _authService.getPlaceManagerPlaces(customer.id, token);

      if (mounted) {
        setState(() {
          _places = response.data;
          _isLoadingPlaces = false;
        });
        print('✅ Places loaded: ${_places.length}');
      }
    } catch (e) {
      print('❌ Error loading places: $e');
      if (mounted) {
        setState(() {
          _isLoadingPlaces = false;
        });
      }
    }
  }

  Future<void> _findNearestDcForPickup() async {
    final lat = double.tryParse(_latitudeController.text.trim());
    final lng = double.tryParse(_longitudeController.text.trim());

    if (lat == null || lng == null) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isFindingDc = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      final request = NearestDcRequest(
        lat: lat,
        lng: lng,
        rangeType: 'pick_up_range',
      );

      print('🔵 Finding nearest DC for pickup...');
      final response = await _authService.findNearestDc(request, token);

      if (mounted) {
        setState(() {
          _dcHub = response.data.dcName;
          _isFindingDc = false;
        });
        print('✅ Nearest DC found: ${response.data.dcName} (${response.data.distanceKm} km away)');
      }
    } catch (e) {
      print('❌ Error finding nearest DC: $e');
      if (mounted) {
        setState(() {
          _isFindingDc = false;
          _dcHub = 'Not available';
        });
      }
    }
  }

  Future<void> _findNearestDcForConsignee() async {
    final lat = double.tryParse(_consigneeLatitudeController.text.trim());
    final lng = double.tryParse(_consigneeLongitudeController.text.trim());

    if (lat == null || lng == null) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isFindingConsigneeDc = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      final request = CheckDropServiceRequest(
        lat: lat,
        lng: lng,
      );

      print('🔵 Checking drop service availability for consignee...');
      final response = await _authService.checkDropService(request, token);

      if (mounted) {
        if (response.data.covered) {
          setState(() {
            _consigneeDcHub = response.data.dcName;
            _isFindingConsigneeDc = false;
          });
          print('✅ Service available: ${response.data.dcName} (${response.data.distanceKm} km away)');
        } else {
          setState(() {
            _consigneeDcHub = 'Not available';
            _isFindingConsigneeDc = false;
          });
          print('⚠️ Service not available in this area');
          _showSnackBar('Sorry, we do not provide service at this location.');
        }
      }
    } catch (e) {
      print('❌ Error checking drop service: $e');
      if (mounted) {
        setState(() {
          _isFindingConsigneeDc = false;
          _consigneeDcHub = 'Not available';
        });
        _showErrorDialog('Failed to check service availability: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  Future<void> _loadUserData() async {
    final displayName = await UserService.getUserDisplayName();
    final fullName = await UserService.getUserFullName();
    final email = await UserService.getUserEmail();
    final initial = await UserService.getUserInitial();
    
    if (mounted) {
      setState(() {
        _userName = displayName;
        _userFullName = fullName;
        _userEmail = email;
        _userInitial = initial;
      });
    }
  }

  @override
  void dispose() {
    // Cancel location tracking
    _positionStreamSubscription?.cancel();
    _pickupSearchTimer?.cancel();
    _consigneeSearchTimer?.cancel();
    
    // Dispose controllers
    _searchController.dispose();
    _contactPersonNameController.dispose();
    _companyNameController.dispose();
    _contactPersonMobileController.dispose();
    _alternateNumberController.dispose();
    _gstNumberController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _nearestRailwayStationController.dispose();
    _nearestBusStopController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _latitudeController.removeListener(_onPickupCoordinatesChanged);
    _latitudeController.dispose();
    _longitudeController.removeListener(_onPickupCoordinatesChanged);
    _longitudeController.dispose();
    _consigneeContactPersonNameController.dispose();
    _consigneeCompanyNameController.dispose();
    _consigneeContactPersonMobileController.dispose();
    _consigneeAlternateNumberController.dispose();
    _consigneeGstNumberController.dispose();
    _consigneeAddressLine1Controller.dispose();
    _consigneeAddressLine2Controller.dispose();
    _consigneeNearestRailwayStationController.dispose();
    _consigneeNearestBusStopController.dispose();
    _consigneeLandmarkController.dispose();
    _consigneePincodeController.dispose();
    _consigneeStateController.dispose();
    _consigneeCityController.dispose();
    _consigneeLatitudeController.removeListener(_onConsigneeCoordinatesChanged);
    _consigneeLatitudeController.dispose();
    _consigneeLongitudeController.removeListener(_onConsigneeCoordinatesChanged);
    _consigneeLongitudeController.dispose();
    _pickupSearchController.dispose();
    _consigneeSearchController.dispose();
    
    // Dispose map controllers
    _pickupMapController?.dispose();
    _consigneeMapController?.dispose();
    
    super.dispose();
  }

  List<PlaceManagerData> get _filteredPlaces {
    var filtered = _places;
    
    if (_selectedFilter == 'Pickup Address') {
      filtered = filtered.where((place) => place.placeType == 'Pickup Place').toList();
    } else if (_selectedFilter == 'Consignee Address') {
      filtered = filtered.where((place) => place.placeType == 'Consignee Place').toList();
    }
    
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((place) {
        return place.fullAddress.toLowerCase().contains(searchLower) ||
            place.companyName.toLowerCase().contains(searchLower) ||
            place.contactPersonName.toLowerCase().contains(searchLower) ||
            place.city.toLowerCase().contains(searchLower) ||
            place.placeType.toLowerCase().contains(searchLower);
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        centerTitle: true,
        title: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.amber,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/Kartbuddy logo v.2.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  'Hi, $_userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userFullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userEmail.isNotEmpty ? _userEmail : 'No email',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.black87),
                          SizedBox(width: 12),
                          Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'signout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'Sign out',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (String value) async {
                    if (value == 'profile') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const UserProfile()),
                      );
                    } else if (value == 'signout') {
                      await UserService.clearUserData();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place Manager Title
            const Center(
              child: Text(
                'Place Manager',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tab Buttons
            Row(
              children: [
                Expanded(
                  child: _buildTabButton('Registered Addresses', _selectedTab == 'Registered Addresses'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('Add Pickup Address', _selectedTab == 'Add Pickup Address'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('Add Consignee Address', _selectedTab == 'Add Consignee Address'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Place Management Section (only shown for Registered Addresses)
            if (_selectedTab == 'Registered Addresses') ...[
              // Search Bar with Download Button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {});
                        },
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by address, city, name, etc...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.normal,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 22,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E3A8A),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 56, // Match search box height
                    width: 56, // Square button
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Coming Soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Icon(
                            Icons.download,
                            color: Colors.grey[700],
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter Radio Buttons
              Row(
                children: [
                  _buildRadioButton('All', _selectedFilter == 'All'),
                  const SizedBox(width: 24),
                  _buildRadioButton('Pickup Address', _selectedFilter == 'Pickup Address'),
                  const SizedBox(width: 24),
                  _buildRadioButton('Consignee Address', _selectedFilter == 'Consignee Address'),
                ],
              ),
              const SizedBox(height: 24),

              // Address Cards List
              if (_isLoadingPlaces)
                Container(
                  padding: const EdgeInsets.all(40.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  ),
                )
              else if (_filteredPlaces.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No places found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _filteredPlaces.map((place) => _buildPlaceCard(place)).toList(),
                ),
            ],

            // Add Pickup Address Form
            if (_selectedTab == 'Add Pickup Address') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup Address',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Person Name
                    _buildFormField(
                      label: 'Contact Person Name',
                      controller: _contactPersonNameController,
                      hint: 'Contact Person Name',
                    ),
                    const SizedBox(height: 20),

                    // Company Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Company Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _sameAsContactPerson,
                              onChanged: (value) {
                                setState(() {
                                  _sameAsContactPerson = value ?? false;
                                  if (_sameAsContactPerson) {
                                    _companyNameController.text = _contactPersonNameController.text;
                                  } else {
                                    _companyNameController.clear();
                                  }
                                });
                              },
                              activeColor: const Color(0xFF1E3A8A),
                            ),
                            const Text(
                              'Same as Contact Person Name',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _companyNameController,
                          hint: 'Company Name',
                          enabled: !_sameAsContactPerson,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Contact Person Mobile
                    _buildFormField(
                      label: 'Contact Person Mobile',
                      controller: _contactPersonMobileController,
                      hint: 'Enter 10-digit contact number',
                      keyboardType: TextInputType.number,
                      isPhoneNumber: true,
                    ),
                    const SizedBox(height: 20),

                    // Alternate Number
                    _buildFormField(
                      label: 'Alternate Number',
                      controller: _alternateNumberController,
                      hint: 'Optional: 10-digit alternate number',
                      keyboardType: TextInputType.number,
                      isPhoneNumber: true,
                    ),
                    const SizedBox(height: 20),

                    // GST Number
                    _buildFormField(
                      label: 'GST Number (Optional)',
                      controller: _gstNumberController,
                      hint: 'Enter 15 alphanumeric characters (optional)',
                    ),
                    const SizedBox(height: 20),

                    // Parking Place Availability
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parking Place Availability',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _parkingPlaceAvailability,
                              isExpanded: true,
                              items: <String>['YES', 'NO'].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _parkingPlaceAvailability = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Address Fields - Full Width
                    _buildFormField(
                      label: 'Address Line 1',
                      controller: _addressLine1Controller,
                      hint: 'Address Line 1',
                    ),
                    const SizedBox(height: 20),
                    _buildFormField(
                      label: 'Address Line 2',
                      controller: _addressLine2Controller,
                      hint: 'Address Line 2',
                    ),
                    const SizedBox(height: 20),
                    _buildFormField(
                      label: 'Nearest Railway Station',
                      controller: _nearestRailwayStationController,
                      hint: 'Nearest Railway Station',
                    ),
                    const SizedBox(height: 20),
                    _buildFormField(
                      label: 'Nearest Bus Stop',
                      controller: _nearestBusStopController,
                      hint: 'Nearest Bus Stop',
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Landmark',
                            controller: _landmarkController,
                            hint: 'Landmark',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'Pincode',
                            controller: _pincodeController,
                            hint: 'Pincode',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'State',
                            controller: _stateController,
                            hint: 'State',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'City',
                            controller: _cityController,
                            hint: 'City',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Latitude',
                            controller: _latitudeController,
                            hint: 'Latitude',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'Longitude',
                            controller: _longitudeController,
                            hint: 'Longitude',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            enabled: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // DC Hub
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DC Hub',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: _isFindingDc
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Finding nearest DC...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                            _dcHub,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Location Map Section
                    const Text(
                      'Location Map',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Map Toggle Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildMapToggleButton(
                            'Map',
                            _pickupMapType == MapType.normal,
                            onTap: () {
                              setState(() {
                                _pickupMapType = MapType.normal;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMapToggleButton(
                            'Satellite',
                            _pickupMapType == MapType.satellite,
                            onTap: () {
                              setState(() {
                                _pickupMapType = MapType.satellite;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Map with Search Overlay
                    SizedBox(
                      height: 400,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                    Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: _buildPickupMap(),
                            ),
                            // Full Screen Button
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: GestureDetector(
                                onTap: () => _showFullScreenMap(
                                  context,
                                  _buildPickupMap(),
                                  _pickupMapController,
                                  _pickupMapType,
                                  (MapType type) {
                                    setState(() {
                                      _pickupMapType = type;
                                    });
                                  },
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Color(0xFF1E3A8A),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            // My Location Button
                            Positioned(
                              bottom: 60,
                              left: 10,
                              child: GestureDetector(
                                onTap: _findMyLocationForPickup,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            // Search Bar Overlay
                            Positioned(
                              top: 10,
                              left: 10,
                              right: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                      ),
                      child: TextField(
                                  controller: _pickupSearchController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                                      onChanged: (value) {
                                        // Trigger listener manually to ensure it fires
                                        _onPickupSearchChanged();
                                      },
                        decoration: InputDecoration(
                          hintText: 'Search for a location...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.normal,
                          ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 22,
                                      ),
                                      onPressed: () {
                                            setState(() {
                                              _showPickupSuggestions = false;
                                            });
                                        _searchLocationOnMap(_pickupSearchController.text, true);
                                      },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E3A8A),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                                  onSubmitted: (value) {
                                        setState(() {
                                          _showPickupSuggestions = false;
                                        });
                                    _searchLocationOnMap(value, true);
                                  },
                                      onTap: () {
                                        // Show suggestions when search bar is clicked
                                        if (_pickupSuggestions.isNotEmpty) {
                                          setState(() {
                                            _showPickupSuggestions = true;
                                          });
                                        } else if (_pickupSearchController.text.trim().isNotEmpty) {
                                          // If there's text but no suggestions, fetch them and show
                                          _fetchPlaceSuggestions(_pickupSearchController.text.trim(), true, showSuggestions: true);
                                        }
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _showPickupSuggestions = false;
                                        });
                                      },
                                    ),
                                  ),
                                  // Suggestions Dropdown
                                  if (_showPickupSuggestions && _pickupSuggestions.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: _pickupSuggestions.length,
                                        itemBuilder: (context, index) {
                                          final suggestion = _pickupSuggestions[index];
                                          return InkWell(
                                            onTap: () {
                                              final selectedPlace = suggestion['description'] ?? '';
                                              final placeId = suggestion['place_id'] ?? '';
                                              // Hide dropdown immediately
                                              setState(() {
                                                _showPickupSuggestions = false;
                                                _pickupSuggestions = [];
                                              });
                                              // Unfocus search field
                                              FocusScope.of(context).unfocus();
                                              // Temporarily remove listener to prevent re-triggering
                                              _pickupSearchController.removeListener(_onPickupSearchChanged);
                                              _pickupSearchController.text = selectedPlace;
                                              // Re-add listener after a short delay
                                              Future.delayed(const Duration(milliseconds: 100), () {
                                                if (mounted) {
                                                  _pickupSearchController.addListener(_onPickupSearchChanged);
                                                }
                                              });
                                              // Use place_id for more accurate location
                                              if (placeId.isNotEmpty) {
                                                _searchLocationByPlaceId(placeId, selectedPlace, true);
                                              } else {
                                                _searchLocationOnMap(selectedPlace, true);
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey[200]!,
                                                    width: index < _pickupSuggestions.length - 1 ? 1 : 0,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      suggestion['description'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitPickupAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit Pickup Address',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Add Consignee Address Form
            if (_selectedTab == 'Add Consignee Address') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consignee Address',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Person Name
                    _buildFormField(
                      label: 'Contact Person Name',
                      controller: _consigneeContactPersonNameController,
                      hint: 'Contact Person Name',
                    ),
                    const SizedBox(height: 20),

                    // Company Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Company Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _consigneeSameAsContactPerson,
                              onChanged: (value) {
                                setState(() {
                                  _consigneeSameAsContactPerson = value ?? false;
                                  if (_consigneeSameAsContactPerson) {
                                    _consigneeCompanyNameController.text = _consigneeContactPersonNameController.text;
                                  } else {
                                    _consigneeCompanyNameController.clear();
                                  }
                                });
                              },
                              activeColor: const Color(0xFF1E3A8A),
                            ),
                            const Text(
                              'Same as Contact Person Name',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _consigneeCompanyNameController,
                          hint: 'Company Name',
                          enabled: !_consigneeSameAsContactPerson,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Contact Person Mobile
                    _buildFormField(
                      label: 'Contact Person Mobile',
                      controller: _consigneeContactPersonMobileController,
                      hint: 'Enter 10-digit contact number',
                      keyboardType: TextInputType.number,
                      isPhoneNumber: true,
                    ),
                    const SizedBox(height: 20),

                    // Alternate Number
                    _buildFormField(
                      label: 'Alternate Number',
                      controller: _consigneeAlternateNumberController,
                      hint: 'Optional: 10-digit alternate number',
                      keyboardType: TextInputType.number,
                      isPhoneNumber: true,
                    ),
                    const SizedBox(height: 20),

                    // GST Number
                    _buildFormField(
                      label: 'GST Number (Optional)',
                      controller: _consigneeGstNumberController,
                      hint: 'Enter 15 alphanumeric characters (optional)',
                    ),
                    const SizedBox(height: 20),

                    // Parking Place Availability
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parking Place Availability',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _consigneeParkingPlaceAvailability,
                              isExpanded: true,
                              items: <String>['YES', 'NO'].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _consigneeParkingPlaceAvailability = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Address Fields - Full Width
                    _buildFormField(
                      label: 'Address Line 1',
                      controller: _consigneeAddressLine1Controller,
                      hint: 'Address Line 1',
                    ),
                    const SizedBox(height: 20),
                    _buildFormField(
                      label: 'Address Line 2',
                      controller: _consigneeAddressLine2Controller,
                      hint: 'Address Line 2',
                    ),
                    const SizedBox(height: 20),
                    _buildFormField(
                      label: 'Nearest Railway Station',
                      controller: _consigneeNearestRailwayStationController,
                      hint: 'Nearest Railway Station',
                    ),
                    const SizedBox(height: 20),
                    _buildFormField(
                      label: 'Nearest Bus Stop',
                      controller: _consigneeNearestBusStopController,
                      hint: 'Nearest Bus Stop',
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Landmark',
                            controller: _consigneeLandmarkController,
                            hint: 'Landmark',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'Pincode',
                            controller: _consigneePincodeController,
                            hint: 'Pincode',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'State',
                            controller: _consigneeStateController,
                            hint: 'State',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'City',
                            controller: _consigneeCityController,
                            hint: 'City',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Latitude',
                            controller: _consigneeLatitudeController,
                            hint: 'Latitude',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'Longitude',
                            controller: _consigneeLongitudeController,
                            hint: 'Longitude',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            enabled: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Location Map Section
                    const Text(
                      'Location Map',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Map Toggle Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildMapToggleButton(
                            'Map',
                            _consigneeMapType == MapType.normal,
                            onTap: () {
                              setState(() {
                                _consigneeMapType = MapType.normal;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMapToggleButton(
                            'Satellite',
                            _consigneeMapType == MapType.satellite,
                            onTap: () {
                              setState(() {
                                _consigneeMapType = MapType.satellite;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Map with Search Overlay
                    SizedBox(
                      height: 400,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                    Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: _buildConsigneeMap(),
                            ),
                            // Full Screen Button
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: GestureDetector(
                                onTap: () => _showFullScreenMap(
                                  context,
                                  _buildConsigneeMap(),
                                  _consigneeMapController,
                                  _consigneeMapType,
                                  (MapType type) {
                                    setState(() {
                                      _consigneeMapType = type;
                                    });
                                  },
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Color(0xFF1E3A8A),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            // My Location Button
                            Positioned(
                              bottom: 60,
                              left: 10,
                              child: GestureDetector(
                                onTap: _findMyLocationForConsignee,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            // Search Bar Overlay
                            Positioned(
                              top: 10,
                              left: 10,
                              right: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                      ),
                      child: TextField(
                                  controller: _consigneeSearchController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                                      onChanged: (value) {
                                        // Trigger listener manually to ensure it fires
                                        _onConsigneeSearchChanged();
                                      },
                        decoration: InputDecoration(
                          hintText: 'Search for a location...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.normal,
                          ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 22,
                                      ),
                                      onPressed: () {
                                            setState(() {
                                              _showConsigneeSuggestions = false;
                                            });
                                        _searchLocationOnMap(_consigneeSearchController.text, false);
                                      },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E3A8A),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                                  onSubmitted: (value) {
                                        setState(() {
                                          _showConsigneeSuggestions = false;
                                        });
                                    _searchLocationOnMap(value, false);
                                  },
                                      onTap: () {
                                        // Show suggestions when search bar is clicked
                                        if (_consigneeSuggestions.isNotEmpty) {
                                          setState(() {
                                            _showConsigneeSuggestions = true;
                                          });
                                        } else if (_consigneeSearchController.text.trim().isNotEmpty) {
                                          // If there's text but no suggestions, fetch them and show
                                          _fetchPlaceSuggestions(_consigneeSearchController.text.trim(), false, showSuggestions: true);
                                        }
                                      },
                                      onEditingComplete: () {
                                        setState(() {
                                          _showConsigneeSuggestions = false;
                                        });
                                      },
                                    ),
                                  ),
                                  // Suggestions Dropdown
                                  if (_showConsigneeSuggestions && _consigneeSuggestions.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: _consigneeSuggestions.length,
                                        itemBuilder: (context, index) {
                                          final suggestion = _consigneeSuggestions[index];
                                          return InkWell(
                                            onTap: () {
                                              final selectedPlace = suggestion['description'] ?? '';
                                              final placeId = suggestion['place_id'] ?? '';
                                              // Hide dropdown immediately
                                              setState(() {
                                                _showConsigneeSuggestions = false;
                                                _consigneeSuggestions = [];
                                              });
                                              // Unfocus search field
                                              FocusScope.of(context).unfocus();
                                              // Temporarily remove listener to prevent re-triggering
                                              _consigneeSearchController.removeListener(_onConsigneeSearchChanged);
                                              _consigneeSearchController.text = selectedPlace;
                                              // Re-add listener after a short delay
                                              Future.delayed(const Duration(milliseconds: 100), () {
                                                if (mounted) {
                                                  _consigneeSearchController.addListener(_onConsigneeSearchChanged);
                                                }
                                              });
                                              // Use place_id for more accurate location
                                              if (placeId.isNotEmpty) {
                                                _searchLocationByPlaceId(placeId, selectedPlace, false);
                                              } else {
                                                _searchLocationOnMap(selectedPlace, false);
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey[200]!,
                                                    width: index < _consigneeSuggestions.length - 1 ? 1 : 0,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      suggestion['description'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitConsigneeAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit Consignee Address',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E3A8A),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isActive: false,
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const CustomerHome()),
                      (route) => false,
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.account_balance_wallet,
                  label: 'Wallet',
                  isActive: false,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CustomerWallet()),
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.location_on,
                  label: 'Address',
                  isActive: true,
                  onTap: () {},
                ),
                _buildNavItem(
                  icon: Icons.refresh,
                  label: 'My Orders',
                  isActive: false,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const MyOrders()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(PlaceManagerData place) {
    final isPickup = place.placeType == 'Pickup Place';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showPlaceDetails(place);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Type Badge and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPickup ? const Color(0xFF1E3A8A) : Colors.green[700],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        place.placeType.replaceAll(' Place', ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            _showPlaceDetails(place);
                          },
                          icon: const Icon(
                            Icons.visibility,
                            size: 18,
                            color: Color(0xFF1E3A8A),
                          ),
                          label: const Text(
                            'View',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () {
                            _showEditPlaceDialog(place);
                          },
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Color(0xFF1E3A8A),
                          ),
                          label: const Text(
                            'Edit',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () {
                            _confirmDeletePlace(place);
                          },
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Company Name
                if (place.companyName.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.companyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (place.companyName.isNotEmpty) const SizedBox(height: 8),
                
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.fullAddress.isNotEmpty
                                ? place.fullAddress
                                : '${place.addressLine1} ${place.addressLine2}'.trim(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (place.city.isNotEmpty || place.state.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${place.city}${place.city.isNotEmpty && place.state.isNotEmpty ? ', ' : ''}${place.state}${place.pincode > 0 ? ' - ${place.pincode}' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Contact Person (only show if different from company name)
                if (place.contactPersonName.isNotEmpty && 
                    place.contactPersonName.toLowerCase() != place.companyName.toLowerCase())
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        place.contactPersonName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (place.contactPersonName.isNotEmpty && 
                    place.contactPersonName.toLowerCase() != place.companyName.toLowerCase()) 
                  const SizedBox(height: 8),
                
                // Contact Mobile
                if (place.contactPersonMobile.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        place.contactPersonMobile,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (place.contactPersonMobile.isNotEmpty) const SizedBox(height: 12),
                
                // Footer: Connected Hub and View Details Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (place.connectedHub.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connected Hub',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              place.connectedHub,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A8A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    if (place.connectedHub.isNotEmpty) const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () {
                          _showPlaceDetails(place);
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, bool isActive) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTab = label;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF1E3A8A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[400]!,
                width: 2,
              ),
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
            ),
            child: isSelected
                ? const Center(
                    child: Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E3A8A),
      child: SafeArea(
        child: Column(
          children: [
            // Collapse button
            Container(
              margin: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Navigation Items
            _buildDrawerItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const CustomerHome()),
                  (route) => false,
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.account_balance_wallet,
              label: 'Wallet',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CustomerWallet()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.add_circle_outline,
              label: 'Place Order',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PlaceOrder()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.refresh,
              label: 'My Orders',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MyOrders()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.location_on,
              label: 'Track Order',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TrackOrder()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.store,
              label: 'Place Manager',
              isActive: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.support_agent,
              label: 'Support',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const Support()),
                );
              },
            ),

            const Spacer(),

            // Copyright
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Kartbuddy © 2025 All Right Reserved\nwith Perennial Global Consultancy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.amber : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey[400],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? Colors.white : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool enabled = true,
    bool isPhoneNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: controller,
          hint: hint,
          keyboardType: keyboardType,
          enabled: enabled,
          isPhoneNumber: isPhoneNumber,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool enabled = true,
    bool isPhoneNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: isPhoneNumber ? TextInputType.number : (keyboardType ?? TextInputType.multiline),
        maxLength: isPhoneNumber ? 10 : null,
        maxLines: isPhoneNumber ? 1 : 3, // Allow multiple lines for text fields, single line for phone
        minLines: 1,
        textInputAction: isPhoneNumber ? TextInputAction.done : TextInputAction.newline,
        inputFormatters: isPhoneNumber
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : null,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black87 : Colors.grey[600],
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF1E3A8A),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          counterText: '', // Hide character counter
        ),
      ),
    );
  }

  Widget _buildMapToggleButton(String label, bool isActive, {VoidCallback? onTap}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF1E3A8A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaceDetails(PlaceManagerData place) {
    MapType viewMapType = MapType.normal;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: Responsive.isMobile(context) 
              ? Responsive.widthPercent(context, 95)
              : Responsive.widthPercent(context, 70),
          constraints: BoxConstraints(
            maxHeight: Responsive.heightPercent(context, 90),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        place.placeType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditPlaceDialog(place);
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildEditSectionTitle('Basic Information', Icons.info_outline, Colors.blue),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildReadOnlyField('Place ID', place.placeId),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildReadOnlyField('Address Type', place.placeType),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildReadOnlyField('Connected Hub', place.connectedHub),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Contact Information Section
                      _buildEditSectionTitle('Contact Information', Icons.person, Colors.green),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            _buildReadOnlyField('Contact Person Name', place.contactPersonName),
                            const SizedBox(height: 16),
                            _buildReadOnlyField('Contact Number', place.contactPersonMobile),
                            const SizedBox(height: 16),
                            _buildReadOnlyField('Alternate Number', place.alternateNumber.isNotEmpty ? place.alternateNumber : '-'),
                            const SizedBox(height: 16),
                            _buildReadOnlyField('Company Name', place.companyName),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // GST Number Section
                      if (place.gstNo != null && place.gstNo!.isNotEmpty) ...[
                        _buildEditFormField('GST Number (Optional)', TextEditingController(text: place.gstNo), enabled: false),
                        const SizedBox(height: 24),
                      ],
                      
                      // Address Details Section
                      _buildEditSectionTitle('Address Details', Icons.home, Colors.orange),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            _buildReadOnlyField('Address Line 1', place.addressLine1),
                            const SizedBox(height: 16),
                            _buildReadOnlyField('Address Line 2', place.addressLine2.isNotEmpty ? place.addressLine2 : '-'),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildReadOnlyField('City', place.city),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildReadOnlyField('State', place.state),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildReadOnlyField('Pincode', place.pincode > 0 ? place.pincode.toString() : '-'),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildReadOnlyField('Parking Available', place.parkingPlaceAvailability),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Location & Landmarks Section
                      _buildEditSectionTitle('Location & Landmarks', Icons.location_on, Colors.red),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            _buildReadOnlyField('Nearest Railway Station', place.nearestRailwayStation.isNotEmpty ? place.nearestRailwayStation : '-'),
                            const SizedBox(height: 16),
                            _buildReadOnlyField('Nearest Bus Stop', place.nearestBusStop.isNotEmpty ? place.nearestBusStop : '-'),
                            const SizedBox(height: 16),
                            _buildReadOnlyField('Landmark', place.landmark.isNotEmpty ? place.landmark : '-'),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildReadOnlyField('Latitude', place.latitude.isNotEmpty ? place.latitude : '-'),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildReadOnlyField('Longitude', place.longitude.isNotEmpty ? place.longitude : '-'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Status & Timeline Section
                      _buildEditSectionTitle('Status & Timeline', Icons.check_circle, Colors.purple),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Status: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    place.status,
                                    style: TextStyle(
                                      color: Colors.blue[900],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildReadOnlyField('Status Remark', place.statusRemarks ?? '-'),
                            const SizedBox(height: 16),
                            _buildReadOnlyField('Created At', _formatDate(place.createdAt)),
                            const SizedBox(height: 16),
                            _buildReadOnlyField('Last Updated', _formatDate(place.updatedAt)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Location on Map Section
                      _buildEditSectionTitle('Location on Map', Icons.map, Colors.teal),
                      const SizedBox(height: 12),
                      // Map Toggle Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildMapToggleButton(
                              'Map',
                              viewMapType == MapType.normal,
                              onTap: () {
                                setDialogState(() {
                                  viewMapType = MapType.normal;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMapToggleButton(
                              'Satellite',
                              viewMapType == MapType.satellite,
                              onTap: () {
                                setDialogState(() {
                                  viewMapType = MapType.satellite;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Map View
                      if (place.latitude.isNotEmpty && place.longitude.isNotEmpty)
                        Stack(
                          children: [
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  double.tryParse(place.latitude) ?? 0.0,
                                  double.tryParse(place.longitude) ?? 0.0,
                                ),
                                zoom: 14.0,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('place_location'),
                                  position: LatLng(
                                    double.tryParse(place.latitude) ?? 0.0,
                                    double.tryParse(place.longitude) ?? 0.0,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: place.companyName.isNotEmpty 
                                        ? place.companyName 
                                        : place.contactPersonName,
                                    snippet: place.fullAddress.isNotEmpty 
                                        ? place.fullAddress 
                                        : '${place.addressLine1} ${place.addressLine2}',
                            ),
                          ),
                              },
                              mapType: viewMapType,
                              zoomControlsEnabled: true,
                              myLocationButtonEnabled: false,
                              myLocationEnabled: true,
                              compassEnabled: true,
                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              tiltGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                            ),
                          ),
                            ),
                          // Full Screen Button
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () => _showFullScreenMap(
                                context,
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      double.tryParse(place.latitude) ?? 0.0,
                                      double.tryParse(place.longitude) ?? 0.0,
                                    ),
                                    zoom: 14.0,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('place_location'),
                                      position: LatLng(
                                        double.tryParse(place.latitude) ?? 0.0,
                                        double.tryParse(place.longitude) ?? 0.0,
                                      ),
                                      infoWindow: InfoWindow(
                                        title: place.companyName.isNotEmpty 
                                            ? place.companyName 
                                            : place.contactPersonName,
                                        snippet: place.fullAddress.isNotEmpty 
                                            ? place.fullAddress 
                                            : '${place.addressLine1} ${place.addressLine2}',
                                      ),
                                    ),
                                  },
                                  mapType: viewMapType,
                                  zoomControlsEnabled: true,
                                  myLocationButtonEnabled: false,
                                  myLocationEnabled: true,
                                  compassEnabled: true,
                                  zoomGesturesEnabled: true,
                                  scrollGesturesEnabled: true,
                                  tiltGesturesEnabled: true,
                                  rotateGesturesEnabled: true,
                                ),
                                null,
                                viewMapType,
                                (MapType type) {
                                  setDialogState(() {
                                    viewMapType = type;
                                  });
                                },
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.fullscreen,
                                  color: Color(0xFF1E3A8A),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      else
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                  'No location data available',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    print('🔵 _showErrorDialog called with: $message');
    _showSnackBar(message, isError: true);
  }

  void _showSuccessDialog(String message) {
    print('🔵 _showSuccessDialog called with: $message');
    _showSnackBar(message, isError: false);
    // Reload places and switch to Registered Addresses tab if needed
    _loadPlaces();
    setState(() {
      _selectedTab = 'Registered Addresses';
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) {
      print('❌ Widget not mounted, cannot show snackbar');
      return;
    }
    
    print('🔵 Attempting to show snackbar: $message (isError: $isError)');
    
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars(); // Clear any existing snackbars
      
      final snackBar = SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessenger.hideCurrentSnackBar();
          },
        ),
      );
      
      scaffoldMessenger.showSnackBar(snackBar);
      print('✅ Snackbar shown successfully: $message');
    } catch (e, stackTrace) {
      print('❌ Error showing snackbar: $e');
      print('❌ Stack trace: $stackTrace');
      // Fallback: try with root navigator context
      try {
        final rootContext = Navigator.of(context, rootNavigator: true).context;
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: isError ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        print('✅ Snackbar shown with root navigator context');
      } catch (e2) {
        print('❌ Error showing snackbar with root navigator: $e2');
      }
    }
  }

  void _confirmDeletePlace(PlaceManagerData place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Place'),
        content: Text(
          'Are you sure you want to delete this ${place.placeType.toLowerCase()}?\n\n'
          '${place.companyName}\n'
          '${place.fullAddress.isNotEmpty ? place.fullAddress : "${place.addressLine1} ${place.addressLine2}"}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePlace(place);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlace(PlaceManagerData place) async {
    try {
      final token = await UserService.getToken();
      if (token == null) {
        _showErrorDialog('Authentication token not found.');
        return;
      }

      print('🔵 Deleting place: ${place.placeId}');
      final response = await _authService.deletePlace(place.placeId, token);

      if (mounted) {
        if (response.success) {
          _showSuccessDialog('Place deleted successfully!');
          // Reload places list
          _loadPlaces();
        } else {
          _showErrorDialog(response.message);
        }
      }
    } catch (e) {
      print('❌ Error deleting place: $e');
      if (mounted) {
        _showErrorDialog('Failed to delete place: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _showEditPlaceDialog(PlaceManagerData place) {
    // Create temporary controllers pre-filled with place data
    final editContactPersonNameController = TextEditingController(text: place.contactPersonName);
    final editCompanyNameController = TextEditingController(text: place.companyName);
    final editContactPersonMobileController = TextEditingController(text: place.contactPersonMobile);
    final editAlternateNumberController = TextEditingController(text: place.alternateNumber);
    final editGstNumberController = TextEditingController(text: place.gstNo ?? '');
    final editAddressLine1Controller = TextEditingController(text: place.addressLine1);
    final editAddressLine2Controller = TextEditingController(text: place.addressLine2);
    final editNearestRailwayStationController = TextEditingController(text: place.nearestRailwayStation);
    final editNearestBusStopController = TextEditingController(text: place.nearestBusStop);
    final editLandmarkController = TextEditingController(text: place.landmark);
    final editPincodeController = TextEditingController(text: place.pincode > 0 ? place.pincode.toString() : '');
    final editStateController = TextEditingController(text: place.state);
    final editCityController = TextEditingController(text: place.city);
    final editLatitudeController = TextEditingController(text: place.latitude);
    final editLongitudeController = TextEditingController(text: place.longitude);
    final editSearchController = TextEditingController();
    
    String editParkingPlaceAvailability = place.parkingPlaceAvailability;
    String editDcHub = place.connectedHub;
    bool isUpdating = false;
    
    // Map state for edit dialog
    GoogleMapController? editMapController;
    MapType editMapType = MapType.normal;
    Set<Marker> editMarkers = {};
    
    // Autocomplete suggestions for edit dialog
    List<Map<String, dynamic>> editPlaceSuggestions = [];
    bool showEditSuggestions = false;

    showDialog(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          place.placeType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Dispose controllers
                          editContactPersonNameController.dispose();
                          editCompanyNameController.dispose();
                          editContactPersonMobileController.dispose();
                          editAlternateNumberController.dispose();
                          editGstNumberController.dispose();
                          editAddressLine1Controller.dispose();
                          editAddressLine2Controller.dispose();
                          editNearestRailwayStationController.dispose();
                          editNearestBusStopController.dispose();
                          editLandmarkController.dispose();
                          editPincodeController.dispose();
                          editStateController.dispose();
                          editCityController.dispose();
                          editLatitudeController.dispose();
                          editLongitudeController.dispose();
                        },
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information Section
                        _buildEditSectionTitle('Basic Information', Icons.info_outline, Colors.blue),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildReadOnlyField('Place ID', place.placeId),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildReadOnlyField('Address Type', place.placeType),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildReadOnlyField('Connected Hub', editDcHub),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Contact Information Section
                        _buildEditSectionTitle('Contact Information', Icons.person, Colors.green),
                        const SizedBox(height: 12),
                        _buildEditFormField('Contact Person Name', editContactPersonNameController),
                        const SizedBox(height: 12),
                        _buildEditFormField('Contact Number', editContactPersonMobileController, keyboardType: TextInputType.number, isPhoneNumber: true),
                        const SizedBox(height: 12),
                        _buildEditFormField('Alternate Number', editAlternateNumberController, keyboardType: TextInputType.number, isPhoneNumber: true),
                        const SizedBox(height: 12),
                        _buildEditFormField('Company Name', editCompanyNameController),
                        const SizedBox(height: 24),
                        
                        // GST Number Section
                        _buildEditFormField('GST Number (Optional)', editGstNumberController),
                        const SizedBox(height: 24),
                        
                        // Address Details Section
                        _buildEditSectionTitle('Address Details', Icons.home, Colors.orange),
                        const SizedBox(height: 12),
                        _buildEditFormField('Address Line 1', editAddressLine1Controller),
                        const SizedBox(height: 12),
                        _buildEditFormField('Address Line 2', editAddressLine2Controller),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildEditFormField('City', editCityController),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildEditFormField('State', editStateController),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildEditFormField('Pincode', editPincodeController, keyboardType: TextInputType.number),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Parking Available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: editParkingPlaceAvailability,
                                        isExpanded: true,
                                        items: <String>['YES', 'NO'].map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setDialogState(() {
                                            editParkingPlaceAvailability = newValue!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Location & Landmarks Section
                        _buildEditSectionTitle('Location & Landmarks', Icons.location_on, Colors.red),
                        const SizedBox(height: 12),
                        _buildEditFormField('Nearest Railway Station', editNearestRailwayStationController),
                        const SizedBox(height: 12),
                        _buildEditFormField('Nearest Bus Stop', editNearestBusStopController),
                        const SizedBox(height: 12),
                        _buildEditFormField('Landmark', editLandmarkController),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildEditFormField('Latitude', editLatitudeController, keyboardType: TextInputType.numberWithOptions(decimal: true), enabled: false),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildEditFormField('Longitude', editLongitudeController, keyboardType: TextInputType.numberWithOptions(decimal: true), enabled: false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Click on the map to set location. Coordinates will update automatically.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[900],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Status & Timeline Section
                        _buildEditSectionTitle('Status & Timeline', Icons.check_circle, Colors.purple),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Status: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      place.status,
                                      style: TextStyle(
                                        color: Colors.blue[900],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildReadOnlyField('Status Remark', place.statusRemarks ?? '-'),
                              const SizedBox(height: 8),
                              _buildReadOnlyField('Created At', _formatDate(place.createdAt)),
                              const SizedBox(height: 8),
                              _buildReadOnlyField('Last Updated', _formatDate(place.updatedAt)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Search and Set Location Section
                        _buildEditSectionTitle('Search and Set Location', Icons.map, Colors.teal),
                        const SizedBox(height: 12),
                        // Map Toggle Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildMapToggleButton(
                                'Map',
                                editMapType == MapType.normal,
                                onTap: () {
                                  setDialogState(() {
                                    editMapType = MapType.normal;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMapToggleButton(
                                'Satellite',
                                editMapType == MapType.satellite,
                                onTap: () {
                                  setDialogState(() {
                                    editMapType = MapType.satellite;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Google Map with Search Overlay
                        SizedBox(
                          height: 400,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: _buildEditMap(
                                    editLatitudeController,
                                    editLongitudeController,
                                    editMapType,
                                    editMarkers,
                                    (controller) => editMapController = controller,
                                    (type) {
                                      setDialogState(() {
                                        editMapType = type;
                                      });
                                    },
                                    (markers) {
                                      setDialogState(() {
                                        editMarkers = markers;
                                      });
                                    },
                                    editMapController,
                                    () {
                                      // Trigger UI update when coordinates change
                                      setDialogState(() {});
                                    },
                                  ),
                                ),
                                // Full Screen Button
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: GestureDetector(
                                    onTap: () => _showFullScreenMap(
                                      context,
                                      _buildEditMap(
                                        editLatitudeController,
                                        editLongitudeController,
                                        editMapType,
                                        editMarkers,
                                        (controller) => editMapController = controller,
                                        (type) {
                                          setDialogState(() {
                                            editMapType = type;
                                          });
                                        },
                                        (markers) {
                                          setDialogState(() {
                                            editMarkers = markers;
                                          });
                                        },
                                        editMapController,
                                        () {
                                          setDialogState(() {});
                                        },
                                      ),
                                      editMapController,
                                      editMapType,
                                      (MapType type) {
                                        setDialogState(() {
                                          editMapType = type;
                                        });
                                      },
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.fullscreen,
                                        color: Color(0xFF1E3A8A),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                // My Location Button for Edit Map
                                Positioned(
                                  bottom: 60,
                                  left: 10,
                                  child: GestureDetector(
                                    onTap: () async {
                                      Position? position = await _getCurrentLocation();
                                      if (position != null && editMapController != null) {
                                        final currentLocation = LatLng(position.latitude, position.longitude);
                                        editMapController!.animateCamera(
                                          CameraUpdate.newLatLngZoom(currentLocation, 15.0),
                                        );
                                        setDialogState(() {
                                          editLatitudeController.text = position.latitude.toStringAsFixed(7);
                                          editLongitudeController.text = position.longitude.toStringAsFixed(7);
                                          // Preserve blue marker
                                          final blueMarker = _currentPosition != null
                                              ? Marker(
                                                  markerId: const MarkerId('current_location_edit'),
                                                  position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                                  infoWindow: const InfoWindow(
                                                    title: 'My Current Location',
                                                    snippet: 'Your live location',
                                                  ),
                                                )
                                              : null;
                                          final newMarkers = {
                                            Marker(
                                              markerId: const MarkerId('edit_location'),
                                              position: currentLocation,
                                              draggable: true,
                                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                              onDragEnd: (LatLng newPosition) {
                                                editLatitudeController.text = newPosition.latitude.toStringAsFixed(7);
                                                editLongitudeController.text = newPosition.longitude.toStringAsFixed(7);
                                                // Preserve blue marker
                                                final blueMarker = _currentPosition != null
                                                    ? Marker(
                                                        markerId: const MarkerId('current_location_edit'),
                                                        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                                        infoWindow: const InfoWindow(
                                                          title: 'My Current Location',
                                                          snippet: 'Your live location',
                                                        ),
                                                      )
                                                    : null;
                                                final updatedMarkers = {
                                                  Marker(
                                                    markerId: const MarkerId('edit_location'),
                                                    position: newPosition,
                                                    draggable: true,
                                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                                  ),
                                                };
                                                if (blueMarker != null) {
                                                  updatedMarkers.add(blueMarker);
                                                }
                                                setDialogState(() {
                                                  editMarkers = updatedMarkers;
                                                });
                                              },
                                            ),
                                          };
                                          if (blueMarker != null) {
                                            newMarkers.add(blueMarker);
                                          }
                                          editMarkers = newMarkers;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.my_location,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                // Search Bar Overlay
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  right: 10,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: editSearchController,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          onChanged: (value) {
                                            if (value.trim().length >= 1) {
                                              _fetchEditPlaceSuggestions(value, setDialogState, (suggestions) {
                                                setDialogState(() {
                                                  editPlaceSuggestions = suggestions;
                                                  showEditSuggestions = suggestions.isNotEmpty;
                                                });
                                              });
                                            } else {
                                              setDialogState(() {
                                                editPlaceSuggestions = [];
                                                showEditSuggestions = false;
                                              });
                                            }
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Search for a location...',
                                            hintStyle: TextStyle(
                                              color: Colors.grey[400],
                                              fontWeight: FontWeight.normal,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                Icons.search,
                                                color: Colors.grey[600],
                                                size: 22,
                                              ),
                                              onPressed: () async {
                                                setDialogState(() {
                                                  showEditSuggestions = false;
                                                });
                                                final query = editSearchController.text.trim();
                                                if (query.isEmpty) return;
                                                await _searchLocationForEditWithPlaceId(
                                                  query,
                                                  editLatitudeController,
                                                  editLongitudeController,
                                                  editMapController,
                                                  setDialogState,
                                                  (markers) {
                                                    setDialogState(() {
                                                      editMarkers = markers;
                                                    });
                                                  },
                                                );
                                              },
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF1E3A8A),
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                          ),
                                          onSubmitted: (value) async {
                                            setDialogState(() {
                                              showEditSuggestions = false;
                                            });
                                            if (value.trim().isEmpty) return;
                                            await _searchLocationForEditWithPlaceId(
                                              value,
                                              editLatitudeController,
                                              editLongitudeController,
                                              editMapController,
                                              setDialogState,
                                              (markers) {
                                                setDialogState(() {
                                                  editMarkers = markers;
                                                });
                                              },
                                            );
                                          },
                                          onTap: () {
                                            if (editPlaceSuggestions.isNotEmpty) {
                                              setDialogState(() {
                                                showEditSuggestions = true;
                                              });
                                            } else if (editSearchController.text.trim().isNotEmpty) {
                                              _fetchEditPlaceSuggestions(editSearchController.text.trim(), setDialogState, (suggestions) {
                                                setDialogState(() {
                                                  editPlaceSuggestions = suggestions;
                                                  showEditSuggestions = suggestions.isNotEmpty;
                                                });
                                              });
                                            }
                                          },
                                          onEditingComplete: () {
                                            setDialogState(() {
                                              showEditSuggestions = false;
                                            });
                                          },
                                        ),
                                      ),
                                      // Suggestions Dropdown
                                      if (showEditSuggestions && editPlaceSuggestions.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          constraints: const BoxConstraints(maxHeight: 200),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            padding: EdgeInsets.zero,
                                            itemCount: editPlaceSuggestions.length,
                                            itemBuilder: (context, index) {
                                              final suggestion = editPlaceSuggestions[index];
                                              return InkWell(
                                                onTap: () {
                                                  final selectedPlace = suggestion['description'] ?? '';
                                                  final placeId = suggestion['place_id'] ?? '';
                                                  // Hide dropdown immediately
                                                  setDialogState(() {
                                                    showEditSuggestions = false;
                                                    editPlaceSuggestions = [];
                                                  });
                                                  // Unfocus search field
                                                  FocusScope.of(context).unfocus();
                                                  editSearchController.text = selectedPlace;
                                                  // Use place_id for more accurate location
                                                  if (placeId.isNotEmpty) {
                                                    _searchLocationForEditByPlaceId(
                                                      placeId,
                                                      selectedPlace,
                                                      editLatitudeController,
                                                      editLongitudeController,
                                                      editMapController,
                                                      setDialogState,
                                                      (markers) {
                                                        setDialogState(() {
                                                          editMarkers = markers;
                                                        });
                                                      },
                                                    );
                                                  } else {
                                                    _searchLocationForEditWithPlaceId(
                                                      selectedPlace,
                                                      editLatitudeController,
                                                      editLongitudeController,
                                                      editMapController,
                                                      setDialogState,
                                                      (markers) {
                                                        setDialogState(() {
                                                          editMarkers = markers;
                                                        });
                                                      },
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: Colors.grey[200]!,
                                                        width: index < editPlaceSuggestions.length - 1 ? 1 : 0,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          suggestion['description'] ?? '',
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isUpdating ? null : () {
                          Navigator.of(context).pop();
                          // Dispose controllers
                          editContactPersonNameController.dispose();
                          editCompanyNameController.dispose();
                          editContactPersonMobileController.dispose();
                          editAlternateNumberController.dispose();
                          editGstNumberController.dispose();
                          editAddressLine1Controller.dispose();
                          editAddressLine2Controller.dispose();
                          editNearestRailwayStationController.dispose();
                          editNearestBusStopController.dispose();
                          editLandmarkController.dispose();
                          editPincodeController.dispose();
                          editStateController.dispose();
                          editCityController.dispose();
                          editLatitudeController.dispose();
                          editLongitudeController.dispose();
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isUpdating ? null : () async {
                          // Validate
                          if (editContactPersonNameController.text.trim().isEmpty ||
                              editCompanyNameController.text.trim().isEmpty ||
                              editContactPersonMobileController.text.trim().isEmpty ||
                              editAddressLine1Controller.text.trim().isEmpty ||
                              editCityController.text.trim().isEmpty ||
                              editStateController.text.trim().isEmpty ||
                              editPincodeController.text.trim().isEmpty ||
                              editLatitudeController.text.trim().isEmpty ||
                              editLongitudeController.text.trim().isEmpty) {
                            _showErrorDialog('Please fill all required fields');
                            return;
                          }

                          setDialogState(() {
                            isUpdating = true;
                          });

                          try {
                            final token = await UserService.getToken();
                            final customer = await UserService.getCustomer();
                            
                            if (token == null || customer == null) {
                              _showErrorDialog('Authentication token or customer ID not found.');
                              setDialogState(() {
                                isUpdating = false;
                              });
                              return;
                            }

                            final request = PlaceUpdateRequest(
                              contactPersonName: editContactPersonNameController.text.trim(),
                              companyName: editCompanyNameController.text.trim(),
                              gstNo: editGstNumberController.text.trim().isNotEmpty ? editGstNumberController.text.trim() : null,
                              addressLine1: editAddressLine1Controller.text.trim(),
                              addressLine2: editAddressLine2Controller.text.trim(),
                              alternateNumber: editAlternateNumberController.text.trim().isNotEmpty
                                  ? editAlternateNumberController.text.trim()
                                  : '',
                              city: editCityController.text.trim(),
                              connectedHub: editDcHub,
                              contactPersonMobile: editContactPersonMobileController.text.trim(),
                              createdBy: 'Customer',
                              latitude: double.tryParse(editLatitudeController.text.trim()) ?? 0.0,
                              longitude: double.tryParse(editLongitudeController.text.trim()) ?? 0.0,
                              nearestBusStop: editNearestBusStopController.text.trim(),
                              nearestRailwayStation: editNearestRailwayStationController.text.trim(),
                              landmark: editLandmarkController.text.trim(),
                              parkingPlaceAvailability: editParkingPlaceAvailability,
                              pincode: int.tryParse(editPincodeController.text.trim()) ?? 0,
                              placeSource: customer.id,
                              placeSourceName: customer.fullName,
                              state: editStateController.text.trim(),
                              status: 'Approved',
                            );

                            print('🔵 Updating place: ${place.placeId}');
                            final response = await _authService.updatePlace(place.placeId, request, token);

                            if (mounted) {
                              Navigator.of(context).pop();
                              // Dispose controllers
                              editContactPersonNameController.dispose();
                              editCompanyNameController.dispose();
                              editContactPersonMobileController.dispose();
                              editAlternateNumberController.dispose();
                              editGstNumberController.dispose();
                              editAddressLine1Controller.dispose();
                              editAddressLine2Controller.dispose();
                              editNearestRailwayStationController.dispose();
                              editNearestBusStopController.dispose();
                              editLandmarkController.dispose();
                              editPincodeController.dispose();
                              editStateController.dispose();
                              editCityController.dispose();
                              editLatitudeController.dispose();
                              editLongitudeController.dispose();

                              if (response.success) {
                                _showSuccessDialog('Place updated successfully!');
                                _loadPlaces();
                              } else {
                                _showErrorDialog(response.message);
                              }
                            }
                          } catch (e) {
                            print('❌ Error updating place: $e');
                            if (mounted) {
                              setDialogState(() {
                                isUpdating = false;
                              });
                              _showErrorDialog('Failed to update place: ${e.toString().replaceAll('Exception: ', '')}');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: isUpdating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildEditFormField(String label, TextEditingController controller, {TextInputType? keyboardType, bool enabled = true, bool isPhoneNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isPhoneNumber ? TextInputType.number : keyboardType,
          enabled: enabled,
          maxLength: isPhoneNumber ? 10 : null,
          inputFormatters: isPhoneNumber
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ]
              : null,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: !enabled,
            fillColor: enabled ? Colors.white : Colors.grey[50],
            counterText: '', // Hide character counter
          ),
          style: TextStyle(
            color: enabled ? Colors.black87 : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _formatCoordinates(String lat, String lng) {
    try {
      final latitude = double.parse(lat);
      final longitude = double.parse(lng);
      
      // Convert to degrees, minutes, seconds format
      String formatDMS(double coord, bool isLat) {
        final abs = coord.abs();
        final degrees = abs.floor();
        final minutes = ((abs - degrees) * 60).floor();
        final seconds = ((abs - degrees) * 60 - minutes) * 60;
        final direction = isLat 
            ? (coord >= 0 ? 'N' : 'S')
            : (coord >= 0 ? 'E' : 'W');
        return "$degrees°$minutes'${seconds.toStringAsFixed(1)}\"$direction";
      }
      
      return '${formatDMS(latitude, true)} ${formatDMS(longitude, false)}';
    } catch (e) {
      return '$lat, $lng';
    }
  }

  Future<void> _submitPickupAddress() async {
    // Validate required fields
    if (_contactPersonNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter contact person name');
      return;
    }
    if (_companyNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter company name');
      return;
    }
    if (_contactPersonMobileController.text.trim().isEmpty) {
      _showErrorDialog('Please enter contact person mobile');
      return;
    }
    if (_addressLine1Controller.text.trim().isEmpty) {
      _showErrorDialog('Please enter address line 1');
      return;
    }
    if (_cityController.text.trim().isEmpty) {
      _showErrorDialog('Please enter city');
      return;
    }
    if (_stateController.text.trim().isEmpty) {
      _showErrorDialog('Please enter state');
      return;
    }
    if (_pincodeController.text.trim().isEmpty) {
      _showErrorDialog('Please enter pincode');
      return;
    }
    if (_latitudeController.text.trim().isEmpty || _longitudeController.text.trim().isEmpty) {
      _showErrorDialog('Please enter latitude and longitude');
      return;
    }
    if (_dcHub == 'Not available' || _dcHub.isEmpty) {
      _showErrorDialog('Please select a connected hub');
      return;
    }

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        _showErrorDialog('Authentication token or customer ID not found.');
        return;
      }

      final request = PlaceRegisterRequest(
        contactPersonName: _contactPersonNameController.text.trim(),
        companyName: _companyNameController.text.trim(),
        gstNo: _gstNumberController.text.trim().isNotEmpty ? _gstNumberController.text.trim() : null,
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        alternateNumber: _alternateNumberController.text.trim().isNotEmpty
            ? _alternateNumberController.text.trim()
            : '',
        city: _cityController.text.trim(),
        connectedHub: _dcHub,
        contactPersonMobile: _contactPersonMobileController.text.trim(),
        createdBy: 'Customer',
        latitude: double.tryParse(_latitudeController.text.trim()) ?? 0.0,
        longitude: double.tryParse(_longitudeController.text.trim()) ?? 0.0,
        nearestBusStop: _nearestBusStopController.text.trim(),
        nearestRailwayStation: _nearestRailwayStationController.text.trim(),
        landmark: _landmarkController.text.trim(),
        parkingPlaceAvailability: _parkingPlaceAvailability,
        pincode: int.tryParse(_pincodeController.text.trim()) ?? 0,
        placeSource: customer.id,
        placeSourceName: customer.fullName,
        placeType: 'Pickup Place',
        state: _stateController.text.trim(),
        status: 'Approved',
      );

      print('🔵 Submitting pickup address...');
      final response = await _authService.registerPlace(request, token);

      if (mounted) {
        if (response.success) {
          _showSuccessDialog('Pickup address registered successfully!');
          // Clear form
          _contactPersonNameController.clear();
          _companyNameController.clear();
          _contactPersonMobileController.clear();
          _alternateNumberController.clear();
          _gstNumberController.clear();
          _addressLine1Controller.clear();
          _addressLine2Controller.clear();
          _nearestRailwayStationController.clear();
          _nearestBusStopController.clear();
          _landmarkController.clear();
          _pincodeController.clear();
          _stateController.clear();
          _cityController.clear();
          _latitudeController.clear();
          _longitudeController.clear();
        } else {
          _showErrorDialog(response.message);
        }
      }
    } catch (e) {
      print('❌ Error submitting pickup address: $e');
      if (mounted) {
        _showErrorDialog('Failed to submit pickup address: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  Future<void> _submitConsigneeAddress() async {
    // Validate required fields
    if (_consigneeContactPersonNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter contact person name');
      return;
    }
    if (_consigneeCompanyNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter company name');
      return;
    }
    if (_consigneeContactPersonMobileController.text.trim().isEmpty) {
      _showErrorDialog('Please enter contact person mobile');
      return;
    }
    if (_consigneeAddressLine1Controller.text.trim().isEmpty) {
      _showErrorDialog('Please enter address line 1');
      return;
    }
    if (_consigneeCityController.text.trim().isEmpty) {
      _showErrorDialog('Please enter city');
      return;
    }
    if (_consigneeStateController.text.trim().isEmpty) {
      _showErrorDialog('Please enter state');
      return;
    }
    if (_consigneePincodeController.text.trim().isEmpty) {
      _showErrorDialog('Please enter pincode');
      return;
    }
    if (_consigneeLatitudeController.text.trim().isEmpty || _consigneeLongitudeController.text.trim().isEmpty) {
      _showErrorDialog('Please enter latitude and longitude');
      return;
    }
    if (_consigneeDcHub == 'Not available' || _consigneeDcHub.isEmpty) {
      _showErrorDialog('Please select a connected hub');
      return;
    }

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        _showErrorDialog('Authentication token or customer ID not found.');
        return;
      }

      final request = PlaceRegisterRequest(
        contactPersonName: _consigneeContactPersonNameController.text.trim(),
        companyName: _consigneeCompanyNameController.text.trim(),
        gstNo: _consigneeGstNumberController.text.trim().isNotEmpty ? _consigneeGstNumberController.text.trim() : null,
        addressLine1: _consigneeAddressLine1Controller.text.trim(),
        addressLine2: _consigneeAddressLine2Controller.text.trim(),
        alternateNumber: _consigneeAlternateNumberController.text.trim().isNotEmpty
            ? _consigneeAlternateNumberController.text.trim()
            : '',
        city: _consigneeCityController.text.trim(),
        connectedHub: _consigneeDcHub,
        contactPersonMobile: _consigneeContactPersonMobileController.text.trim(),
        createdBy: 'Customer',
        latitude: double.tryParse(_consigneeLatitudeController.text.trim()) ?? 0.0,
        longitude: double.tryParse(_consigneeLongitudeController.text.trim()) ?? 0.0,
        nearestBusStop: _consigneeNearestBusStopController.text.trim(),
        nearestRailwayStation: _consigneeNearestRailwayStationController.text.trim(),
        landmark: _consigneeLandmarkController.text.trim(),
        parkingPlaceAvailability: _consigneeParkingPlaceAvailability,
        pincode: int.tryParse(_consigneePincodeController.text.trim()) ?? 0,
        placeSource: customer.id,
        placeSourceName: customer.fullName,
        placeType: 'Consignee Place',
        state: _consigneeStateController.text.trim(),
        status: 'Approved',
      );

      print('🔵 Submitting consignee address...');
      final response = await _authService.registerPlace(request, token);

      if (mounted) {
        if (response.success) {
          _showSuccessDialog('Consignee address registered successfully!');
          // Clear form
          _consigneeContactPersonNameController.clear();
          _consigneeCompanyNameController.clear();
          _consigneeContactPersonMobileController.clear();
          _consigneeAlternateNumberController.clear();
          _consigneeGstNumberController.clear();
          _consigneeAddressLine1Controller.clear();
          _consigneeAddressLine2Controller.clear();
          _consigneeNearestRailwayStationController.clear();
          _consigneeNearestBusStopController.clear();
          _consigneeLandmarkController.clear();
          _consigneePincodeController.clear();
          _consigneeStateController.clear();
          _consigneeCityController.clear();
          _consigneeLatitudeController.clear();
          _consigneeLongitudeController.clear();
        } else {
          _showErrorDialog(response.message);
        }
      }
    } catch (e) {
      print('❌ Error submitting consignee address: $e');
      if (mounted) {
        _showErrorDialog('Failed to submit consignee address: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  Widget _buildEditSectionTitle(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = date.day;
      final month = months[date.month - 1];
      final year = date.year;
      final hour = date.hour;
      final minute = date.minute;
      final period = hour >= 12 ? 'pm' : 'am';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$day $month $year, ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildPickupMap() {
    double? lat = double.tryParse(_latitudeController.text.trim());
    double? lng = double.tryParse(_longitudeController.text.trim());
    
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
      // Default to Mumbai if no coordinates
      lat = 19.0760;
      lng = 72.8777;
    }
    
    final initialPosition = LatLng(lat, lng);
    
    // Update markers - include red marker for selected location and blue marker for current location
    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('pickup_location'),
        position: initialPosition,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onDragEnd: (LatLng newPosition) {
          setState(() {
            _latitudeController.text = newPosition.latitude.toStringAsFixed(7);
            _longitudeController.text = newPosition.longitude.toStringAsFixed(7);
            // Preserve blue marker for current location
            final blueMarker = _pickupMarkers.firstWhere(
              (m) => m.markerId.value == 'current_location_pickup',
              orElse: () => _currentPosition != null
                  ? Marker(
                      markerId: const MarkerId('current_location_pickup'),
                      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: const InfoWindow(
                        title: 'My Current Location',
                        snippet: 'Your live location',
                      ),
                    )
                  : Marker(
                      markerId: const MarkerId('current_location_pickup'),
                      position: newPosition,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    ),
            );
            _pickupMarkers = {
              Marker(
                markerId: const MarkerId('pickup_location'),
                position: newPosition,
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                onDragEnd: (LatLng pos) {
                  setState(() {
                    // Preserve blue marker
                    final blueMarker = _pickupMarkers.firstWhere(
                      (m) => m.markerId.value == 'current_location_pickup',
                      orElse: () => _currentPosition != null
                          ? Marker(
                              markerId: const MarkerId('current_location_pickup'),
                              position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                              infoWindow: const InfoWindow(
                                title: 'My Current Location',
                                snippet: 'Your live location',
                              ),
                            )
                          : Marker(
                              markerId: const MarkerId('current_location_pickup'),
                              position: pos,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            ),
                    );
                    _pickupMarkers = {
                      Marker(
                        markerId: const MarkerId('pickup_location'),
                        position: pos,
                        draggable: true,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                      blueMarker,
                    };
                    _latitudeController.text = pos.latitude.toStringAsFixed(7);
                    _longitudeController.text = pos.longitude.toStringAsFixed(7);
                  });
                  _findNearestDcForPickup();
                },
              ),
              blueMarker,
            };
          });
          // Find nearest DC when coordinates change
          _findNearestDcForPickup();
        },
      ),
    };
    
    // Add blue marker for current location if available
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location_pickup'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'My Current Location',
            snippet: 'Your live location',
          ),
        ),
      );
    }
    
    _pickupMarkers = markers;
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 14.0,
      ),
      mapType: _pickupMapType,
      markers: _pickupMarkers,
      onMapCreated: (GoogleMapController controller) {
        _pickupMapController = controller;
        print('✅ Pickup map created successfully');
      },
      onCameraMove: (CameraPosition position) {
        // Update coordinates as camera moves (optional)
      },
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      onTap: (LatLng position) {
        setState(() {
          _latitudeController.text = position.latitude.toStringAsFixed(7);
          _longitudeController.text = position.longitude.toStringAsFixed(7);
          // Preserve blue marker for current location
          final blueMarker = _pickupMarkers.firstWhere(
            (m) => m.markerId.value == 'current_location_pickup',
            orElse: () => _currentPosition != null
                ? Marker(
                    markerId: const MarkerId('current_location_pickup'),
                    position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(
                      title: 'My Current Location',
                      snippet: 'Your live location',
                    ),
                  )
                : Marker(
                    markerId: const MarkerId('current_location_pickup'),
                    position: position,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  ),
          );
          _pickupMarkers = {
            Marker(
              markerId: const MarkerId('pickup_location'),
              position: position,
              draggable: true,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              onDragEnd: (LatLng newPosition) {
                setState(() {
                  _latitudeController.text = newPosition.latitude.toStringAsFixed(7);
                  _longitudeController.text = newPosition.longitude.toStringAsFixed(7);
                  // Preserve blue marker
                  final blueMarker = _pickupMarkers.firstWhere(
                    (m) => m.markerId.value == 'current_location_pickup',
                    orElse: () => _currentPosition != null
                        ? Marker(
                            markerId: const MarkerId('current_location_pickup'),
                            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            infoWindow: const InfoWindow(
                              title: 'My Current Location',
                              snippet: 'Your live location',
                            ),
                          )
                        : Marker(
                            markerId: const MarkerId('current_location_pickup'),
                            position: newPosition,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                          ),
                  );
                  _pickupMarkers = {
                    Marker(
                      markerId: const MarkerId('pickup_location'),
                      position: newPosition,
                      draggable: true,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      onDragEnd: (LatLng pos) {
                        setState(() {
                          // Preserve blue marker
                          final blueMarker = _pickupMarkers.firstWhere(
                            (m) => m.markerId.value == 'current_location_pickup',
                            orElse: () => _currentPosition != null
                                ? Marker(
                                    markerId: const MarkerId('current_location_pickup'),
                                    position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                    infoWindow: const InfoWindow(
                                      title: 'My Current Location',
                                      snippet: 'Your live location',
                                    ),
                                  )
                                : Marker(
                                    markerId: const MarkerId('current_location_pickup'),
                                    position: pos,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                  ),
                          );
                          _pickupMarkers = {
                            Marker(
                              markerId: const MarkerId('pickup_location'),
                              position: pos,
                              draggable: true,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            ),
                            blueMarker,
                          };
                          _latitudeController.text = pos.latitude.toStringAsFixed(7);
                          _longitudeController.text = pos.longitude.toStringAsFixed(7);
                        });
                        _findNearestDcForPickup();
                      },
                    ),
                    blueMarker,
                  };
                });
                _findNearestDcForPickup();
              },
            ),
            blueMarker,
          };
        });
        _pickupMapController?.animateCamera(
          CameraUpdate.newLatLng(position),
        );
        _findNearestDcForPickup();
      },
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      zoomControlsEnabled: true,
    );
  }

  Widget _buildConsigneeMap() {
    double? lat = double.tryParse(_consigneeLatitudeController.text.trim());
    double? lng = double.tryParse(_consigneeLongitudeController.text.trim());
    
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
      // Default to Mumbai if no coordinates
      lat = 19.0760;
      lng = 72.8777;
    }
    
    final initialPosition = LatLng(lat, lng);
    
    // Update markers - include red marker for selected location and blue marker for current location
    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('consignee_location'),
        position: initialPosition,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onDragEnd: (LatLng newPosition) {
          setState(() {
            _consigneeLatitudeController.text = newPosition.latitude.toStringAsFixed(7);
            _consigneeLongitudeController.text = newPosition.longitude.toStringAsFixed(7);
            // Preserve blue marker for current location
            final blueMarker = _consigneeMarkers.firstWhere(
              (m) => m.markerId.value == 'current_location_consignee',
              orElse: () => _currentPosition != null
                  ? Marker(
                      markerId: const MarkerId('current_location_consignee'),
                      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: const InfoWindow(
                        title: 'My Current Location',
                        snippet: 'Your live location',
                      ),
                    )
                  : Marker(
                      markerId: const MarkerId('current_location_consignee'),
                      position: newPosition,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    ),
            );
            _consigneeMarkers = {
              Marker(
                markerId: const MarkerId('consignee_location'),
                position: newPosition,
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                onDragEnd: (LatLng pos) {
                  setState(() {
                    // Preserve blue marker
                    final blueMarker = _consigneeMarkers.firstWhere(
                      (m) => m.markerId.value == 'current_location_consignee',
                      orElse: () => _currentPosition != null
                          ? Marker(
                              markerId: const MarkerId('current_location_consignee'),
                              position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                              infoWindow: const InfoWindow(
                                title: 'My Current Location',
                                snippet: 'Your live location',
                              ),
                            )
                          : Marker(
                              markerId: const MarkerId('current_location_consignee'),
                              position: pos,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            ),
                    );
                    _consigneeMarkers = {
                      Marker(
                        markerId: const MarkerId('consignee_location'),
                        position: pos,
                        draggable: true,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                      blueMarker,
                    };
                    _consigneeLatitudeController.text = pos.latitude.toStringAsFixed(7);
                    _consigneeLongitudeController.text = pos.longitude.toStringAsFixed(7);
                  });
                  _findNearestDcForConsignee();
                },
              ),
              blueMarker,
            };
          });
          _findNearestDcForConsignee();
        },
      ),
    };
    
    // Add blue marker for current location if available
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location_consignee'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'My Current Location',
            snippet: 'Your live location',
          ),
        ),
      );
    }
    
    _consigneeMarkers = markers;
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 14.0,
      ),
      mapType: _consigneeMapType,
      markers: _consigneeMarkers,
      onMapCreated: (GoogleMapController controller) {
        _consigneeMapController = controller;
        print('✅ Consignee map created successfully');
      },
      onCameraMove: (CameraPosition position) {
        // Update coordinates as camera moves (optional)
      },
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      onTap: (LatLng position) {
        setState(() {
          _consigneeLatitudeController.text = position.latitude.toStringAsFixed(7);
          _consigneeLongitudeController.text = position.longitude.toStringAsFixed(7);
          // Preserve blue marker for current location
          final blueMarker = _consigneeMarkers.firstWhere(
            (m) => m.markerId.value == 'current_location_consignee',
            orElse: () => _currentPosition != null
                ? Marker(
                    markerId: const MarkerId('current_location_consignee'),
                    position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(
                      title: 'My Current Location',
                      snippet: 'Your live location',
                    ),
                  )
                : Marker(
                    markerId: const MarkerId('current_location_consignee'),
                    position: position,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  ),
          );
          _consigneeMarkers = {
            Marker(
              markerId: const MarkerId('consignee_location'),
              position: position,
              draggable: true,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              onDragEnd: (LatLng newPosition) {
                setState(() {
                  _consigneeLatitudeController.text = newPosition.latitude.toStringAsFixed(7);
                  _consigneeLongitudeController.text = newPosition.longitude.toStringAsFixed(7);
                  // Preserve blue marker
                  final blueMarker = _consigneeMarkers.firstWhere(
                    (m) => m.markerId.value == 'current_location_consignee',
                    orElse: () => _currentPosition != null
                        ? Marker(
                            markerId: const MarkerId('current_location_consignee'),
                            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            infoWindow: const InfoWindow(
                              title: 'My Current Location',
                              snippet: 'Your live location',
                            ),
                          )
                        : Marker(
                            markerId: const MarkerId('current_location_consignee'),
                            position: newPosition,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                          ),
                  );
                  _consigneeMarkers = {
                    Marker(
                      markerId: const MarkerId('consignee_location'),
                      position: newPosition,
                      draggable: true,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      onDragEnd: (LatLng pos) {
                        setState(() {
                          // Preserve blue marker
                          final blueMarker = _consigneeMarkers.firstWhere(
                            (m) => m.markerId.value == 'current_location_consignee',
                            orElse: () => _currentPosition != null
                                ? Marker(
                                    markerId: const MarkerId('current_location_consignee'),
                                    position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                    infoWindow: const InfoWindow(
                                      title: 'My Current Location',
                                      snippet: 'Your live location',
                                    ),
                                  )
                                : Marker(
                                    markerId: const MarkerId('current_location_consignee'),
                                    position: pos,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                  ),
                          );
                          _consigneeMarkers = {
                            Marker(
                              markerId: const MarkerId('consignee_location'),
                              position: pos,
                              draggable: true,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            ),
                            blueMarker,
                          };
                          _consigneeLatitudeController.text = pos.latitude.toStringAsFixed(7);
                          _consigneeLongitudeController.text = pos.longitude.toStringAsFixed(7);
                        });
                        _findNearestDcForConsignee();
                      },
                    ),
                    blueMarker,
                  };
                });
                _findNearestDcForConsignee();
              },
            ),
            blueMarker,
          };
        });
        _consigneeMapController?.animateCamera(
          CameraUpdate.newLatLng(position),
        );
        _findNearestDcForConsignee();
      },
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      zoomControlsEnabled: true,
    );
  }

  Widget _buildEditMap(
    TextEditingController latController,
    TextEditingController lngController,
    MapType mapType,
    Set<Marker> markers,
    Function(GoogleMapController) onMapCreated,
    Function(MapType) onMapTypeChanged,
    Function(Set<Marker>) onMarkersChanged,
    GoogleMapController? mapController,
    Function()? onCoordinatesUpdated,
  ) {
    double? lat = double.tryParse(latController.text.trim());
    double? lng = double.tryParse(lngController.text.trim());
    
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
      // Default to Mumbai if no coordinates
      lat = 19.0760;
      lng = 72.8777;
    }
    
    final initialPosition = LatLng(lat, lng);
    
    // Always ensure blue marker is included in the markers set
    Set<Marker> markersWithBlue = Set.from(markers);
    if (_currentPosition != null) {
      // Remove old blue marker if exists
      markersWithBlue = markersWithBlue.where((m) => m.markerId.value != 'current_location_edit').toSet();
      // Add current blue marker
      markersWithBlue.add(
        Marker(
          markerId: const MarkerId('current_location_edit'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'My Current Location',
            snippet: 'Your live location',
          ),
        ),
      );
    }
    
    // Update markers if empty or if coordinates changed
    final editMarker = markers.firstWhere(
      (m) => m.markerId.value == 'edit_location',
      orElse: () => Marker(markerId: const MarkerId('edit_location'), position: initialPosition),
    );
    
    if (markers.isEmpty || 
        (markers.isNotEmpty && editMarker.position.latitude != lat && editMarker.position.longitude != lng)) {
      Set<Marker> newMarkers = {
        Marker(
          markerId: const MarkerId('edit_location'),
          position: initialPosition,
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onDragEnd: (LatLng newPosition) {
            latController.text = newPosition.latitude.toStringAsFixed(7);
            lngController.text = newPosition.longitude.toStringAsFixed(7);
            // Preserve blue marker
            final blueMarker = _currentPosition != null
                ? Marker(
                    markerId: const MarkerId('current_location_edit'),
                    position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(
                      title: 'My Current Location',
                      snippet: 'Your live location',
                    ),
                  )
                : null;
            final updatedMarkers = {
              Marker(
                markerId: const MarkerId('edit_location'),
                position: newPosition,
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                onDragEnd: (LatLng pos) {
                  latController.text = pos.latitude.toStringAsFixed(7);
                  lngController.text = pos.longitude.toStringAsFixed(7);
                  // Preserve blue marker
                  final blueMarker = _currentPosition != null
                      ? Marker(
                          markerId: const MarkerId('current_location_edit'),
                          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                          infoWindow: const InfoWindow(
                            title: 'My Current Location',
                            snippet: 'Your live location',
                          ),
                        )
                      : null;
                  final finalMarkers = blueMarker != null 
                      ? {Marker(
                          markerId: const MarkerId('edit_location'),
                          position: pos,
                          draggable: true,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        ), blueMarker}
                      : {Marker(
                          markerId: const MarkerId('edit_location'),
                          position: pos,
                          draggable: true,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        )};
                  onMarkersChanged(finalMarkers);
                  // Trigger UI update after drag
                  if (onCoordinatesUpdated != null) {
                    onCoordinatesUpdated();
                  }
                },
              ),
            };
            if (blueMarker != null) {
              updatedMarkers.add(blueMarker);
            }
            onMarkersChanged(updatedMarkers);
            // Trigger UI update after drag
            if (onCoordinatesUpdated != null) {
              onCoordinatesUpdated();
            }
          },
        ),
      };
      
      // Add blue marker for current location if available
      if (_currentPosition != null) {
        newMarkers.add(
          Marker(
            markerId: const MarkerId('current_location_edit'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(
              title: 'My Current Location',
              snippet: 'Your live location',
            ),
          ),
        );
      }
      
      markers = newMarkers;
      onMarkersChanged(markers);
    } else {
      // Use markers with blue marker included
      markers = markersWithBlue;
    }
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 14.0,
      ),
      mapType: mapType,
      markers: markersWithBlue,
      onMapCreated: onMapCreated,
      onCameraMove: (CameraPosition position) {
        // Optional: Update coordinates as camera moves
      },
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      onTap: (LatLng position) {
        latController.text = position.latitude.toStringAsFixed(7);
        lngController.text = position.longitude.toStringAsFixed(7);
        // Preserve blue marker for current location
        final blueMarker = _currentPosition != null
            ? Marker(
                markerId: const MarkerId('current_location_edit'),
                position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: const InfoWindow(
                  title: 'My Current Location',
                  snippet: 'Your live location',
                ),
              )
            : null;
        final newMarkers = {
          Marker(
            markerId: const MarkerId('edit_location'),
            position: position,
            draggable: true,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onDragEnd: (LatLng newPosition) {
              latController.text = newPosition.latitude.toStringAsFixed(7);
              lngController.text = newPosition.longitude.toStringAsFixed(7);
              // Preserve blue marker
              final blueMarker = _currentPosition != null
                  ? Marker(
                      markerId: const MarkerId('current_location_edit'),
                      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: const InfoWindow(
                        title: 'My Current Location',
                        snippet: 'Your live location',
                      ),
                    )
                  : null;
              final updatedMarkers = {
                Marker(
                  markerId: const MarkerId('edit_location'),
                  position: newPosition,
                  draggable: true,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  onDragEnd: (LatLng pos) {
                    latController.text = pos.latitude.toStringAsFixed(7);
                    lngController.text = pos.longitude.toStringAsFixed(7);
                    // Preserve blue marker
                    final blueMarker = _currentPosition != null
                        ? Marker(
                            markerId: const MarkerId('current_location_edit'),
                            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            infoWindow: const InfoWindow(
                              title: 'My Current Location',
                              snippet: 'Your live location',
                            ),
                          )
                        : null;
                    final finalMarkers = blueMarker != null
                        ? {
                            Marker(
                              markerId: const MarkerId('edit_location'),
                              position: pos,
                              draggable: true,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            ),
                            blueMarker,
                          }
                        : {
                            Marker(
                              markerId: const MarkerId('edit_location'),
                              position: pos,
                              draggable: true,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            ),
                          };
                    onMarkersChanged(finalMarkers);
                    // Trigger UI update after drag
                    if (onCoordinatesUpdated != null) {
                      onCoordinatesUpdated();
                    }
                  },
                ),
              };
              if (blueMarker != null) {
                updatedMarkers.add(blueMarker);
              }
              onMarkersChanged(updatedMarkers);
              // Trigger UI update after drag
              if (onCoordinatesUpdated != null) {
                onCoordinatesUpdated();
              }
            },
          ),
        };
        if (blueMarker != null) {
          newMarkers.add(blueMarker);
        }
        onMarkersChanged(newMarkers);
        // Trigger UI update after tap
        if (onCoordinatesUpdated != null) {
          onCoordinatesUpdated();
        }
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 16.0),
        );
      },
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      zoomControlsEnabled: true,
    );
  }

  // Helper function to get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied. Please enable them in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // Function to find and center on self location for pickup map
  Future<void> _findMyLocationForPickup() async {
    Position? position = await _getCurrentLocation();
    if (position != null && _pickupMapController != null) {
      final currentLocation = LatLng(position.latitude, position.longitude);
      _pickupMapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15.0),
      );
      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(7);
        _longitudeController.text = position.longitude.toStringAsFixed(7);
        // Preserve blue marker for current location
        final blueMarker = _pickupMarkers.firstWhere(
          (m) => m.markerId.value == 'current_location_pickup',
          orElse: () => Marker(
            markerId: const MarkerId('current_location_pickup'),
            position: _currentPosition != null 
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : currentLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(
              title: 'My Current Location',
              snippet: 'Your live location',
            ),
          ),
        );
        _pickupMarkers = {
          Marker(
            markerId: const MarkerId('pickup_location'),
            position: currentLocation,
            draggable: true,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onDragEnd: (LatLng newPosition) {
              setState(() {
                _latitudeController.text = newPosition.latitude.toStringAsFixed(7);
                _longitudeController.text = newPosition.longitude.toStringAsFixed(7);
                // Preserve blue marker
                final blueMarker = _pickupMarkers.firstWhere(
                  (m) => m.markerId.value == 'current_location_pickup',
                  orElse: () => Marker(
                    markerId: const MarkerId('current_location_pickup'),
                    position: _currentPosition != null 
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : newPosition,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(
                      title: 'My Current Location',
                      snippet: 'Your live location',
                    ),
                  ),
                );
                _pickupMarkers = {
                  Marker(
                    markerId: const MarkerId('pickup_location'),
                    position: newPosition,
                    draggable: true,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    onDragEnd: (LatLng pos) {
                      setState(() {
                        // Preserve blue marker
                        final blueMarker = _pickupMarkers.firstWhere(
                          (m) => m.markerId.value == 'current_location_pickup',
                          orElse: () => Marker(
                            markerId: const MarkerId('current_location_pickup'),
                            position: _currentPosition != null 
                                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                                : pos,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            infoWindow: const InfoWindow(
                              title: 'My Current Location',
                              snippet: 'Your live location',
                            ),
                          ),
                        );
                        _pickupMarkers = {
                          Marker(
                            markerId: const MarkerId('pickup_location'),
                            position: pos,
                            draggable: true,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          ),
                          blueMarker,
                        };
                        _latitudeController.text = pos.latitude.toStringAsFixed(7);
                        _longitudeController.text = pos.longitude.toStringAsFixed(7);
                      });
                      _findNearestDcForPickup();
                    },
                  ),
                  blueMarker,
                };
              });
              _findNearestDcForPickup();
            },
          ),
          blueMarker,
        };
      });
      _findNearestDcForPickup();
    }
  }

  // Function to find and center on self location for consignee map
  Future<void> _findMyLocationForConsignee() async {
    Position? position = await _getCurrentLocation();
    if (position != null && _consigneeMapController != null) {
      final currentLocation = LatLng(position.latitude, position.longitude);
      _consigneeMapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15.0),
      );
      setState(() {
        _consigneeLatitudeController.text = position.latitude.toStringAsFixed(7);
        _consigneeLongitudeController.text = position.longitude.toStringAsFixed(7);
        // Preserve blue marker for current location
        final blueMarker = _consigneeMarkers.firstWhere(
          (m) => m.markerId.value == 'current_location_consignee',
          orElse: () => Marker(
            markerId: const MarkerId('current_location_consignee'),
            position: _currentPosition != null 
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : currentLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(
              title: 'My Current Location',
              snippet: 'Your live location',
            ),
          ),
        );
        _consigneeMarkers = {
          Marker(
            markerId: const MarkerId('consignee_location'),
            position: currentLocation,
            draggable: true,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onDragEnd: (LatLng newPosition) {
              setState(() {
                _consigneeLatitudeController.text = newPosition.latitude.toStringAsFixed(7);
                _consigneeLongitudeController.text = newPosition.longitude.toStringAsFixed(7);
                // Preserve blue marker
                final blueMarker = _consigneeMarkers.firstWhere(
                  (m) => m.markerId.value == 'current_location_consignee',
                  orElse: () => Marker(
                    markerId: const MarkerId('current_location_consignee'),
                    position: _currentPosition != null 
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : newPosition,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(
                      title: 'My Current Location',
                      snippet: 'Your live location',
                    ),
                  ),
                );
                _consigneeMarkers = {
                  Marker(
                    markerId: const MarkerId('consignee_location'),
                    position: newPosition,
                    draggable: true,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    onDragEnd: (LatLng pos) {
                      setState(() {
                        // Preserve blue marker
                        final blueMarker = _consigneeMarkers.firstWhere(
                          (m) => m.markerId.value == 'current_location_consignee',
                          orElse: () => Marker(
                            markerId: const MarkerId('current_location_consignee'),
                            position: _currentPosition != null 
                                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                                : pos,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            infoWindow: const InfoWindow(
                              title: 'My Current Location',
                              snippet: 'Your live location',
                            ),
                          ),
                        );
                        _consigneeMarkers = {
                          Marker(
                            markerId: const MarkerId('consignee_location'),
                            position: pos,
                            draggable: true,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          ),
                          blueMarker,
                        };
                        _consigneeLatitudeController.text = pos.latitude.toStringAsFixed(7);
                        _consigneeLongitudeController.text = pos.longitude.toStringAsFixed(7);
                      });
                      _findNearestDcForConsignee();
                    },
                  ),
                  blueMarker,
                };
              });
              _findNearestDcForConsignee();
            },
          ),
          blueMarker,
        };
      });
      _findNearestDcForConsignee();
    }
  }

  Future<void> _fetchEditPlaceSuggestions(
    String query,
    Function setDialogState,
    Function(List<Map<String, dynamic>>) onSuggestionsReceived,
  ) async {
    if (query.trim().isEmpty || query.trim().length < 1) {
      onSuggestionsReceived([]);
      return;
    }

    try {
      final apiKey = 'AIzaSyB1tKNFxigZ5II4PqyHAXQSCgwOL2zsiwg';
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$apiKey&components=country:in',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['predictions'] != null) {
        final predictions = data['predictions'] as List;
        final suggestions = predictions.take(5).map((prediction) {
          return {
            'description': prediction['description'] ?? '',
            'place_id': prediction['place_id'] ?? '',
          };
        }).toList();
        
        onSuggestionsReceived(suggestions);
      } else {
        onSuggestionsReceived([]);
      }
    } catch (e) {
      print('❌ Error fetching edit suggestions: $e');
      onSuggestionsReceived([]);
    }
  }

  Future<void> _searchLocationForEditWithPlaceId(
    String query,
    TextEditingController latController,
    TextEditingController lngController,
    GoogleMapController? mapController,
    Function setDialogState,
    Function(Set<Marker>) onMarkersChanged,
  ) async {
    if (query.trim().isEmpty) return;

    try {
      // Use Google Geocoding API to search for the location
      final apiKey = 'AIzaSyB1tKNFxigZ5II4PqyHAXQSCgwOL2zsiwg';
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedQuery&key=$apiKey',
      );

      print('🔵 Searching for location in edit dialog: $query');
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final result = data['results'][0];
        final location = result['geometry']['location'];
        final lat = location['lat'] as double;
        final lng = location['lng'] as double;

        print('✅ Location found: ($lat, $lng)');

        // Place marker at the selected location and update coordinates
        final position = LatLng(lat, lng);
        onMarkersChanged({
          Marker(
            markerId: const MarkerId('edit_location'),
            position: position,
            draggable: true,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onDragEnd: (LatLng newPosition) {
              latController.text = newPosition.latitude.toStringAsFixed(7);
              lngController.text = newPosition.longitude.toStringAsFixed(7);
              onMarkersChanged({
                Marker(
                  markerId: const MarkerId('edit_location'),
                  position: newPosition,
                  draggable: true,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  onDragEnd: (LatLng pos) {
                    latController.text = pos.latitude.toStringAsFixed(7);
                    lngController.text = pos.longitude.toStringAsFixed(7);
                  },
                ),
              });
            },
          ),
        });
        
        // Update coordinate controllers
        latController.text = lat.toStringAsFixed(7);
        lngController.text = lng.toStringAsFixed(7);
        
        // Move camera to the location with appropriate zoom
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 16.0),
        );
      } else {
        print('❌ Location not found: ${data['status']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location not found: ${data['status']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error searching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Search location using Place Details API for edit dialog
  Future<void> _searchLocationForEditByPlaceId(
    String placeId,
    String address,
    TextEditingController latController,
    TextEditingController lngController,
    GoogleMapController? mapController,
    Function setDialogState,
    Function(Set<Marker>) onMarkersChanged,
  ) async {
    if (placeId.isEmpty) {
      _searchLocationForEditWithPlaceId(address, latController, lngController, mapController, setDialogState, onMarkersChanged);
      return;
    }

    try {
      final apiKey = 'AIzaSyB1tKNFxigZ5II4PqyHAXQSCgwOL2zsiwg';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey&fields=geometry,formatted_address',
      );

      print('🔵 Fetching place details for edit: $placeId');
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['result'] != null) {
        final result = data['result'];
        final location = result['geometry']['location'];
        final lat = location['lat'] as double;
        final lng = location['lng'] as double;

        print('✅ Place details found: ($lat, $lng)');

        // Place marker at the selected location and update coordinates
        final position = LatLng(lat, lng);
        onMarkersChanged({
          Marker(
            markerId: const MarkerId('edit_location'),
            position: position,
            draggable: true,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onDragEnd: (LatLng newPosition) {
              latController.text = newPosition.latitude.toStringAsFixed(7);
              lngController.text = newPosition.longitude.toStringAsFixed(7);
              onMarkersChanged({
                Marker(
                  markerId: const MarkerId('edit_location'),
                  position: newPosition,
                  draggable: true,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  onDragEnd: (LatLng pos) {
                    latController.text = pos.latitude.toStringAsFixed(7);
                    lngController.text = pos.longitude.toStringAsFixed(7);
                  },
                ),
              });
            },
          ),
        });
        
        // Update coordinate controllers
        latController.text = lat.toStringAsFixed(7);
        lngController.text = lng.toStringAsFixed(7);
        
        // Move camera to the location with appropriate zoom
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 16.0),
        );
      } else {
        print('❌ Place details not found: ${data['status']}');
        _searchLocationForEditWithPlaceId(address, latController, lngController, mapController, setDialogState, onMarkersChanged);
      }
    } catch (e) {
      print('❌ Error fetching place details: $e');
      _searchLocationForEditWithPlaceId(address, latController, lngController, mapController, setDialogState, onMarkersChanged);
    }
  }

  void _showFullScreenMap(
    BuildContext context,
    Widget mapWidget,
    GoogleMapController? mapController,
    MapType currentMapType,
    Function(MapType) onMapTypeChanged,
  ) {
    MapType fullScreenMapType = currentMapType;
    final TextEditingController fullScreenSearchController = TextEditingController();
    List<Map<String, dynamic>> fullScreenSuggestions = [];
    bool showFullScreenSuggestions = false;
    Timer? fullScreenSearchTimer;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Function to fetch suggestions for full-screen map
            Future<void> fetchFullScreenSuggestions(String query) async {
              if (query.trim().isEmpty || query.trim().length < 1) {
                setDialogState(() {
                  fullScreenSuggestions = [];
                  showFullScreenSuggestions = false;
                });
                return;
              }

              try {
                final apiKey = 'AIzaSyB1tKNFxigZ5II4PqyHAXQSCgwOL2zsiwg';
                final encodedQuery = Uri.encodeComponent(query);
                final url = Uri.parse(
                  'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=$apiKey&components=country:in',
                );

                final response = await http.get(url);
                final data = jsonDecode(response.body);

                if (data['status'] == 'OK' && data['predictions'] != null) {
                  final predictions = data['predictions'] as List;
                  final suggestions = predictions.take(5).map((prediction) {
                    return {
                      'description': prediction['description'] ?? '',
                      'place_id': prediction['place_id'] ?? '',
                    };
                  }).toList();

                  setDialogState(() {
                    fullScreenSuggestions = suggestions;
                    showFullScreenSuggestions = true;
                  });
                } else {
                  setDialogState(() {
                    fullScreenSuggestions = [];
                    showFullScreenSuggestions = false;
                  });
                }
              } catch (e) {
                print('❌ Error fetching full-screen suggestions: $e');
                setDialogState(() {
                  fullScreenSuggestions = [];
                  showFullScreenSuggestions = false;
                });
              }
            }

            // Function to search location on full-screen map
            Future<void> searchLocationFullScreen(String query) async {
              if (query.trim().isEmpty) return;

              try {
                final apiKey = 'AIzaSyB1tKNFxigZ5II4PqyHAXQSCgwOL2zsiwg';
                final encodedQuery = Uri.encodeComponent(query);
                final url = Uri.parse(
                  'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedQuery&key=$apiKey',
                );

                final response = await http.get(url);
                final data = jsonDecode(response.body);

                if (data['status'] == 'OK' && data['results'].isNotEmpty) {
                  final result = data['results'][0];
                  final location = result['geometry']['location'];
                  final lat = location['lat'] as double;
                  final lng = location['lng'] as double;

                  mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.0),
                  );

                  setDialogState(() {
                    showFullScreenSuggestions = false;
                  });
                }
              } catch (e) {
                print('❌ Error searching location in full-screen: $e');
              }
            }

            // Function to get place details from place_id
            Future<void> getPlaceDetailsAndMove(String placeId) async {
              try {
                final apiKey = 'AIzaSyB1tKNFxigZ5II4PqyHAXQSCgwOL2zsiwg';
                final url = Uri.parse(
                  'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey',
                );

                final response = await http.get(url);
                final data = jsonDecode(response.body);

                if (data['status'] == 'OK' && data['result'] != null) {
                  final result = data['result'];
                  final location = result['geometry']['location'];
                  final lat = location['lat'] as double;
                  final lng = location['lng'] as double;

                  mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.0),
                  );

                  setDialogState(() {
                    fullScreenSearchController.text = result['formatted_address'] ?? result['name'] ?? '';
                    showFullScreenSuggestions = false;
                  });
                }
              } catch (e) {
                print('❌ Error getting place details: $e');
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black,
                child: Stack(
                  children: [
                    // Full Screen Map
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: mapWidget,
                    ),
                    // Search Bar
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 10,
                      right: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: fullScreenSearchController,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search location...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.normal,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[600],
                                  size: 22,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1E3A8A),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (value) {
                                fullScreenSearchTimer?.cancel();
                                if (value.trim().length >= 1) {
                                  fullScreenSearchTimer = Timer(const Duration(milliseconds: 300), () {
                                    fetchFullScreenSuggestions(value.trim());
                                  });
                                } else {
                                  setDialogState(() {
                                    fullScreenSuggestions = [];
                                    showFullScreenSuggestions = false;
                                  });
                                }
                              },
                              onTap: () {
                                if (fullScreenSuggestions.isNotEmpty || fullScreenSearchController.text.trim().isNotEmpty) {
                                  setDialogState(() {
                                    showFullScreenSuggestions = true;
                                  });
                                }
                              },
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  searchLocationFullScreen(value.trim());
                                }
                              },
                            ),
                          ),
                          // Suggestions Dropdown
                          if (showFullScreenSuggestions && fullScreenSuggestions.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: fullScreenSuggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = fullScreenSuggestions[index];
                                  return InkWell(
                                    onTap: () {
                                      getPlaceDetailsAndMove(suggestion['place_id']);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[200]!,
                                            width: index < fullScreenSuggestions.length - 1 ? 1 : 0,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 20,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              suggestion['description'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Close Button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () {
                          fullScreenSearchController.dispose();
                          fullScreenSearchTimer?.cancel();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    // My Location Button for Full Screen Map
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 70,
                      right: 10,
                      child: GestureDetector(
                        onTap: () async {
                          Position? position = await _getCurrentLocation();
                          if (position != null && mapController != null) {
                            mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(position.latitude, position.longitude),
                                15.0,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    // Map Type Toggle Buttons
                    Positioned(
                      bottom: 20,
                      left: 10,
                      child: Row(
                        children: [
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: fullScreenMapType == MapType.normal
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: fullScreenMapType == MapType.normal
                                    ? const Color(0xFF1E3A8A)
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    fullScreenMapType = MapType.normal;
                                  });
                                  onMapTypeChanged(MapType.normal);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Center(
                                    child: Text(
                                      'Map',
                                      style: TextStyle(
                                        color: fullScreenMapType == MapType.normal
                                            ? Colors.white
                                            : const Color(0xFF1E3A8A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: fullScreenMapType == MapType.satellite
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: fullScreenMapType == MapType.satellite
                                    ? const Color(0xFF1E3A8A)
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    fullScreenMapType = MapType.satellite;
                                  });
                                  onMapTypeChanged(MapType.satellite);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Center(
                                    child: Text(
                                      'Satellite',
                                      style: TextStyle(
                                        color: fullScreenMapType == MapType.satellite
                                            ? Colors.white
                                            : const Color(0xFF1E3A8A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _searchLocationOnMap(String query, bool isPickup) async {
    if (query.trim().isEmpty) return;

    try {
      // Use Google Geocoding API to search for the location
      final apiKey = 'AIzaSyB1tKNFxigZ5II4PqyHAXQSCgwOL2zsiwg';
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedQuery&key=$apiKey',
      );

      print('🔵 Searching for location: $query');
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final result = data['results'][0];
        final location = result['geometry']['location'];
        final lat = location['lat'] as double;
        final lng = location['lng'] as double;
        final address = result['formatted_address'] as String;

        print('✅ Location found: $address ($lat, $lng)');

        // Place marker at the selected location and update coordinates
        final position = LatLng(lat, lng);
        
        if (isPickup) {
          // Update pickup markers
          setState(() {
            _pickupMarkers = {
              Marker(
                markerId: const MarkerId('pickup_location'),
                position: position,
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                onDragEnd: (LatLng newPosition) {
                  setState(() {
                    _pickupMarkers = {
                      Marker(
                        markerId: const MarkerId('pickup_location'),
                        position: newPosition,
                        draggable: true,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        onDragEnd: (LatLng pos) {
                          setState(() {
                            _pickupMarkers = {
                              Marker(
                                markerId: const MarkerId('pickup_location'),
                                position: pos,
                                draggable: true,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                            };
                            _latitudeController.text = pos.latitude.toStringAsFixed(7);
                            _longitudeController.text = pos.longitude.toStringAsFixed(7);
                          });
                          _findNearestDcForPickup();
                        },
                      ),
                    };
                    _latitudeController.text = newPosition.latitude.toStringAsFixed(7);
                    _longitudeController.text = newPosition.longitude.toStringAsFixed(7);
                  });
                  _findNearestDcForPickup();
                },
              ),
            };
            // Update coordinate controllers
            _latitudeController.text = lat.toStringAsFixed(7);
            _longitudeController.text = lng.toStringAsFixed(7);
          });
          
          // Move camera to the location with appropriate zoom
          _pickupMapController?.animateCamera(
            CameraUpdate.newLatLngZoom(position, 16.0),
          );
          _findNearestDcForPickup();
        } else {
          // Update consignee markers
          setState(() {
            _consigneeMarkers = {
              Marker(
                markerId: const MarkerId('consignee_location'),
                position: position,
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                onDragEnd: (LatLng newPosition) {
                  setState(() {
                    _consigneeMarkers = {
                      Marker(
                        markerId: const MarkerId('consignee_location'),
                        position: newPosition,
                        draggable: true,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        onDragEnd: (LatLng pos) {
                          setState(() {
                            _consigneeMarkers = {
                              Marker(
                                markerId: const MarkerId('consignee_location'),
                                position: pos,
                                draggable: true,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                            };
                            _consigneeLatitudeController.text = pos.latitude.toStringAsFixed(7);
                            _consigneeLongitudeController.text = pos.longitude.toStringAsFixed(7);
                          });
                          _findNearestDcForConsignee();
                        },
                      ),
                    };
                    _consigneeLatitudeController.text = newPosition.latitude.toStringAsFixed(7);
                    _consigneeLongitudeController.text = newPosition.longitude.toStringAsFixed(7);
                  });
                  _findNearestDcForConsignee();
                },
              ),
            };
            // Update coordinate controllers
            _consigneeLatitudeController.text = lat.toStringAsFixed(7);
            _consigneeLongitudeController.text = lng.toStringAsFixed(7);
          });
          
          // Move camera to the location with appropriate zoom
          _consigneeMapController?.animateCamera(
            CameraUpdate.newLatLngZoom(position, 16.0),
          );
          _findNearestDcForConsignee();
        }
      } else {
        print('❌ Location not found: ${data['status']}');
        _showSnackBar('Location not found. Please try a different search term.');
      }
    } catch (e) {
      print('❌ Error searching location: $e');
      _showSnackBar('Failed to search location. Please try again.');
    }
  }

  // Search location using Place Details API (more accurate when place_id is available)
  Future<void> _searchLocationByPlaceId(String placeId, String address, bool isPickup) async {
    if (placeId.isEmpty) {
      // Fallback to regular search if no place_id
      _searchLocationOnMap(address, isPickup);
      return;
    }

    try {
      final apiKey = 'AIzaSyB1tKNFxigZ5II4PqyHAXQSCgwOL2zsiwg';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey&fields=geometry,formatted_address',
      );

      print('🔵 Fetching place details for place_id: $placeId');
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['result'] != null) {
        final result = data['result'];
        final location = result['geometry']['location'];
        final lat = location['lat'] as double;
        final lng = location['lng'] as double;

        print('✅ Place details found: ($lat, $lng)');

        // Place marker at the selected location and update coordinates
        final position = LatLng(lat, lng);
        
        if (isPickup) {
          // Update pickup markers
          setState(() {
            _pickupMarkers = {
              Marker(
                markerId: const MarkerId('pickup_location'),
                position: position,
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                onDragEnd: (LatLng newPosition) {
                  setState(() {
                    _pickupMarkers = {
                      Marker(
                        markerId: const MarkerId('pickup_location'),
                        position: newPosition,
                        draggable: true,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        onDragEnd: (LatLng pos) {
                          setState(() {
                            _pickupMarkers = {
                              Marker(
                                markerId: const MarkerId('pickup_location'),
                                position: pos,
                                draggable: true,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                            };
                            _latitudeController.text = pos.latitude.toStringAsFixed(7);
                            _longitudeController.text = pos.longitude.toStringAsFixed(7);
                          });
                          _findNearestDcForPickup();
                        },
                      ),
                    };
                    _latitudeController.text = newPosition.latitude.toStringAsFixed(7);
                    _longitudeController.text = newPosition.longitude.toStringAsFixed(7);
                  });
                  _findNearestDcForPickup();
                },
              ),
            };
            // Update coordinate controllers
            _latitudeController.text = lat.toStringAsFixed(7);
            _longitudeController.text = lng.toStringAsFixed(7);
          });
          
          // Move camera to the location with appropriate zoom
          _pickupMapController?.animateCamera(
            CameraUpdate.newLatLngZoom(position, 16.0),
          );
          _findNearestDcForPickup();
        } else {
          // Update consignee markers
          setState(() {
            _consigneeMarkers = {
              Marker(
                markerId: const MarkerId('consignee_location'),
                position: position,
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                onDragEnd: (LatLng newPosition) {
                  setState(() {
                    _consigneeMarkers = {
                      Marker(
                        markerId: const MarkerId('consignee_location'),
                        position: newPosition,
                        draggable: true,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        onDragEnd: (LatLng pos) {
                          setState(() {
                            _consigneeMarkers = {
                              Marker(
                                markerId: const MarkerId('consignee_location'),
                                position: pos,
                                draggable: true,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                            };
                            _consigneeLatitudeController.text = pos.latitude.toStringAsFixed(7);
                            _consigneeLongitudeController.text = pos.longitude.toStringAsFixed(7);
                          });
                          _findNearestDcForConsignee();
                        },
                      ),
                    };
                    _consigneeLatitudeController.text = newPosition.latitude.toStringAsFixed(7);
                    _consigneeLongitudeController.text = newPosition.longitude.toStringAsFixed(7);
                  });
                  _findNearestDcForConsignee();
                },
              ),
            };
            // Update coordinate controllers
            _consigneeLatitudeController.text = lat.toStringAsFixed(7);
            _consigneeLongitudeController.text = lng.toStringAsFixed(7);
          });
          
          // Move camera to the location with appropriate zoom
          _consigneeMapController?.animateCamera(
            CameraUpdate.newLatLngZoom(position, 16.0),
          );
          _findNearestDcForConsignee();
        }
      } else {
        print('❌ Place details not found: ${data['status']}');
        // Fallback to regular search
        _searchLocationOnMap(address, isPickup);
      }
    } catch (e) {
      print('❌ Error fetching place details: $e');
      // Fallback to regular search
      _searchLocationOnMap(address, isPickup);
    }
  }
}

