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
  bool _isLoadingTrip = false;
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
        final response = await _authService.getCurrentTrip(token);
        if (response.success && response.data != null) {
          setState(() {
            _currentTrip = response.data;
            _isActive = true; // Trip exists, so driver is active
          });
        } else {
          setState(() {
            _currentTrip = null;
          });
        }
      }
    } catch (e) {
      print('Error loading current trip: $e');
      setState(() {
        _currentTrip = null;
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
  
  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    _fullScreenMapController?.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _searchController.dispose();
    _plannedKmController.dispose();
    _startKmController.dispose();
    super.dispose();
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
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rajesh Singh',
                        style: TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
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
                        child: const Center(
                          child: Text(
                            'R',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rajesh Singh',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'moneyformanish@gmail.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
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
              onSelected: (String value) {
                if (value == 'signout') {
                  _handleSignOut();
                } else if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DriverProfile()),
                  );
                } else if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DriverSettings()),
                  );
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
                  child: const Center(
                    child: Text(
                      'R',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rajesh Singh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        'KBD1',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
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
          // Page Title
          const Text(
            'My Trips',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
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
                    // Show appropriate button based on trip status
                    if (_currentTrip!.driverResponse.toLowerCase() == 'pending')
                      ElevatedButton.icon(
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
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    else if (_currentTrip!.driverResponse.toLowerCase() == 'accepted' && 
                             _currentTrip!.actualStartTime == null)
                      ElevatedButton.icon(
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
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () {
                          _showEndTripDialog();
                        },
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
          // Reload the current trip to get updated status
          await _loadCurrentTrip();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['data']?['message'] ?? response['message'] ?? 'Trip accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
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
  
  void _showStartTripDialog() {
    _plannedKmController.clear();
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
                      'Start KM Photo',
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
                              _startKmPic = File(image.path);
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
                        child: _startKmPic != null
                            ? Image.file(
                                _startKmPic!,
                                fit: BoxFit.cover,
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to add photo',
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Trip'),
          content: const Text(
            'Are you sure you want to end this trip? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trip ended successfully'),
                  ),
                );
                // Handle end trip logic here
              },
              child: const Text(
                'End Trip',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
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
  
  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'picked':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

