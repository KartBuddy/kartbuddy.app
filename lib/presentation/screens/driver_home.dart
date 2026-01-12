import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import '../../auth/login.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../models/trip_model.dart';
import '../../models/dc_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/auth_models.dart';
import 'driver_profile.dart';
import 'driver_settings.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool _isActive = true;
  String _selectedMenuItem = 'Live Trips';
  
  // Map controller
  GoogleMapController? _mapController;
  GoogleMapController? _fullScreenMapController; // Full-screen map controller reference
  
  // Map markers and polylines
  Set<Marker> _mapMarkers = {};
  Set<Polyline> _mapPolylines = {};
  
  // Current location tracking
  Position? _currentPosition;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isRealTimeTrackingEnabled = false; // Real-time tracking toggle
  
  // Trip data
  CurrentTrip? _currentTrip;
  TripDetails? _tripDetails;
  bool _isLoadingTrip = false;
  Set<String> _expandedOrders = {}; // Track which orders are expanded
  Map<String, List<File>> _orderPopImages = {}; // Track POP images for each order
  Map<String, bool> _orderPopUploading = {}; // Track upload state
  Map<String, List<File>> _orderPodImages = {}; // Track POD images for each order
  Map<String, bool> _orderPodUploading = {}; // Track POD upload state
  Map<String, List<File>> _orderPodChallanImages = {}; // Track POD Challan images
  Map<String, bool> _orderPodChallanUploading = {}; // Track POD Challan upload state
  final AuthService _authService = AuthService();
  
  // Trip history data
  List<TripHistory> _tripHistory = [];
  bool _isLoadingHistory = false;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  // DC data
  List<DcManager> _allDcs = [];
  List<DcManager> _assignedDcs = [];
  DcManager? _selectedDc;
  bool _isLoadingDcs = false;
  DriverProfileDetails? _driverProfile;
  
  // Service Type data
  String? _selectedServiceType;
  List<Map<String, String>> _availableServiceTypes = [];
  
  // Vehicle data
  List<Vehicle> _availableVehicles = [];
  Vehicle? _selectedVehicle;
  bool _isLoadingVehicles = false;
  
  // Start Trip data
  final ImagePicker _imagePicker = ImagePicker();
  File? _startKmPic;
  final TextEditingController _plannedKmController = TextEditingController();
  final TextEditingController _startKmController = TextEditingController();
  
  // Periodic refresh timer
  Timer? _refreshTimer;
  bool _isStartingTrip = false;
  
  // Hub location (Vasai) - approximate coordinates
  final LatLng _hubLocation = const LatLng(19.4700, 72.8000);
  
  // Delivery location (Adheri/Andheri) - approximate coordinates
  final LatLng _deliveryLocation = const LatLng(19.1136, 72.8697);
  
  // Route points (simplified route from Vasai to Andheri)
  final List<LatLng> _routePoints = [
    const LatLng(19.4700, 72.8000), // Vasai (Hub)
    const LatLng(19.4000, 72.8200),
    const LatLng(19.3000, 72.8400),
    const LatLng(19.2000, 72.8500),
    const LatLng(19.1136, 72.8697), // Andheri (Delivery)
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
    _startLocationTracking();
    _loadCurrentTrip();
    _loadDriverProfileAndDcs();
    _startPeriodicRefresh();
  }
  
  void _startPeriodicRefresh() {
    // Refresh trip data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isActive && mounted) {
        print('🔄 Periodic refresh triggered');
        _loadCurrentTrip();
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    _fullScreenMapController?.dispose();
    _plannedKmController.dispose();
    _startKmController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  // @override
  // void dispose() {
  //   _positionStreamSubscription?.cancel();
  //   _mapController?.dispose();
  //   _fullScreenMapController?.dispose();
  //   _fromDateController.dispose();
  //   _toDateController.dispose();
  //   _searchController.dispose();
  //   _plannedKmController.dispose();
  //   _startKmController.dispose();
  //   super.dispose();
  // }
  
  // Helper method to get initials from name
  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'D';
    
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return 'D';
    
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
  
  Future<void> _loadDriverProfileAndDcs() async {
    setState(() {
      _isLoadingDcs = true;
    });
    
    try {
      final token = await UserService.getToken();
      if (token != null) {
        // Load driver profile to get assigned_dc_id
        final profileResponse = await _authService.getDriverProfile(token);
        if (profileResponse.success) {
          setState(() {
            _driverProfile = profileResponse.data;
          });
          
          // Load all DCs
          final dcResponse = await _authService.getDcManagers(token);
          if (dcResponse.success) {
            setState(() {
              _allDcs = dcResponse.data;
              // Filter DCs based on assigned_dc_id
              if (_driverProfile?.assignedDcId != null && _driverProfile!.assignedDcId!.isNotEmpty) {
                _assignedDcs = _allDcs.where((dc) {
                  return _driverProfile!.assignedDcId!.contains(dc.id);
                }).toList();
                
                // Set the first assigned DC as selected if available
                if (_assignedDcs.isNotEmpty) {
                  _selectedDc = _assignedDcs.first;
                }
              } else {
                _assignedDcs = [];
              }
              
              // Build available service types based on driver access
              _buildAvailableServiceTypes();
              
              // Set default service type if available
              if (_availableServiceTypes.isNotEmpty) {
                _selectedServiceType = _availableServiceTypes.first['value'];
                // Load vehicles when DC and service type are set
                _loadAvailableVehicles();
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error loading driver profile and DCs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading DCs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingDcs = false;
      });
    }
  }
  
  void _buildAvailableServiceTypes() {
    _availableServiceTypes = [];
    
    if (_driverProfile == null) return;
    
    // Map driver access fields to service types
    if (_driverProfile!.intraSddAccess?.toUpperCase() == 'YES') {
      _availableServiceTypes.add({
        'label': 'INTRA SDD',
        'value': 'intra_sdd_access',
      });
    }
    if (_driverProfile!.intraNddAccess?.toUpperCase() == 'YES') {
      _availableServiceTypes.add({
        'label': 'INTRA NDD',
        'value': 'intra_ndd_access',
      });
    }
    if (_driverProfile!.intraFtlAccess?.toUpperCase() == 'YES') {
      _availableServiceTypes.add({
        'label': 'INTRA FTL',
        'value': 'intra_ftl_access',
      });
    }
    if (_driverProfile!.intraRentalAccess?.toUpperCase() == 'YES') {
      _availableServiceTypes.add({
        'label': 'INTRA RENTAL',
        'value': 'intra_rental_access',
      });
    }
    if (_driverProfile!.interPtlAccess?.toUpperCase() == 'YES') {
      _availableServiceTypes.add({
        'label': 'INTER PTL',
        'value': 'inter_ptl_access',
      });
    }
    if (_driverProfile!.interFtlAccess?.toUpperCase() == 'YES') {
      _availableServiceTypes.add({
        'label': 'INTER FTL',
        'value': 'inter_ftl_access',
      });
    }
    if (_driverProfile!.interBiddingAccess?.toUpperCase() == 'YES') {
      _availableServiceTypes.add({
        'label': 'INTER BIDDING',
        'value': 'inter_bidding_access',
      });
    }
  }
  
  Future<void> _loadAvailableVehicles() async {
    if (_selectedDc == null || _selectedServiceType == null || _driverProfile?.vendorId == null) {
      setState(() {
        _availableVehicles = [];
        _selectedVehicle = null;
      });
      return;
    }
    
    setState(() {
      _isLoadingVehicles = true;
    });
    
    try {
      final token = await UserService.getToken();
      if (token != null) {
        final response = await _authService.getAvailableVehicles(
          token,
          _driverProfile!.vendorId!,
          _selectedDc!.id,
          _selectedServiceType!,
        );
        
        if (response.success) {
          setState(() {
            _availableVehicles = response.data;
            // Auto-select first vehicle if available
            if (_availableVehicles.isNotEmpty) {
              _selectedVehicle = _availableVehicles.first;
            } else {
              _selectedVehicle = null;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading available vehicles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vehicles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _availableVehicles = [];
        _selectedVehicle = null;
      });
    } finally {
      setState(() {
        _isLoadingVehicles = false;
      });
    }
  }
  
  Future<void> _loadCurrentTrip() async {
    if (!_isActive) return;
    
    setState(() {
      _isLoadingTrip = true;
    });
    
    try {
      final token = await UserService.getToken();
      if (token != null) {
        // First, get the current assigned trip
        final response = await _authService.getCurrentTrip(token);
        if (response.success && response.data != null) {
          // Check if trip is closed or completed
          if (response.data!.tripStatus.toLowerCase() == 'trip closed' || 
              response.data!.tripStatus.toLowerCase() == 'completed') {
            print('⚠️ Trip is ${response.data!.tripStatus} - clearing current trip');
            setState(() {
              _currentTrip = null;
              _tripDetails = null;
            });
            return;
          }
          
          setState(() {
            _currentTrip = response.data;
            _isActive = true; // Trip exists, so driver is active
          });
          
          print('✅ ===== CURRENT TRIP LOADED =====');
          print('   Trip ID: ${_currentTrip?.tripId}');
          print('   Trip Name: ${_currentTrip?.tripName}');
          print('   Trip Status: "${_currentTrip?.tripStatus}"');
          print('   Driver Response: "${_currentTrip?.driverResponse}"');
          print('   Actual Start Time: ${_currentTrip?.actualStartTime}');
          print('   Response Time: ${_currentTrip?.responseTime}');
          print('===================================');
          
          // Then, fetch detailed trip information including orders
          try {
            final detailsResponse = await _authService.getTripDetails(
              token,
              response.data!.tripId, // Use trip_id (e.g., KBT13)
            );
            
            if (detailsResponse.success && detailsResponse.data != null) {
              // Double-check trip status in details
              if (detailsResponse.data!.tripStatus.toLowerCase() == 'trip closed' || 
                  detailsResponse.data!.tripStatus.toLowerCase() == 'completed') {
                print('⚠️ Trip details show ${detailsResponse.data!.tripStatus} - clearing current trip');
                setState(() {
                  _currentTrip = null;
                  _tripDetails = null;
                });
                return;
              }
              
              setState(() {
                _tripDetails = detailsResponse.data;
              });
              print('✅ Trip details loaded:');
              print('   - Orders: ${_tripDetails?.orders.length}');
              print('   - Driver Response: ${_tripDetails?.driverResponse}');
              print('   - Actual Start Time: ${_tripDetails?.actualStartTime}');
              print('   - Trip Status: ${_tripDetails?.tripStatus}');
            }
          } catch (e) {
            print('⚠️ Error loading trip details: $e');
            // Continue even if details fail - we have basic trip info
          }
        } else {
          print('ℹ️ No current trip found or response not successful');
          setState(() {
            _currentTrip = null;
            _tripDetails = null;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading current trip: $e');
      setState(() {
        _currentTrip = null;
        _tripDetails = null;
      });
    } finally {
      setState(() {
        _isLoadingTrip = false;
      });
    }
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
      _updateCurrentLocationMarker();

      // Listen to position updates
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        _currentPosition = position;
        _updateCurrentLocationMarker();
        // Auto-follow location if real-time tracking is enabled
        if (_isRealTimeTrackingEnabled) {
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(position.latitude, position.longitude),
                15.0,
              ),
            );
          }
          // Also update full-screen map if it's open
          if (_fullScreenMapController != null) {
            _fullScreenMapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(position.latitude, position.longitude),
                15.0,
              ),
            );
          }
        }
      });
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }
  
  void _updateCurrentLocationMarker() {
    if (_currentPosition != null && mounted) {
      setState(() {
        // Add blue marker for current location
        final currentLocationMarker = Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'My Current Location',
            snippet: 'Your live location',
          ),
        );
        
        // Keep existing markers and add/update current location marker
        _mapMarkers = {
          ..._mapMarkers.where((m) => m.markerId.value != 'current_location'),
          currentLocationMarker,
        };
      });
    }
  }
  
  Future<void> _initializeMap() async {
    // Create custom markers with text
    final hubIcon = await _createCustomMarker('H', Colors.blue);
    final deliveryIcon = await _createCustomMarker('D1', Colors.green);
    
    // Create markers
    _mapMarkers = {
      Marker(
        markerId: const MarkerId('hub'),
        position: _hubLocation,
        icon: hubIcon,
        infoWindow: const InfoWindow(
          title: 'Hub',
          snippet: 'Vasai DC',
        ),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: _deliveryLocation,
        icon: deliveryIcon,
        infoWindow: const InfoWindow(
          title: 'Delivery Point',
          snippet: 'D1',
        ),
      ),
    };
    
    // Create route polyline
    _mapPolylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: Colors.red,
        width: 4,
      ),
    };
    
    if (mounted) {
      setState(() {});
    }
  }
  
  Future<BitmapDescriptor> _createCustomMarker(String label, Color color) async {
    // Create a simple custom marker with text
    // For a more sophisticated marker, you'd use canvas to draw
    // For now, we'll use the default marker with custom hue
    if (color == Colors.blue) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }
  
  void _fitBounds() {
    if (_mapController == null) return;
    
    double minLat = _hubLocation.latitude < _deliveryLocation.latitude
        ? _hubLocation.latitude
        : _deliveryLocation.latitude;
    double maxLat = _hubLocation.latitude > _deliveryLocation.latitude
        ? _hubLocation.latitude
        : _deliveryLocation.latitude;
    double minLng = _hubLocation.longitude < _deliveryLocation.longitude
        ? _hubLocation.longitude
        : _deliveryLocation.longitude;
    double maxLng = _hubLocation.longitude > _deliveryLocation.longitude
        ? _hubLocation.longitude
        : _deliveryLocation.longitude;
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.05, minLng - 0.05),
          northeast: LatLng(maxLat + 0.05, maxLng + 0.05),
        ),
        50.0,
      ),
    );
  }

  Future<void> _findMyLocation() async {
    try {
      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable them in settings.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Move camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15.0,
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location found: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  

  
  Future<void> _loadTripHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });
    
    try {
      final token = await UserService.getToken();
      if (token != null) {
        final response = await _authService.getTripHistory(token);
        if (response.success) {
          setState(() {
            _tripHistory = response.data;
          });
        }
      }
    } catch (e) {
      print('Error loading trip history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trip history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      _loadTripHistory(); // Reload with filters
    }
  }
  
  List<TripHistory> get _filteredTripHistory {
    List<TripHistory> filtered = _tripHistory;
    
    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((trip) {
        return trip.tripId.toLowerCase().contains(searchTerm) ||
               trip.tripName.toLowerCase().contains(searchTerm);
      }).toList();
    }
    
    // Filter by date range
    if (_fromDateController.text.isNotEmpty) {
      try {
        final fromDateParts = _fromDateController.text.split('-');
        final fromDate = DateTime(
          int.parse(fromDateParts[2]),
          int.parse(fromDateParts[1]),
          int.parse(fromDateParts[0]),
        );
        filtered = filtered.where((trip) {
          final tripDate = DateTime.parse(trip.scheduledDate);
          return tripDate.isAfter(fromDate.subtract(const Duration(days: 1))) ||
                 tripDate.isAtSameMomentAs(fromDate);
        }).toList();
      } catch (e) {
        // Invalid date format, ignore filter
      }
    }
    
    if (_toDateController.text.isNotEmpty) {
      try {
        final toDateParts = _toDateController.text.split('-');
        final toDate = DateTime(
          int.parse(toDateParts[2]),
          int.parse(toDateParts[1]),
          int.parse(toDateParts[0]),
        );
        filtered = filtered.where((trip) {
          final tripDate = DateTime.parse(trip.scheduledDate);
          return tripDate.isBefore(toDate.add(const Duration(days: 1))) ||
                 tripDate.isAtSameMomentAs(toDate);
        }).toList();
      } catch (e) {
        // Invalid date format, ignore filter
      }
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: Color(0xFF1E3A8A),
              size: 28,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Container(
          width: 40,
          height: 40,
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
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1E3A8A),
                  size: 28,
                ),
                onPressed: () {
                  // Handle notification
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Driver Profile
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(_driverProfile?.fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverProfile?.fullName ?? 'Driver',
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Driver',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF1E3A8A),
                  ),
                ],
              ),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_driverProfile?.fullName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _driverProfile?.fullName ?? 'Driver',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _driverProfile?.email ?? _driverProfile?.mobileNumber ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20, color: Colors.black87),
                      SizedBox(width: 12),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, size: 20, color: Colors.red),
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
                if (value == 'signout') {
                  _handleSignOut();
                } else if (value == 'profile') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DriverProfile()),
                  );
                  // Refresh profile data when returning from profile page
                  _loadDriverProfileAndDcs();
                } else if (value == 'settings') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DriverSettings()),
                  );
                  // Refresh profile data when returning from settings page
                  _loadDriverProfileAndDcs();
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Content Area
              _selectedMenuItem == 'Live Trips'
                  ? _buildLiveTripsView()
                  : _selectedMenuItem == 'History'
                      ? _buildHistoryView()
                      : _buildEarningsView(),
              // Map and Summary (below main content)
              if (_selectedMenuItem == 'Live Trips' && _isActive)
                _buildRightSidebar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lock,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            const Text(
              'Hub',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingDcs)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (!_isActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: DropdownButton<DcManager>(
              value: _selectedDc,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
                size: 20,
              ),
              hint: Text(
                'Select Hub',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              items: _assignedDcs.map((dc) {
                return DropdownMenuItem<DcManager>(
                  value: dc,
                  child: Text(
                    dc.branchName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _assignedDcs.isNotEmpty
                  ? (DcManager? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedDc = newValue;
                        });
                        // Load vehicles when DC changes
                        _loadAvailableVehicles();
                      }
                    }
                  : null,
              selectedItemBuilder: (BuildContext context) {
                return _assignedDcs.map<Widget>((dc) {
                  return Text(
                    dc.branchName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList();
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDc?.branchName ?? 'No Hub Assigned',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildServiceTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lock,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            const Text(
              'Service Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_isActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedServiceType,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
                size: 20,
              ),
              hint: const Text(
                'Select Service Type',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              items: _availableServiceTypes.map((serviceType) {
                return DropdownMenuItem<String>(
                  value: serviceType['value'],
                  child: Text(
                    serviceType['label'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _availableServiceTypes.isNotEmpty
                  ? (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedServiceType = newValue;
                        });
                        // Load vehicles when service type changes
                        _loadAvailableVehicles();
                      }
                    }
                  : null,
              selectedItemBuilder: (BuildContext context) {
                return _availableServiceTypes.map<Widget>((serviceType) {
                  return Text(
                    serviceType['label'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList();
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedServiceType != null
                        ? _availableServiceTypes.firstWhere(
                            (st) => st['value'] == _selectedServiceType,
                            orElse: () => {'label': 'No Service Type', 'value': ''},
                          )['label'] ?? 'No Service Type'
                        : 'No Service Type',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildVehicleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lock,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              'Vehicle (${_availableVehicles.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingVehicles)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (!_isActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: DropdownButton<Vehicle>(
              value: _selectedVehicle,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
                size: 20,
              ),
              hint: const Text(
                'Select Vehicle',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              items: _availableVehicles.map((vehicle) {
                return DropdownMenuItem<Vehicle>(
                  value: vehicle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vehicle.vehicleRegistrationNo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Type: ${vehicle.vehicleType ?? 'N/A'} | Model: ${vehicle.vehicleModelName ?? 'N/A'} ${vehicle.vehicleSubModelName ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _availableVehicles.isNotEmpty
                  ? (Vehicle? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedVehicle = newValue;
                        });
                      }
                    }
                  : null,
              selectedItemBuilder: (BuildContext context) {
                return _availableVehicles.map<Widget>((vehicle) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vehicle.vehicleRegistrationNo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_selectedVehicle?.id == vehicle.id) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${vehicle.vehicleType ?? 'N/A'} | Model: ${vehicle.vehicleModelName ?? 'N/A'} ${vehicle.vehicleSubModelName ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  );
                }).toList();
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVehicle?.vehicleRegistrationNo ?? 'No Vehicle Selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_selectedVehicle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${_selectedVehicle!.vehicleType ?? 'N/A'} | Model: ${_selectedVehicle!.vehicleModelName ?? 'N/A'} ${_selectedVehicle!.vehicleSubModelName ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
      ],
    );
  }
  

  Widget _buildLockedField({
    required String label,
    required String value,
    required bool showDropdown,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lock,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showDropdown)
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                  size: 20,
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showGoInactiveDialog() {
    if (_driverProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver profile not loaded'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Go Inactive'),
          content: const Text(
            'Are you sure you want to go inactive? This will stop receiving trips and release your vehicle.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleGoInactive();
              },
              child: const Text(
                'Go Inactive',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _handleGoInactive() async {
    if (_driverProfile == null) {
      return;
    }
    
    setState(() {
      _isLoadingVehicles = true; // Reuse loading state for deactivation
    });
    
    try {
      final token = await UserService.getToken();
      if (token != null) {
        final response = await _authService.releaseVehicle(
          token,
          _driverProfile!.driverId,
        );
        
        final message = response['message'] ?? '';
        final isSuccess = response['success'] == true;
        
        // Check if driver already has no active session (already inactive)
        final isAlreadyInactive = message.toLowerCase().contains('no active session') ||
                                  message.toLowerCase().contains('already inactive');
        
        if (isSuccess || isAlreadyInactive) {
          setState(() {
            _isActive = false;
            _currentTrip = null; // Clear current trip when going inactive
            _tripDetails = null; // Clear trip details
            _selectedVehicle = null; // Clear selected vehicle
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAlreadyInactive 
                    ? 'You are already inactive' 
                    : (response['message'] ?? 'You are now inactive'),
              ),
              backgroundColor: isAlreadyInactive ? Colors.blue : Colors.green,
            ),
          );
        } else {
          // Only show error if it's not about already being inactive
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.isNotEmpty ? message : 'Failed to go inactive'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error going inactive: $e');
      if (mounted) {
        final errorMessage = e.toString();
        // Check if error is about no active session
        if (errorMessage.toLowerCase().contains('no active session')) {
          setState(() {
            _isActive = false;
            _currentTrip = null;
            _tripDetails = null;
            _selectedVehicle = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already inactive'),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isLoadingVehicles = false;
      });
    }
  }

  void _showGoActiveDialog() {
    // Validate required selections
    if (_selectedDc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Hub'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Service Type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Vehicle'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_driverProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver profile not loaded'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Go Active'),
          content: const Text(
            'Are you sure you want to go active? This will start receiving trips and claim your vehicle.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleGoActive();
              },
              child: const Text(
                'Go Active',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _handleGoActive() async {
    if (_selectedDc == null || _selectedVehicle == null || _driverProfile == null) {
      return;
    }
    
    setState(() {
      _isLoadingVehicles = true; // Reuse loading state for activation
    });
    
    try {
      final token = await UserService.getToken();
      if (token != null) {
        final response = await _authService.claimVehicle(
          token,
          _driverProfile!.driverId,
          _selectedVehicle!.vehicleId,
          _selectedDc!.id,
        );
        
        final message = response['message'] ?? '';
        final isSuccess = response['success'] == true;
        
        // Check if driver already has an active session (already active)
        final isAlreadyActive = message.toLowerCase().contains('already active') ||
                                message.toLowerCase().contains('active session');
        
        if (isSuccess || isAlreadyActive) {
          setState(() {
            _isActive = true;
          });
          
          // Reload current trip to check if any trips are assigned
          _loadCurrentTrip();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAlreadyActive 
                    ? 'You are already active' 
                    : (response['message'] ?? 'You are now active'),
              ),
              backgroundColor: isAlreadyActive ? Colors.blue : Colors.green,
            ),
          );
        } else {
          // Show error message for other failures
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.isNotEmpty ? message : 'Failed to go active'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error going active: $e');
      if (mounted) {
        final errorMessage = e.toString();
        // Check if error is about already being active
        if (errorMessage.toLowerCase().contains('already active') ||
            errorMessage.toLowerCase().contains('active session')) {
          setState(() {
            _isActive = true;
          });
          _loadCurrentTrip();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already active'),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isLoadingVehicles = false;
      });
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 320,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Driver Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(_driverProfile?.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverProfile?.fullName ?? 'Driver',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _driverProfile?.driverId ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Status Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isActive ? Colors.green[700] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (_isActive) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active Session',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Text(
                      'Configuration locked',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Hub Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildHubDropdown(),
          ),
          const Divider(height: 1),
          
          // Service Type Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildServiceTypeDropdown(),
          ),
          const Divider(height: 1),
          
          // Vehicle Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildVehicleDropdown(),
          ),
          const Divider(height: 1),
          
          // Go Inactive/Active Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_isActive) {
                        _showGoInactiveDialog();
                      } else {
                        _showGoActiveDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isActive ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isActive ? 'Go Inactive' : 'Go Active',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isActive
                      ? 'Click to stop receiving trips and release vehicle'
                      : 'Click to start receiving trips and claim vehicle',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Divider(height: 1),
          
          // Navigation Links
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildSidebarNavItem(
                  icon: Icons.local_shipping,
                  label: 'Live Trips',
                  isSelected: _selectedMenuItem == 'Live Trips',
                  onTap: () {
                    setState(() {
                      _selectedMenuItem = 'Live Trips';
                    });
                    Navigator.of(context).pop();
                    _loadCurrentTrip();
                  },
                ),
                _buildSidebarNavItem(
                  icon: Icons.history,
                  label: 'History',
                  isSelected: _selectedMenuItem == 'History',
                  onTap: () {
                    setState(() {
                      _selectedMenuItem = 'History';
                    });
                    Navigator.of(context).pop();
                    _loadTripHistory();
                  },
                ),
                _buildSidebarNavItem(
                  icon: Icons.attach_money,
                  label: 'Earnings',
                  isSelected: _selectedMenuItem == 'Earnings',
                  onTap: () {
                    setState(() {
                      _selectedMenuItem = 'Earnings';
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[700],
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildLiveTripsView() {
    if (_isLoadingTrip) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (!_isActive || _currentTrip == null) {
      return const Center(
        child: Text(
          'No active trips',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Format scheduled date
    String formattedDate = _formatDate(_currentTrip!.scheduledDate);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title with Refresh Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Trips',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              IconButton(
                onPressed: _isLoadingTrip ? null : () {
                  print('🔄 Manual refresh triggered');
                  _loadCurrentTrip();
                },
                icon: _isLoadingTrip 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh Trip',
                color: const Color(0xFF1E3A8A),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Trip Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip Header with Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentTrip!.tripName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trip ID: ${_currentTrip!.tripId}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Date: $formattedDate',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Show appropriate buttons based on trip status
                    // Use _tripDetails if available for most up-to-date status
                    Builder(
                      builder: (context) {
                        final driverResponse = (_tripDetails?.driverResponse ?? _currentTrip!.driverResponse).toLowerCase();
                        final actualStartTime = _tripDetails?.actualStartTime ?? _currentTrip!.actualStartTime;
                        final tripStatus = _tripDetails?.tripStatus ?? _currentTrip!.tripStatus;
                        
                        print('🎯 ===== BUTTON LOGIC DEBUG =====');
                        print('   Current Trip ID: ${_currentTrip!.tripId}');
                        print('   Trip Status: "$tripStatus"');
                        print('   Driver Response (raw): "${_tripDetails?.driverResponse ?? _currentTrip!.driverResponse}"');
                        print('   Driver Response (lowercase): "$driverResponse"');
                        print('   Actual Start Time: "$actualStartTime"');
                        print('   ');
                        print('   BUTTON CHECKS:');
                        print('   ✓ Is "pending"? ${driverResponse == 'pending'}');
                        print('   ✓ Is "accepted"? ${driverResponse == 'accepted'}');
                        print('   ✓ Trip status is "assigned"? ${tripStatus.toLowerCase() == 'assigned'}');
                        print('   ✓ Start time is null? ${actualStartTime == null}');
                        print('   ');
                        print('   WHICH BUTTON SHOWS:');
                        if (driverResponse == 'pending') {
                          print('   → Accept/Reject buttons');
                        } else if (driverResponse == 'accepted' && tripStatus.toLowerCase() == 'assigned') {
                          print('   → Start Trip button (MATCHED!)');
                        } else {
                          print('   → End Trip button (FALLBACK)');
                          print('   ⚠️ Why End Trip? driver_response="$driverResponse", trip_status="$tripStatus"');
                        }
                        print('🎯 ===============================');
                        
                        return const SizedBox.shrink();
                      },
                    ),
                    if ((_tripDetails?.driverResponse ?? _currentTrip!.driverResponse).toLowerCase() == 'pending')
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 140,
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingTrip ? null : () {
                                _handleAcceptTrip();
                              },
                              icon: const Icon(
                                Icons.check_circle,
                                size: 18,
                              ),
                              label: const Text(
                                'Accept Trip',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 140,
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingTrip ? null : () {
                                _handleRejectTrip();
                              },
                              icon: const Icon(
                                Icons.cancel,
                                size: 18,
                              ),
                              label: const Text(
                                'Reject Trip',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if ((_tripDetails?.driverResponse ?? _currentTrip!.driverResponse).toLowerCase() == 'accepted' && 
                             (_tripDetails?.tripStatus ?? _currentTrip!.tripStatus).toLowerCase() == 'assigned')
                      SizedBox(
                        width: 140,
                        child: ElevatedButton.icon(
                          onPressed: _isStartingTrip ? null : () {
                            _showStartTripDialog();
                          },
                          icon: const Icon(
                            Icons.play_arrow,
                            size: 18,
                          ),
                          label: const Text(
                            'Start Trip',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: 140,
                        child: ElevatedButton.icon(
                          onPressed: _areAllOrdersComplete() ? () {
                            _showEndTripDialog();
                          } : null,
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                          ),
                          label: const Text(
                            'End Trip',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[500],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      
                  ],
                ),
                const SizedBox(height: 16),

                // Trip Status Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green[400]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trip Status: ${_currentTrip!.tripStatus}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Trip Orders Section
                Text(
                  'Trip Orders (${_currentTrip!.totalOrders})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),

                // Hub Information
                if (_currentTrip!.hubAddress != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hub: ${_currentTrip!.hubName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        if (_currentTrip!.hubAddress != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _currentTrip!.hubAddress!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Notes
                if (_currentTrip!.notes != null && _currentTrip!.notes!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Notes: ${_currentTrip!.notes}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Individual Order Cards (Expandable)
                if (_tripDetails != null && _tripDetails!.orders.isNotEmpty) ...[
                  ..._tripDetails!.orders.map((order) => _buildExpandableOrderCard(order)).toList(),
                ] else if (_isLoadingTrip) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildRightSidebar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Live Map Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Map',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Text(
                  'Total Road Distance: 46.8 km',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Map Container with Google Maps
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          (_hubLocation.latitude + _deliveryLocation.latitude) / 2,
                          (_hubLocation.longitude + _deliveryLocation.longitude) / 2,
                        ),
                        zoom: 11.0,
                      ),
                      markers: _mapMarkers,
                      polylines: _mapPolylines,
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: true,
                      compassEnabled: true,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        // Fit bounds to show both markers
                        _fitBounds();
                      },
                    ),
                    // Map controls
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen),
                          onPressed: () {
                            _showFullScreenMap();
                          },
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    // My Location Button
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _findMyLocation,
                          color: Colors.blue[700],
                          tooltip: 'Find my location',
                        ),
                      ),
                    ),
                    // Real-time Tracking Toggle Button
                    Positioned(
                      top: 60,
                      left: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isRealTimeTrackingEnabled ? Colors.green : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isRealTimeTrackingEnabled ? Icons.gps_fixed : Icons.gps_not_fixed,
                            color: _isRealTimeTrackingEnabled ? Colors.white : Colors.grey[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _isRealTimeTrackingEnabled = !_isRealTimeTrackingEnabled;
                              // If enabling, immediately center on current location
                              if (_isRealTimeTrackingEnabled && _currentPosition != null && _mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    15.0,
                                  ),
                                );
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isRealTimeTrackingEnabled 
                                    ? 'Real-time tracking enabled - Map will follow your location'
                                    : 'Real-time tracking disabled',
                                ),
                                backgroundColor: _isRealTimeTrackingEnabled ? Colors.green : Colors.grey,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: _isRealTimeTrackingEnabled ? 'Disable real-time tracking' : 'Enable real-time tracking',
                        ),
                      ),
                    ),
                    // Real-time Tracking Indicator
                    if (_isRealTimeTrackingEnabled)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Live Tracking',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                _mapController?.animateCamera(
                                  CameraUpdate.zoomIn(),
                                );
                              },
                              color: Colors.grey[700],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                _mapController?.animateCamera(
                                  CameraUpdate.zoomOut(),
                                );
                              },
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Trip Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Total Orders', '1'),
                      _buildSummaryItem('Picked', '0'),
                      _buildSummaryItem('Delivered', '0'),
                      _buildSummaryItem('COD Collected', '0'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExpandableOrderCard(Order order) {
    final isExpanded = _expandedOrders.contains(order.orderId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header (Always visible) - Clickable
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedOrders.remove(order.orderId);
                } else {
                  _expandedOrders.add(order.orderId);
                }
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.orderId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (order.express)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flash_on, size: 14, color: Colors.orange[800]),
                            const SizedBox(width: 4),
                            Text(
                              'Express',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getOrderStatusColor(order.orderStatusInTrip).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getOrderStatusColor(order.orderStatusInTrip),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _formatOrderStatus(order.orderStatusInTrip, order.orderStatus),
                        style: TextStyle(
                          color: _getOrderStatusColor(order.orderStatusInTrip),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF1E3A8A),
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expanded Details (using the beautiful card design)
          if (isExpanded) ...[
            const SizedBox(height: 16),

            // Pickup Section (Green)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pickup #${order.pickupSequence}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.pickupAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        order.pickupContact,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Delivery Section (Blue)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'D',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery #${order.deliverySequence}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.dropAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        order.dropContact,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Info Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOrderInfoColumn(
                    Icons.inventory_2_outlined,
                    'Units',
                    '${order.totalUnits}',
                    Colors.purple,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildOrderInfoColumn(
                    Icons.scale_outlined,
                    'Weight',
                    '${order.totalGrossWeight} kg',
                    Colors.teal,
                  ),
                  if (order.codCollection) ...[
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildOrderInfoColumn(
                      Icons.payments_outlined,
                      'COD',
                      '₹${order.codAmount.toStringAsFixed(0)}',
                      Colors.amber[800]!,
                    ),
                  ],
                ],
              ),
            ),

            // Trip Order Notes
            if (order.tripOrderNotes != null && order.tripOrderNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber[200]!, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_alt_outlined, size: 16, color: Colors.amber[900]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.tripOrderNotes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons Section
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup Actions
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Pickup',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          if (_hasPopUploaded(order)) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.check, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Uploaded',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Open navigation to pickup
                        },
                        icon: const Icon(Icons.navigation, size: 16),
                        label: const Text('Open Navigation'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: Color(0xFF1E3A8A)),
                          foregroundColor: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _hasPopUploaded(order) ? null : (_orderPopUploading[order.orderId] == true ? null : () {
                          _uploadPopImages(order);
                        }),
                        icon: _orderPopUploading[order.orderId] == true 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.upload, size: 16),
                        label: Text(_hasPopUploaded(order) ? 'POP Uploaded' : 'POP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasPopUploaded(order) ? Colors.grey : const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      // Display uploaded images (from local cache OR from backend)
                      if ((_orderPopImages[order.orderId]?.isNotEmpty ?? false) || (order.proofOfPickup?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green[200]!, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(order.proofOfPickup?.length ?? 0) + (_orderPopImages[order.orderId]?.length ?? 0)} image(s)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  // Images from backend
                                  if (order.proofOfPickup != null)
                                    ...order.proofOfPickup!.map((url) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          url,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.error, size: 20, color: Colors.grey[600]),
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  // Images from local cache (before upload completes)
                                  if (_orderPopImages[order.orderId] != null)
                                    ..._orderPopImages[order.orderId]!.map((file) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(
                                          file,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Drop Actions (only enabled after POP is uploaded)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Drop',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          if (!_hasPopUploaded(order)) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Upload POP first to enable drop actions',
                              child: Icon(
                                Icons.lock,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _hasPopUploaded(order) ? () {
                          // Open navigation to drop
                        } : null,
                        icon: const Icon(Icons.navigation, size: 16),
                        label: const Text('Open Navigation'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(
                            color: _hasPopUploaded(order) ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
                          ),
                          foregroundColor: _hasPopUploaded(order) ? const Color(0xFF1E3A8A) : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: !_hasPopUploaded(order) ? null : (_hasPodUploaded(order) ? null : (_orderPodUploading[order.orderId] == true ? null : () {
                          _uploadPodImages(order);
                        })),
                        icon: _orderPodUploading[order.orderId] == true 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(_hasPodUploaded(order) ? Icons.check : Icons.upload, size: 16),
                        label: Text(_hasPodUploaded(order) ? 'POD Uploaded' : 'POD'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_hasPopUploaded(order) ? Colors.grey[300] : (_hasPodUploaded(order) ? Colors.grey : Colors.green),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[500],
                        ),
                      ),
                      // Display uploaded POD images (from local cache OR from backend)
                      if ((_orderPodImages[order.orderId]?.isNotEmpty ?? false) || (order.proofOfDelivery?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green[200]!, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(order.proofOfDelivery?.length ?? 0) + (_orderPodImages[order.orderId]?.length ?? 0)} image(s)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  // Images from backend
                                  if (order.proofOfDelivery != null)
                                    ...order.proofOfDelivery!.map((url) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          url,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.error, size: 20, color: Colors.grey[600]),
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  // Images from local cache (before upload completes)
                                  if (_orderPodImages[order.orderId] != null)
                                    ..._orderPodImages[order.orderId]!.map((file) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(
                                          file,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: !_hasPopUploaded(order) ? null : (_hasPodChallanUploaded(order) ? null : (_orderPodChallanUploading[order.orderId] == true ? null : () {
                          _uploadPodChallanImages(order);
                        })),
                        icon: _orderPodChallanUploading[order.orderId] == true 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(_hasPodChallanUploaded(order) ? Icons.check : Icons.upload, size: 16),
                        label: Text(_hasPodChallanUploaded(order) ? 'Challan Uploaded' : 'Upload POD Challan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_hasPopUploaded(order) ? Colors.grey[300] : (_hasPodChallanUploaded(order) ? Colors.grey : Colors.orange),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[500],
                        ),
                      ),
                      // Display uploaded POD Challan images (from local cache OR from backend)
                      if ((_orderPodChallanImages[order.orderId]?.isNotEmpty ?? false) || (order.podChallan?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange[200]!, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: Colors.orange[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(order.podChallan?.length ?? 0) + (_orderPodChallanImages[order.orderId]?.length ?? 0)} image(s)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  // Images from backend
                                  if (order.podChallan != null)
                                    ...order.podChallan!.map((url) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          url,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.error, size: 20, color: Colors.grey[600]),
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  // Images from local cache (before upload completes)
                                  if (_orderPodChallanImages[order.orderId] != null)
                                    ..._orderPodChallanImages[order.orderId]!.map((file) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(
                                          file,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (order.codCollection) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _hasPopUploaded(order) ? () {
                            _collectCod(order);
                          } : null,
                          icon: const Icon(Icons.currency_rupee, size: 16),
                          label: Text('Collect COD ₹${order.codAmount.toStringAsFixed(2)}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasPopUploaded(order) ? Colors.blue : Colors.grey[300],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _hasPopUploaded(order) ? () {
                            _collectToPay(order);
                          } : null,
                          icon: const Icon(Icons.currency_rupee, size: 16),
                          label: Text('Collect To-Pay ₹${(order.codAmount * 0.94).toStringAsFixed(2)}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasPopUploaded(order) ? Colors.deepOrange : Colors.grey[300],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getOrderStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.blue[50]!;
      case 'picked':
      case 'picked_up':
      case 'picked up':
        return Colors.green[50]!;
      case 'delivered':
        return Colors.green[100]!;
      case 'cancelled':
        return Colors.red[50]!;
      case 'pending':
        return Colors.orange[50]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Widget _buildOrderDetailCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header with ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.orderId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (order.express)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flash_on, size: 14, color: Colors.orange[800]),
                          const SizedBox(width: 4),
                          Text(
                            'Express',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(order.orderStatusInTrip).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getOrderStatusColor(order.orderStatusInTrip),
                    width: 1,
                  ),
                ),
                child: Text(
                  _formatOrderStatus(order.orderStatusInTrip, order.orderStatus),
                  style: TextStyle(
                    color: _getOrderStatusColor(order.orderStatusInTrip),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pickup Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pickup #${order.pickupSequence}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  order.pickupAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      order.pickupContact,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Delivery Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'D',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delivery #${order.deliverySequence}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  order.dropAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      order.dropContact,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Order Info Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOrderInfoColumn(
                  Icons.inventory_2_outlined,
                  'Units',
                  '${order.totalUnits}',
                  Colors.purple,
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildOrderInfoColumn(
                  Icons.scale_outlined,
                  'Weight',
                  '${order.totalGrossWeight} kg',
                  Colors.teal,
                ),
                if (order.codCollection) ...[
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildOrderInfoColumn(
                    Icons.payments_outlined,
                    'COD',
                    '₹${order.codAmount.toStringAsFixed(0)}',
                    Colors.amber[800]!,
                  ),
                ],
              ],
            ),
          ),

          // Trip Order Notes
          if (order.tripOrderNotes != null && order.tripOrderNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber[200]!, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_alt_outlined, size: 16, color: Colors.amber[900]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.tripOrderNotes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderInfoColumn(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _uploadPopImages(Order order) async {
    // Show image source selection dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6366F1)),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6366F1)),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      setState(() {
        _orderPopUploading[order.orderId] = true;
      });

      List<XFile> pickedFiles = [];
      
      if (source == ImageSource.camera) {
        // Camera can only pick one image at a time
        final XFile? image = await _imagePicker.pickImage(source: source);
        if (image != null) {
          pickedFiles.add(image);
        }
      } else {
        // Gallery can pick multiple images
        final List<XFile> images = await _imagePicker.pickMultiImage();
        pickedFiles.addAll(images);
      }

      if (pickedFiles.isEmpty) {
        setState(() {
          _orderPopUploading[order.orderId] = false;
        });
        return;
      }

      // Convert XFile to File
      List<File> imageFiles = pickedFiles.map((xfile) => File(xfile.path)).toList();

      // Upload to server
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _authService.uploadOrderProofMultiple(
        token,
        order.orderId,
        'proof_of_pickup',
        imageFiles,
      );

      if (response['success'] == true) {
        // Store locally for immediate display
        setState(() {
          if (_orderPopImages[order.orderId] == null) {
            _orderPopImages[order.orderId] = [];
          }
          _orderPopImages[order.orderId]!.addAll(imageFiles);
          _orderPopUploading[order.orderId] = false;
        });

        // Reload trip details to get updated data from backend
        await _loadCurrentTrip();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pickedFiles.length} image(s) uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Upload failed');
      }

    } catch (e) {
      print('Error uploading POP images: $e');
      setState(() {
        _orderPopUploading[order.orderId] = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasPopUploaded(Order order) {
    // Check if POP has been uploaded (from backend OR local cache)
    return order.pickedUpAt != null || 
           (order.proofOfPickup?.isNotEmpty ?? false) ||
           (_orderPopImages[order.orderId]?.isNotEmpty ?? false);
  }

  bool _areAllOrdersComplete() {
    // Check if all orders in the trip have completed all required uploads
    if (_tripDetails == null || _tripDetails!.orders.isEmpty) return false;
    
    for (final order in _tripDetails!.orders) {
      // Check if POP is uploaded
      if (!_hasPopUploaded(order)) {
        print('❌ Order ${order.orderId}: POP not uploaded');
        return false;
      }
      
      // Check if POD is uploaded
      if (!_hasPodUploaded(order)) {
        print('❌ Order ${order.orderId}: POD not uploaded');
        return false;
      }
      
      // Check if POD Challan is uploaded (if challan return is required)
      // Note: We check if challanReturn field exists in order, if yes then check upload
      // For now, we'll assume POD Challan is required for all orders
      if (!_hasPodChallanUploaded(order)) {
        print('❌ Order ${order.orderId}: POD Challan not uploaded');
        return false;
      }
      
      // Check if COD is collected (if COD collection is required)
      if (order.codCollection && order.codAmount > 0) {
        if (order.codStatus != 'collected') {
          print('❌ Order ${order.orderId}: COD not collected');
          return false;
        }
      }
      
      // Check if To-Pay is collected (if To-Pay is required)
      // Assuming order has toPayAmount field
      // For now, we'll skip this check as the API response doesn't show this field clearly
    }
    
    print('✅ All orders complete!');
    return true;
  }

  Future<void> _uploadPodImages(Order order) async {
    // Show image source selection dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      setState(() {
        _orderPodUploading[order.orderId] = true;
      });

      List<XFile> pickedFiles = [];
      
      if (source == ImageSource.camera) {
        final XFile? image = await _imagePicker.pickImage(source: source);
        if (image != null) {
          pickedFiles.add(image);
        }
      } else {
        final List<XFile> images = await _imagePicker.pickMultiImage();
        pickedFiles.addAll(images);
      }

      if (pickedFiles.isEmpty) {
        setState(() {
          _orderPodUploading[order.orderId] = false;
        });
        return;
      }

      List<File> imageFiles = pickedFiles.map((xfile) => File(xfile.path)).toList();

      // Upload to server
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _authService.uploadOrderProofMultiple(
        token,
        order.orderId,
        'proof_of_delivery',
        imageFiles,
      );

      if (response['success'] == true) {
        // Store locally for immediate display
        setState(() {
          if (_orderPodImages[order.orderId] == null) {
            _orderPodImages[order.orderId] = [];
          }
          _orderPodImages[order.orderId]!.addAll(imageFiles);
          _orderPodUploading[order.orderId] = false;
        });

        // Reload trip details to get updated data from backend
        await _loadCurrentTrip();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pickedFiles.length} image(s) uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Upload failed');
      }

    } catch (e) {
      print('Error uploading POD images: $e');
      setState(() {
        _orderPodUploading[order.orderId] = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPodChallanImages(Order order) async {
    // Show image source selection dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.orange),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      setState(() {
        _orderPodChallanUploading[order.orderId] = true;
      });

      List<XFile> pickedFiles = [];
      
      if (source == ImageSource.camera) {
        final XFile? image = await _imagePicker.pickImage(source: source);
        if (image != null) {
          pickedFiles.add(image);
        }
      } else {
        final List<XFile> images = await _imagePicker.pickMultiImage();
        pickedFiles.addAll(images);
      }

      if (pickedFiles.isEmpty) {
        setState(() {
          _orderPodChallanUploading[order.orderId] = false;
        });
        return;
      }

      List<File> imageFiles = pickedFiles.map((xfile) => File(xfile.path)).toList();

      // Upload to server
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _authService.uploadOrderProofMultiple(
        token,
        order.orderId,
        'pod_challan',
        imageFiles,
      );

      if (response['success'] == true) {
        // Store locally for immediate display
        setState(() {
          if (_orderPodChallanImages[order.orderId] == null) {
            _orderPodChallanImages[order.orderId] = [];
          }
          _orderPodChallanImages[order.orderId]!.addAll(imageFiles);
          _orderPodChallanUploading[order.orderId] = false;
        });

        // Reload trip details to get updated data from backend
        await _loadCurrentTrip();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pickedFiles.length} image(s) uploaded successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Upload failed');
      }

    } catch (e) {
      print('Error uploading POD Challan images: $e');
      setState(() {
        _orderPodChallanUploading[order.orderId] = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasPodUploaded(Order order) {
    return order.deliveredAt != null || 
           (order.proofOfDelivery?.isNotEmpty ?? false) ||
           (_orderPodImages[order.orderId]?.isNotEmpty ?? false);
  }

  bool _hasPodChallanUploaded(Order order) {
    return (order.podChallan?.isNotEmpty ?? false) ||
           (_orderPodChallanImages[order.orderId]?.isNotEmpty ?? false);
  }

  Future<void> _collectCod(Order order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Collect COD'),
          content: Text(
            'Confirm collection of ₹${order.codAmount.toStringAsFixed(2)} from customer?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _authService.collectCod(
        token,
        order.orderId,
        order.codAmount,
      );

      if (response['success'] == true) {
        // Reload trip details
        await _loadCurrentTrip();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('COD ₹${order.codAmount.toStringAsFixed(2)} collected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to collect COD');
      }
    } catch (e) {
      print('Error collecting COD: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _collectToPay(Order order) async {
    String? selectedMethod;
    File? paymentProof;
    final toPayAmount = order.codAmount * 0.94; // 94% of COD amount

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Collect To-Pay'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount: ₹${toPayAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Payment Method:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(value: 'online', child: Text('Online')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMethod = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Payment Proof (Optional):',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final source = await showDialog<ImageSource>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Image Source'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Camera'),
                                  onTap: () => Navigator.pop(context, ImageSource.camera),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Gallery'),
                                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (source != null) {
                          final XFile? image = await _imagePicker.pickImage(source: source);
                          if (image != null) {
                            setDialogState(() {
                              paymentProof = File(image.path);
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.upload),
                      label: Text(paymentProof != null ? 'Proof Selected' : 'Upload Proof'),
                    ),
                    if (paymentProof != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          paymentProof!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedMethod == null
                      ? null
                      : () => Navigator.of(context).pop({
                            'method': selectedMethod,
                            'proof': paymentProof,
                          }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Collect'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _authService.collectToPay(
        token,
        order.orderId,
        toPayAmount,
        result['method'],
        result['proof'],
      );

      if (response['success'] == true) {
        // Reload trip details
        await _loadCurrentTrip();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('To-Pay ₹${toPayAmount.toStringAsFixed(2)} collected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to collect To-Pay');
      }
    } catch (e) {
      print('Error collecting To-Pay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatOrderStatus(String statusInTrip, String orderStatus) {
    // Priority: use order_status if available, otherwise use order_status_in_trip
    final status = orderStatus.isNotEmpty ? orderStatus : statusInTrip;
    
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'ASSIGNED';
      case 'picked':
      case 'picked_up':
      case 'picked up':
        return 'PICKED';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      case 'pending':
        return 'PENDING';
      case 'in_transit':
      case 'in transit':
        return 'IN TRANSIT';
      default:
        return status.toUpperCase();
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
      case 'picked up':
      case 'picked':
        return Colors.green;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  // Color _getOrderStatusColor(String status) {
  //   switch (status.toLowerCase()) {
  //     case 'pending':
  //       return Colors.orange;
  //     case 'picked':
  //       return Colors.blue;
  //     case 'delivered':
  //       return Colors.green;
  //     case 'cancelled':
  //       return Colors.red;
  //     default:
  //       return Colors.grey;
  //   }
  // }

  Future<void> _handleAcceptTrip() async {
    if (_currentTrip == null) {
      return;
    }
    
    setState(() {
      _isLoadingTrip = true;
    });
    
    try {
      final token = await UserService.getToken();
      if (token != null) {
        final response = await _authService.acceptTrip(
          token,
          _currentTrip!.id,
        );
        
        if (response['success'] == true) {
          print('✅ Trip accepted successfully');
          print('   Response data: ${response['data']}');
          print('   Trip ID from response: ${response['data']?['trip_id']}');
          print('   Message: ${response['data']?['message']}');
          
          // Immediately update local state to "accepted" since API confirmed success
          if (_currentTrip != null) {
            // Create a temporary updated trip object to trigger UI update
            setState(() {
              // Force the UI to recognize trip as accepted
              // This ensures button shows immediately
            });
          }
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['data']?['message'] ?? response['message'] ?? 'Trip accepted successfully. You can now start the trip.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          
          // Reload trip data to sync with backend
          print('🔄 Reloading trip data after accept...');
          await Future.delayed(const Duration(milliseconds: 500));
          await _loadCurrentTrip();
          
          print('🔍 After reload - Current Trip:');
          print('   - ID: ${_currentTrip?.id}');
          print('   - Trip ID: ${_currentTrip?.tripId}');
          print('   - Driver Response: "${_currentTrip?.driverResponse}"');
          print('   - Trip Status: "${_currentTrip?.tripStatus}"');
          print('   - Actual Start Time: ${_currentTrip?.actualStartTime}');
          
          print('🔍 After reload - Trip Details:');
          print('   - Driver Response: "${_tripDetails?.driverResponse}"');
          print('   - Trip Status: "${_tripDetails?.tripStatus}"');
          print('   - Actual Start Time: ${_tripDetails?.actualStartTime}');
          
          // Check button condition
          final driverResp = (_tripDetails?.driverResponse ?? _currentTrip?.driverResponse ?? '').toLowerCase();
          final startTime = _tripDetails?.actualStartTime ?? _currentTrip?.actualStartTime;
          print('🎯 Button Condition Check:');
          print('   - Driver Response (lowercase): "$driverResp"');
          print('   - Is "accepted"? ${driverResp == 'accepted'}');
          print('   - Start Time is null? ${startTime == null}');
          print('   - Should show Start Trip button? ${driverResp == 'accepted' && startTime == null}');
          
          // If still not updated, try once more
          if (driverResp != 'accepted') {
            print('⚠️ Driver response is "$driverResp", not "accepted". Retrying...');
            await Future.delayed(const Duration(seconds: 1));
            await _loadCurrentTrip();
            
            final retryResp = (_tripDetails?.driverResponse ?? _currentTrip?.driverResponse ?? '').toLowerCase();
            print('🔍 After retry - Driver Response: "$retryResp"');
          }
        } else {
          throw Exception(response['message'] ?? 'Failed to accept trip');
        }
      }
    } catch (e) {
      print('Error accepting trip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingTrip = false;
      });
    }
  }

  Future<void> _handleRejectTrip() async {
    if (_currentTrip == null) {
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Trip'),
          content: const Text(
            'Are you sure you want to reject this trip? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    
    if (confirmed != true) {
      return;
    }
    
    setState(() {
      _isLoadingTrip = true;
    });
    
    try {
      final token = await UserService.getToken();
      if (token != null) {
        final response = await _authService.rejectTrip(
          token,
          _currentTrip!.id,
        );
        
        if (response['success'] == true) {
          // Reload the current trip to get updated status
          await _loadCurrentTrip();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['data']?['message'] ?? response['message'] ?? 'Trip rejected successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          throw Exception(response['message'] ?? 'Failed to reject trip');
        }
      }
    } catch (e) {
      print('Error rejecting trip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingTrip = false;
      });
    }
  }
  
  void _showStartTripDialog() {
    // Pre-fill Planned KM from trip details (formatted to 2 decimal places)
    if (_tripDetails?.kmByGoogle != null && _tripDetails!.kmByGoogle!.isNotEmpty) {
      final kmValue = double.tryParse(_tripDetails!.kmByGoogle!) ?? 0.0;
      _plannedKmController.text = kmValue.toStringAsFixed(2);
    } else if (_tripDetails?.plannedKm != null && _tripDetails!.plannedKm!.isNotEmpty) {
      final kmValue = double.tryParse(_tripDetails!.plannedKm!) ?? 0.0;
      _plannedKmController.text = kmValue.toStringAsFixed(2);
    } else {
      _plannedKmController.clear();
    }
    
    _startKmController.clear();
    _startKmPic = null;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Start Trip'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _plannedKmController,
                      decoration: const InputDecoration(
                        labelText: 'Planned KM',
                        hintText: 'Enter planned kilometers',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: true, // Make it read-only since it's auto-filled
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _startKmController,
                      decoration: const InputDecoration(
                        labelText: 'Start KM',
                        hintText: 'Enter starting odometer reading',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Start KM Photo (capture only)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_startKmPic != null) ...[
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _startKmPic!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () async {
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 85,
                        );
                        
                        if (image != null) {
                          setDialogState(() {
                            _startKmPic = File(image.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_startKmPic != null ? 'Retake Photo' : 'Open Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isStartingTrip ? null : () async {
                    if (_plannedKmController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter planned KM'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    if (_startKmController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter start KM'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    if (_startKmPic == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please add start KM photo'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.of(context).pop();
                    await _handleStartTrip();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isStartingTrip
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Start Trip'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _handleStartTrip() async {
    if (_currentTrip == null) {
      return;
    }
    
    setState(() {
      _isStartingTrip = true;
    });
    
    try {
      final token = await UserService.getToken();
      if (token != null) {
        final response = await _authService.startTrip(
          token,
          _currentTrip!.id,
          _plannedKmController.text,
          _startKmController.text,
          _startKmPic,
        );
        
        if (response['success'] == true) {
          // Reload the current trip to get updated status
          await _loadCurrentTrip();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['data']?['message'] ?? response['message'] ?? 'Trip started successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(response['message'] ?? 'Failed to start trip');
        }
      }
    } catch (e) {
      print('Error starting trip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isStartingTrip = false;
      });
    }
  }

  void _showEndTripDialog() {
    final TextEditingController endKmController = TextEditingController();
    File? endKmPic;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('End Trip'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please provide the ending odometer reading to complete this trip.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: endKmController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'End KM *',
                        hintText: 'Enter ending odometer reading',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.speed),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload Odometer Photo *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (endKmPic != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              endKmPic!,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 16,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    endKmPic = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.camera);
                              if (image != null) {
                                setState(() {
                                  endKmPic = File(image.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setState(() {
                                  endKmPic = File(image.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    // Validate inputs
                    if (endKmController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter end KM')),
                      );
                      return;
                    }
                    
                    if (endKmPic == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please upload odometer photo')),
                      );
                      return;
                    }

                    setState(() {
                      isLoading = true;
                    });

                    try {
                      final token = await UserService.getToken();
                      if (token == null) {
                        throw Exception('Not authenticated');
                      }

                      final tripId = _tripDetails?.id ?? _currentTrip!.id;

                      await _authService.endTrip(
                        token,
                        tripId,
                        endKmController.text.trim(),
                        endKmPic,
                      );

                      if (!mounted) return;
                      
                      Navigator.of(context).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trip ended successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Reload current trip
                      await _loadCurrentTrip();
                    } catch (e) {
                      if (!mounted) return;
                      
                      setState(() {
                        isLoading = false;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to end trip: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('End Trip'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryView() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          const Text(
            'Trip History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 24),
          
          // Section Title
          const Text(
            'Delivery History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // From Date
                    Expanded(
                      child: TextField(
                        controller: _fromDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'From Date',
                          hintText: 'dd-mm-yyyy',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context, _fromDateController),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // To Date
                    Expanded(
                      child: TextField(
                        controller: _toDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'To Date',
                          hintText: 'dd-mm-yyyy',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context, _toDateController),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Search
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          hintText: 'Search by ID, name...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Trigger rebuild for filtered list
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Trip History Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _filteredTripHistory.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No trip history found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                      columns: const [
                        DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('TRIP ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('TRIP NAME', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ORDERS', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _filteredTripHistory.asMap().entries.map((entry) {
                        final index = entry.key;
                        final trip = entry.value;
                        final date = _formatDate(trip.scheduledDate);
                        
                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text(date)),
                            DataCell(Text(trip.tripId)),
                            DataCell(Text(trip.tripName)),
                            DataCell(Text('${trip.totalOrders}')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: trip.tripStatus == 'Trip Closed' 
                                      ? Colors.amber[100]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  trip.tripStatus,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: trip.tripStatus == 'Trip Closed' 
                                        ? Colors.amber[900]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              _isLoadingTripDetails
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.visibility, color: Color(0xFF1E3A8A)),
                                      onPressed: () {
                                        _showTripDetails(trip);
                                      },
                                    ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  bool _isLoadingTripDetails = false;
  
  void _showTripDetails(TripHistory trip) {
    if (trip.tripId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid trip ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _loadTripDetails(trip.tripId);
  }
  
  Future<void> _loadTripDetails(String tripId) async {
    if (tripId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip ID is required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    if (_isLoadingTripDetails) return; // Prevent multiple simultaneous calls
    
    setState(() {
      _isLoadingTripDetails = true;
    });
    
    try {
      final token = await UserService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingTripDetails = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication token not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final response = await _authService.getTripDetails(token, tripId);
      
      if (mounted) {
        setState(() {
          _isLoadingTripDetails = false;
        });
        
        if (response.success && response.data != null) {
          _showTripDetailsDialog(response.data!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty 
                  ? response.message 
                  : 'Failed to load trip details'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading trip details: $e');
      if (mounted) {
        setState(() {
          _isLoadingTripDetails = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showTripDetailsDialog(TripDetails tripDetails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trip Details: ${tripDetails.tripId}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tripDetails.tripName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        // Trip Information
                        const Text(
                          'Trip Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow('Trip Status', tripDetails.tripStatus),
                        _buildDetailRow('Scheduled Date', _formatDate(tripDetails.scheduledDate)),
                        if (tripDetails.actualStartTime != null)
                          _buildDetailRow('Start Time', _formatDateTime(tripDetails.actualStartTime!)),
                        if (tripDetails.actualEndTime != null)
                          _buildDetailRow('End Time', _formatDateTime(tripDetails.actualEndTime!)),
                        _buildDetailRow('Hub', tripDetails.hubName),
                        if (tripDetails.hubAddress != null)
                          _buildDetailRow('Hub Address', tripDetails.hubAddress!),
                        if (tripDetails.assignedDriverName != null)
                          _buildDetailRow('Driver', tripDetails.assignedDriverName!),
                        if (tripDetails.assignedVehicleId != null)
                          _buildDetailRow('Vehicle', tripDetails.assignedVehicleId!),
                        if (tripDetails.notes != null && tripDetails.notes!.isNotEmpty)
                          _buildDetailRow('Notes', tripDetails.notes!),
                        const SizedBox(height: 24),
                        
                        // Orders Section
                        Text(
                          'Orders (${tripDetails.orders.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (tripDetails.orders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'No orders found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ...tripDetails.orders.asMap().entries.map((entry) {
                            final index = entry.key;
                            final order = entry.value;
                            return _buildOrderCard(order, index + 1);
                          }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOrderCard(Order order, int orderNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderNumber: ${order.orderId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(order.orderStatus),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.orderStatus.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        const Text(
                          'Pickup',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        order.pickupAddress,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        'Contact: ${order.pickupContact}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        'Sequence: ${order.pickupSequence}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        const Text(
                          'Delivery',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        order.dropAddress,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        'Contact: ${order.dropContact}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        'Sequence: ${order.deliverySequence}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderInfoItem('Units', '${order.totalUnits}'),
              _buildOrderInfoItem('Weight', '${order.totalGrossWeight} kg'),
              if (order.codCollection)
                _buildOrderInfoItem('COD', '₹${order.codAmount.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 12),
          // Proof Upload Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUploadProofDialog(order.orderId, 'proof_of_pickup', 'Proof of Pickup'),
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('PoP', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUploadProofDialog(order.orderId, 'proof_of_delivery', 'Proof of Delivery'),
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('PoD', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUploadProofDialog(order.orderId, 'proof_of_delivery_challan', 'PoD Challan'),
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Challan', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showUploadProofDialog(String orderId, String field, String fieldLabel) {
    File? selectedFile;
    bool isUploading = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Upload $fieldLabel'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: $orderId',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Proof Document',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final ImageSource? source = await showDialog<ImageSource>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Image Source'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Camera'),
                                  onTap: () => Navigator.pop(context, ImageSource.camera),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Gallery'),
                                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                                ),
                              ],
                            ),
                          ),
                        );
                        
                        if (source != null) {
                          final XFile? image = await _imagePicker.pickImage(
                            source: source,
                            imageQuality: 85,
                          );
                          
                          if (image != null) {
                            setDialogState(() {
                              selectedFile = File(image.path);
                            });
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: selectedFile != null
                            ? Image.file(
                                selectedFile!,
                                fit: BoxFit.cover,
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to select photo',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (selectedFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a proof document'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    setDialogState(() {
                      isUploading = true;
                    });
                    
                    try {
                      final token = await UserService.getToken();
                      if (token != null) {
                        final response = await _authService.uploadOrderProof(
                          token,
                          orderId,
                          field,
                          selectedFile!,
                        );
                        
                        if (response['success'] == true) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response['data']?['message'] ?? response['message'] ?? '$fieldLabel uploaded successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          throw Exception(response['message'] ?? 'Failed to upload proof');
                        }
                      }
                    } catch (e) {
                      print('Error uploading proof: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setDialogState(() {
                          isUploading = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildOrderInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  

  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.day}/${date.month}/${date.year}, $hour:$minute $amPm';
    } catch (e) {
      return dateString;
    }
  }
  
  void _showFullScreenMap() {
    MapType fullScreenMapType = MapType.normal;
    GoogleMapController? fullScreenMapController;
    bool fullScreenTrackingEnabled = _isRealTimeTrackingEnabled;
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Stack(
                  children: [
                    // Fullscreen Map
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          (_hubLocation.latitude + _deliveryLocation.latitude) / 2,
                          (_hubLocation.longitude + _deliveryLocation.longitude) / 2,
                        ),
                        zoom: 11.0,
                      ),
                      markers: _mapMarkers,
                      polylines: _mapPolylines,
                      mapType: fullScreenMapType,
                      zoomControlsEnabled: true,
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                      compassEnabled: true,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      onMapCreated: (GoogleMapController controller) {
                        fullScreenMapController = controller;
                        _fullScreenMapController = controller; // Store reference for real-time updates
                        // Fit bounds to show all markers
                        _fitBoundsForController(controller);
                      },
                    ),
                    // Close Button
                    Positioned(
                      top: 40,
                      right: 16,
                      child: Container(
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
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.black87),
                          onPressed: () {
                            _fullScreenMapController = null; // Clear reference when closing
                            Navigator.of(context).pop();
                          },
                          tooltip: 'Close',
                        ),
                      ),
                    ),
                    // Map Type Toggle Button
                    Positioned(
                      top: 40,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: PopupMenuButton<MapType>(
                          icon: const Icon(Icons.layers, color: Colors.black87),
                          onSelected: (MapType type) {
                            setDialogState(() {
                              fullScreenMapType = type;
                            });
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<MapType>(
                              value: MapType.normal,
                              child: Text('Normal'),
                            ),
                            const PopupMenuItem<MapType>(
                              value: MapType.satellite,
                              child: Text('Satellite'),
                            ),
                            const PopupMenuItem<MapType>(
                              value: MapType.terrain,
                              child: Text('Terrain'),
                            ),
                            const PopupMenuItem<MapType>(
                              value: MapType.hybrid,
                              child: Text('Hybrid'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // My Location Button
                    Positioned(
                      bottom: 80,
                      right: 16,
                      child: Container(
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
                        child: IconButton(
                          icon: const Icon(Icons.my_location, color: Colors.blue),
                          onPressed: () async {
                            if (fullScreenMapController != null) {
                              await _findMyLocation();
                              if (_currentPosition != null && fullScreenMapController != null) {
                                fullScreenMapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    15.0,
                                  ),
                                );
                              }
                            }
                          },
                          tooltip: 'My Location',
                        ),
                      ),
                    ),
                    // Real-time Tracking Toggle Button (Full Screen)
                    Positioned(
                      bottom: 140,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: fullScreenTrackingEnabled ? Colors.green : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            fullScreenTrackingEnabled ? Icons.gps_fixed : Icons.gps_not_fixed,
                            color: fullScreenTrackingEnabled ? Colors.white : Colors.grey[700],
                          ),
                          onPressed: () {
                            setDialogState(() {
                              fullScreenTrackingEnabled = !fullScreenTrackingEnabled;
                              // If enabling, immediately center on current location
                              if (fullScreenTrackingEnabled && _currentPosition != null && fullScreenMapController != null) {
                                fullScreenMapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    15.0,
                                  ),
                                );
                              }
                            });
                            // Also update the main tracking state
                            setState(() {
                              _isRealTimeTrackingEnabled = fullScreenTrackingEnabled;
                            });
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  fullScreenTrackingEnabled 
                                    ? 'Real-time tracking enabled - Map will follow your location'
                                    : 'Real-time tracking disabled',
                                ),
                                backgroundColor: fullScreenTrackingEnabled ? Colors.green : Colors.grey,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: fullScreenTrackingEnabled ? 'Disable real-time tracking' : 'Enable real-time tracking',
                        ),
                      ),
                    ),
                    // Real-time Tracking Indicator (Full Screen)
                    if (fullScreenTrackingEnabled)
                      Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Live Tracking',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
  
  Future<void> _fitBoundsForController(GoogleMapController controller) async {
    if (_mapMarkers.isEmpty) return;
    
    double minLat = _mapMarkers.first.position.latitude;
    double maxLat = _mapMarkers.first.position.latitude;
    double minLng = _mapMarkers.first.position.longitude;
    double maxLng = _mapMarkers.first.position.longitude;
    
    for (var marker in _mapMarkers) {
      minLat = minLat < marker.position.latitude ? minLat : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude ? maxLat : marker.position.latitude;
      minLng = minLng < marker.position.longitude ? minLng : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude ? maxLng : marker.position.longitude;
    }
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );
    
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  Widget _buildEarningsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.attach_money,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Earnings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your earnings will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    await UserService.clearUserData();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }
}

