import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/fixed_price_dimensions_model.dart';
import '../../models/commodities_model.dart';
import '../../models/order_submit_model.dart';
import '../../models/place_search_model.dart';
import '../../models/dc_closing_time_model.dart';
import '../../models/saved_dimensions_model.dart';
import '../../models/discount_coupon_model.dart';
import '../../models/order_submit_model.dart' as order_submit_model;
import '../../models/dynamic_price_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/responsive.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Multiple dimensions for Fixed Price form
class DimensionData {
  final String id;
  final TextEditingController lengthController;
  final TextEditingController breadthController;
  final TextEditingController heightController;
  final TextEditingController unitsController;
  final TextEditingController unitWeightController;
  final TextEditingController chargesController;
  FixedPriceDimension? selectedDimension;
  SavedDimension? selectedSavedDimension;
  
  DimensionData({
    required this.id,
    required this.lengthController,
    required this.breadthController,
    required this.heightController,
    required this.unitsController,
    required this.unitWeightController,
    required this.chargesController,
    this.selectedDimension,
    this.selectedSavedDimension,
  });
  
  void dispose() {
    lengthController.dispose();
    breadthController.dispose();
    heightController.dispose();
    unitsController.dispose();
    unitWeightController.dispose();
    chargesController.dispose();
  }
}

class BookPartload extends StatefulWidget {
  final bool hasFixedPriceAccess;
  final List<FixedPriceDimension> fixedPriceDimensions;

  const BookPartload({
    super.key,
    this.hasFixedPriceAccess = false,
    this.fixedPriceDimensions = const [],
  });

  @override
  State<BookPartload> createState() => _BookPartloadState();
}

class _BookPartloadState extends State<BookPartload> {
  String _pricingType = 'Dynamic Price'; // Default to Dynamic Price
  String? _selectedSavedDimension;
  List<SavedDimension> _savedDimensions = [];
  bool _isLoadingSavedDimensions = false;
  bool _isSavingDimension = false;
  bool _isDeletingDimension = false;
  bool _isDeletingFromDropdown = false;
  final TextEditingController _dimensionNameController = TextEditingController();
  bool _expressDelivery = false;
  bool _challanReturn = false;
  bool _collectCOD = false;
  List<Commodity> _commodities = [];
  List<Commodity> _filteredCommodities = [];
  bool _isLoadingCommodities = false;
  String? _selectedCommodityId;
  List<String> _blockedKeywords = [];
  bool _isLoadingBlockedKeywords = false;
  List<DiscountCoupon> _discountCoupons = [];
  bool _isLoadingCoupons = false;
  List<PlaceSearchResult> _shipperResults = [];
  bool _isSearchingShippers = false;
  String? _selectedShipperId;
  PlaceSearchResult? _selectedShipper;
  List<PlaceSearchResult> _consigneeResults = [];
  bool _isSearchingConsignees = false;
  String? _selectedConsigneeId;
  PlaceSearchResult? _selectedConsignee;
  String? _dcClosingTime;
  bool _isLoadingClosingTime = false;
  DateTime? _pickupDate;
  String? _selectedPickupTime;
  List<String> _pickupTimeWindows = [
    '08:00AM to 10:00 AM',
    '09:00AM to 11:00 AM',
    '10:00 AM to 12:00 PM',
    '11:00 AM to 01:00 PM',
    '12:00 PM to 02:00 PM',
  ];
  final AuthService _authService = AuthService();
  final FocusNode _shipperFocusNode = FocusNode();
  final FocusNode _commodityFocusNode = FocusNode();
  final FocusNode _consigneeFocusNode = FocusNode();

  final TextEditingController _commodityController = TextEditingController();
  final TextEditingController _shipperController = TextEditingController();
  final TextEditingController _pickupDateController = TextEditingController();
  final TextEditingController _pickupTimeController = TextEditingController();
  final TextEditingController _pickupNoteController = TextEditingController();
  final TextEditingController _consigneeController = TextEditingController();
  final TextEditingController _consigneeClosingTimeController = TextEditingController();
  final TextEditingController _dropNoteController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _breadthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController(text: '1');
  final TextEditingController _unitWeightController = TextEditingController();
  final TextEditingController _chargesController = TextEditingController();
  final TextEditingController _totalWeightController = TextEditingController(text: '0.00');
  final TextEditingController _couponCodeController = TextEditingController();
  final TextEditingController _codAmountController = TextEditingController();
  String? _appliedCouponCode;
  String? _couponDiscountAmount;
  bool _isValidatingCoupon = false;
  bool _isSubmittingOrder = false;
  List<String> _challanFilePaths = [];
  final ImagePicker _imagePicker = ImagePicker();
  String _walletBalance = '0.00';
  
  // Dynamic price configuration
  DynamicPriceData? _dynamicPriceConfig;
  bool _isLoadingDynamicPrice = false;
  
  // Fixed price dimensions
  List<FixedPriceDimension> _fixedPriceDimensions = [];
  FixedPriceDimension? _selectedFixedPriceDimension;
  bool _isLoadingFixedPriceDimensions = false;
  
  // Multiple dimensions for Fixed Price form
  List<DimensionData> _dimensionList = [];
  
  // Multiple dimensions for Dynamic Price form
  List<DimensionData> _dynamicDimensionList = [];
  
  // Calculated values
  double _totalUnits = 0;
  double _totalGrossWeight = 0;
  double _totalVolumetricWeight = 0;
  double _totalVolume = 0;
  double _chargeableWeight = 0;
  double _transportAmount = 0;
  double _preTaxAmount = 0;
  double _subTotalBeforeDiscount = 0; // Sub Total before coupon discount
  double _subTotalAfterDiscount = 0; // Sub Total after coupon discount (for Dynamic Price)
  double _expressCharges = 0; // Express charges (calculated separately)
  double _gstAmount = 0;
  double _finalPayable = 0;

  @override
  void initState() {
    super.initState();
    // Set default pricing type based on fixed price access
    if (widget.hasFixedPriceAccess) {
      _pricingType = 'Fixed Price';
    }
    // Load commodities, blocked keywords, and discount coupons when screen loads
    _loadCommodities();
    _loadBlockedKeywords();
    _loadDiscountCoupons();
    _loadWalletBalance();
     // Load fixed price dimensions if in fixed price mode
     if (widget.hasFixedPriceAccess && _pricingType == 'Fixed Price') {
       if (widget.fixedPriceDimensions.isNotEmpty) {
         _fixedPriceDimensions = widget.fixedPriceDimensions;
       } else {
         _loadFixedPriceDimensions();
       }
      // Initialize with one dimension for Fixed Price
      if (_dimensionList.isEmpty) {
       _addNewDimension();
      }
     }
    // Load dynamic price configuration if in dynamic pricing mode
    if (!widget.hasFixedPriceAccess || _pricingType == 'Dynamic Price') {
      _loadSavedDimensions();
      _loadActiveDynamicPrice();
      // Initialize with one dimension for dynamic pricing
      if (_dynamicDimensionList.isEmpty) {
        _addNewDynamicDimension();
      }
    }
    // Add listeners to dimension fields for auto-calculation
    _lengthController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      } else {
        _calculatePrice();
      }
    });
    _breadthController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      } else {
        _calculatePrice();
      }
    });
    _heightController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      } else {
        _calculatePrice();
      }
    });
    _unitsController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      } else {
        _calculatePrice();
      }
    });
    _unitWeightController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      } else {
        _calculatePrice();
      }
    });
    _codAmountController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      } else {
        _calculatePrice();
      }
    });
    _expressDelivery = false;
    _challanReturn = false;
    _collectCOD = false;
    // Add listener to shipper field for search
    _shipperController.addListener(_onShipperSearch);
    _shipperFocusNode.addListener(_onShipperFocusChange);
    // Add listener to commodity field for search
    _commodityController.addListener(_onCommoditySearch);
    _commodityFocusNode.addListener(_onCommodityFocusChange);
    // Add listener to consignee field for search
    _consigneeController.addListener(_onConsigneeSearch);
    _consigneeFocusNode.addListener(_onConsigneeFocusChange);
  }

  Future<void> _loadWalletBalance() async {
    try {
      final token = await UserService.getToken();
      if (token != null) {
        print('🔵 Fetching wallet balance from customer details...');
        final customerDetails = await _authService.getCustomerDetails(token);
        if (mounted) {
          setState(() {
            _walletBalance = customerDetails.data.walletBalance ?? '0.00';
          });
        }
        print('✅ Wallet balance loaded: ₹$_walletBalance');
      }
    } catch (e) {
      print('❌ Error loading wallet balance: $e');
      if (mounted) {
        setState(() {
          _walletBalance = '0.00';
        });
      }
    }
  }

  Future<void> _loadFixedPriceDimensions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFixedPriceDimensions = true;
    });

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        throw Exception('Authentication token or customer ID not found.');
      }

      print('🔵 Fetching fixed price dimensions for customer: ${customer.id}');
      final response = await _authService.getFixedPriceDimensions(customer.id, token);

      if (mounted) {
        setState(() {
          _fixedPriceDimensions = response.data.where((dim) => dim.status == 'active').toList();
          _isLoadingFixedPriceDimensions = false;
        });
        print('✅ Fixed price dimensions loaded: ${_fixedPriceDimensions.length} active dimensions');
        if (_fixedPriceDimensions.isNotEmpty) {
          final firstDim = _fixedPriceDimensions.first;
          print('   Sample dimension - Express delivery %: ${firstDim.expressDeliveryPercentage}, Challan charges: ${firstDim.chalaanReturnCharges}');
        }
      }
    } catch (e) {
      print('❌ Error loading fixed price dimensions: $e');
      if (mounted) {
        setState(() {
          _isLoadingFixedPriceDimensions = false;
        });
        _showErrorDialog('Failed to load dimensions. Please try again.');
      }
    }
  }

  void _onCommoditySearch() {
    if (!mounted) return;
    final searchTerm = _commodityController.text.trim().toLowerCase();
    print('🔵 Commodity search: "$searchTerm", commodities count: ${_commodities.length}');
    
    if (searchTerm.isEmpty) {
      // If field has focus, show all commodities, otherwise show none
      if (_commodityFocusNode.hasFocus) {
        print('✅ Showing all commodities (${_commodities.length})');
        setState(() {
          _filteredCommodities = _commodities;
        });
    } else {
        print('❌ Clearing filtered commodities (no focus)');
      setState(() {
          _filteredCommodities = [];
        });
      }
    } else {
      // Filter commodities based on search term
      final filtered = _commodities.where((commodity) {
          return commodity.name.toLowerCase().contains(searchTerm);
        }).toList();
      print('✅ Filtered commodities: ${filtered.length} matches');
      setState(() {
        _filteredCommodities = filtered;
      });
    }
  }

  void _onCommodityFocusChange() {
    print('🔵 Commodity focus changed: hasFocus=${_commodityFocusNode.hasFocus}, text="${_commodityController.text}"');
    
    if (!_commodityFocusNode.hasFocus) {
      // Clear filtered results when field loses focus (with delay to allow tap)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_commodityFocusNode.hasFocus) {
          print('❌ Clearing filtered commodities (lost focus)');
          setState(() {
            _filteredCommodities = [];
          });
        }
      });
    } else {
      // When field gains focus, DON'T call setState immediately
      // Just call APIs without updating UI state to avoid closing keyboard
      print('🔵 Commodity field focused - loading commodities and blocked keywords...');
      _loadCommodities();
      _loadBlockedKeywords();
      
      // Show commodities after a delay (only if still focused)
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || !_commodityFocusNode.hasFocus) return;
        
        // Show commodities if available
      if (_commodityController.text.isEmpty) {
          // Show all commodities when field is focused and empty (like web)
          if (_commodities.isNotEmpty) {
            print('✅ Showing all commodities on focus (${_commodities.length})');
        setState(() {
          _filteredCommodities = _commodities;
        });
          }
      } else {
        // If there's text, filter based on it
          print('✅ Filtering commodities based on existing text');
        _onCommoditySearch();
      }
      });
    }
  }

  void _onShipperSearch() {
    final searchTerm = _shipperController.text.trim();
    if (searchTerm.length >= 2) {
      _searchShippers(searchTerm);
    } else {
      setState(() {
        _shipperResults = [];
      });
    }
  }

  void _onShipperFocusChange() {
    if (!_shipperFocusNode.hasFocus) {
      // Clear results when field loses focus
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _shipperResults = [];
          });
        }
      });
    }
  }

  Future<void> _loadDcClosingTime(String placeId) async {
    if (!mounted || placeId.isEmpty) return;
    setState(() {
      _isLoadingClosingTime = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Fetching DC closing time for place: $placeId');
      final response = await _authService.getDcClosingTime(placeId, token);

      if (mounted) {
        setState(() {
          _dcClosingTime = response.data.maxOrderTime;
          _isLoadingClosingTime = false;
        });
        print('✅ DC closing time: $_dcClosingTime');
        
        // Automatically set pickup date based on closing time
        if (_dcClosingTime != null && _dcClosingTime!.isNotEmpty) {
          final now = DateTime.now();
          try {
            final timeParts = _dcClosingTime!.split(':');
            if (timeParts.length >= 2) {
              final closingHour = int.parse(timeParts[0]);
              final closingMinute = int.parse(timeParts[1]);
              final closingTime = DateTime(now.year, now.month, now.day, closingHour, closingMinute);
              
              DateTime selectedDate;
              if (now.compareTo(closingTime) >= 0) {
                // Current time has passed closing time, set to tomorrow
                selectedDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
                print('🔵 Current time past closing time, setting pickup date to tomorrow');
              } else {
                // Current time is before closing time, set to today
                selectedDate = DateTime(now.year, now.month, now.day);
                print('🔵 Current time before closing time, setting pickup date to today');
              }
              
              setState(() {
                _pickupDate = selectedDate;
                _pickupDateController.text = _formatPickupDate(selectedDate);
              });
              print('✅ Pickup date automatically set to: ${_formatPickupDate(selectedDate)}');
            }
          } catch (e) {
            print('❌ Error parsing closing time: $e');
          }
        } else {
          // If no closing time, clear pickup date if it's no longer valid
        if (_pickupDate != null && _isDateDisabled(_pickupDate!)) {
          setState(() {
            _pickupDate = null;
            _pickupDateController.clear();
          });
          }
        }
      }
    } catch (e) {
      print('❌ Error loading DC closing time: $e');
      if (mounted) {
        setState(() {
          _isLoadingClosingTime = false;
        });
      }
    }
  }

  bool _isDateDisabled(DateTime date) {
    if (_dcClosingTime == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);
    
    // If selected date is not today, it's always allowed
    if (selectedDate.year != today.year || 
        selectedDate.month != today.month || 
        selectedDate.day != today.day) {
      return false;
    }
    
    // If selected date is today, check if current time has passed closing time
    try {
      final timeParts = _dcClosingTime!.split(':');
      if (timeParts.length >= 2) {
        final closingHour = int.parse(timeParts[0]);
        final closingMinute = int.parse(timeParts[1]);
        final closingTime = DateTime(now.year, now.month, now.day, closingHour, closingMinute);
        
        // If current time has passed or equals closing time, today is disabled
        final isDisabled = now.compareTo(closingTime) >= 0;
        print('🔵 Checking if today is disabled: now=$now, closingTime=$closingTime, disabled=$isDisabled');
        return isDisabled;
      }
    } catch (e) {
      print('❌ Error parsing closing time: $e');
    }
    
    return false;
  }

  DateTime _getMinimumSelectableDate() {
    // Always allow today as minimum (closing time check is done in selectableDayPredicate)
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _onConsigneeSearch() {
    final searchTerm = _consigneeController.text.trim();
    if (searchTerm.length >= 2) {
      _searchConsignees(searchTerm);
    } else {
      setState(() {
        _consigneeResults = [];
      });
    }
  }

  void _onConsigneeFocusChange() {
    if (!_consigneeFocusNode.hasFocus) {
      // Clear results when field loses focus
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _consigneeResults = [];
          });
        }
      });
    }
  }

  Future<void> _searchConsignees(String term) async {
    if (!mounted) return;
    setState(() {
      _isSearchingConsignees = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Searching consignees with term: $term');
      final response = await _authService.searchPlaces(
        term: term,
        type: 'consignee',
        token: token,
      );

      if (mounted) {
        setState(() {
          _consigneeResults = response.data;
          _isSearchingConsignees = false;
        });
        print('✅ Consignees found: ${_consigneeResults.length}');
      }
    } catch (e) {
      print('❌ Error searching consignees: $e');
      if (mounted) {
        setState(() {
          _isSearchingConsignees = false;
          _consigneeResults = [];
        });
      }
    }
  }

  Future<void> _searchShippers(String term) async {
    if (!mounted) return;
    setState(() {
      _isSearchingShippers = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Searching shippers with term: $term');
      final response = await _authService.searchPlaces(
        term: term,
        type: 'shipper',
        token: token,
      );

      if (mounted) {
        setState(() {
          _shipperResults = response.data;
          _isSearchingShippers = false;
        });
        print('✅ Shippers found: ${_shipperResults.length}');
      }
    } catch (e) {
      print('❌ Error searching shippers: $e');
      if (mounted) {
        setState(() {
          _isSearchingShippers = false;
          _shipperResults = [];
        });
      }
    }
  }

  Future<void> _handleSaveDimensions() async {
    // Validate dimension fields
    final length = _lengthController.text.trim();
    final breadth = _breadthController.text.trim();
    final height = _heightController.text.trim();
    final weight = _unitWeightController.text.trim();

    if (length.isEmpty || breadth.isEmpty || height.isEmpty || weight.isEmpty) {
      _showErrorDialog('Please fill all dimension fields (Length, Breadth, Height, Weight) before saving.');
      return;
    }

    // Show dialog to get dimension name
    final dimensionName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Dimensions'),
        content: TextField(
          controller: _dimensionNameController,
          decoration: const InputDecoration(
            labelText: 'Dimension Name',
            hintText: 'e.g., Small Box, Carton, etc.',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _dimensionNameController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = _dimensionNameController.text.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.of(context).pop(name);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (dimensionName == null || dimensionName.isEmpty) {
      return; // User cancelled or didn't enter a name
    }

    if (!mounted) return;
    setState(() {
      _isSavingDimension = true;
    });

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        throw Exception('Authentication token or customer ID not found.');
      }

      print('🔵 Saving dimension...');
      final request = SaveDimensionRequest(
        customerId: customer.id,
        dimensionName: dimensionName,
        length: length,
        breadth: breadth,
        height: height,
        weight: weight,
        unitType: 'carton', // Default unit type, can be made configurable later
      );

      final response = await _authService.saveDimension(request, token);

      print('✅ Dimension saved successfully');
      print('✅ Saved Dimension ID: ${response.data.id}');

      if (mounted) {
        setState(() {
          _isSavingDimension = false;
          _dimensionNameController.clear();
        });
        _showSuccessDialog('Dimensions saved successfully!');
        // Reload saved dimensions list
        _loadSavedDimensions();
      }
    } catch (e) {
      print('❌ Error saving dimension: $e');
      if (mounted) {
        setState(() {
          _isSavingDimension = false;
        });
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPickupDate() async {
    print('🔵 Date picker tapped');
    try {
      final minimumDate = _getMinimumSelectableDate();
      print('🔵 Minimum selectable date: $minimumDate');
      
      // Determine initial date - use existing selected date, or find first selectable date
      DateTime initialDate;
      if (_pickupDate != null && !_isDateDisabled(_pickupDate!)) {
        initialDate = _pickupDate!;
      } else {
        // Check if today is selectable
        if (!_isDateDisabled(minimumDate)) {
          initialDate = minimumDate;
        } else {
          // Today is disabled, use tomorrow
          initialDate = minimumDate.add(const Duration(days: 1));
          print('🔵 Today is disabled, using tomorrow as initial date: $initialDate');
        }
      }
      
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: minimumDate,
        lastDate: DateTime.now().add(const Duration(days: 365)),
        selectableDayPredicate: (DateTime date) {
          // Normalize dates to compare only date part (ignore time)
          final dateOnly = DateTime(date.year, date.month, date.day);
          final minDateOnly = DateTime(minimumDate.year, minimumDate.month, minimumDate.day);
          
          // Disable dates before minimum date
          if (dateOnly.isBefore(minDateOnly)) {
            print('🔵 Date $dateOnly is before minimum date $minDateOnly');
            return false;
          }
          // Check if date is disabled based on closing time
          final isDisabled = _isDateDisabled(date);
          if (isDisabled) {
            print('🔵 Date $dateOnly is disabled due to closing time');
          }
          return !isDisabled;
        },
      );
      
      if (picked != null) {
        print('✅ Date selected: $picked');
        setState(() {
          _pickupDate = picked;
          _pickupDateController.text = _formatPickupDate(picked);
        });
      } else {
        print('❌ Date picker cancelled or no date selected');
      }
    } catch (e) {
      print('❌ Error in date picker: $e');
      _showErrorDialog('Alert: Issue selecting date: ${e.toString()}');
    }
  }

  String _formatPickupDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> _selectConsigneeClosingTime() async {
    print('🔵 Consignee closing time picker tapped');
    try {
      // Parse current time from controller or use default
      TimeOfDay initialTime = const TimeOfDay(hour: 11, minute: 30);
      if (_consigneeClosingTimeController.text.isNotEmpty) {
        final parts = _consigneeClosingTimeController.text.split(':');
        if (parts.length >= 2) {
          try {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            initialTime = TimeOfDay(hour: hour, minute: minute);
          } catch (e) {
            print('⚠️ Error parsing current time, using default: $e');
          }
        }
      }

      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        },
      );

      if (picked != null) {
        print('✅ Time selected: ${picked.hour}:${picked.minute}');
        setState(() {
          _consigneeClosingTimeController.text = 
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        });
      } else {
        print('❌ Time picker cancelled or no time selected');
      }
    } catch (e) {
      print('❌ Error in time picker: $e');
      _showErrorDialog('Alert: Issue selecting time: ${e.toString()}');
    }
  }

  Future<void> _handleDeleteDimension(SavedDimension dimension) async {
    // Set flag to prevent dropdown selection
    _isDeletingFromDropdown = true;
    
    // Show confirmation dialog
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dimension'),
        content: Text(
          'Are you sure you want to delete "${dimension.dimensionName}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete != true) {
      // Reset flag if cancelled
      _isDeletingFromDropdown = false;
      return; // User cancelled
    }

    if (!mounted) return;
    setState(() {
      _isDeletingDimension = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Deleting dimension: ${dimension.id}');
      await _authService.deleteSavedDimension(dimension.id, token);

      print('✅ Dimension deleted successfully');

      if (mounted) {
        setState(() {
          _isDeletingDimension = false;
          _isDeletingFromDropdown = false;
          // Clear selection if the deleted dimension was selected
          if (_selectedSavedDimension == dimension.id) {
            _selectedSavedDimension = null;
            // Clear dimension fields
            _lengthController.clear();
            _breadthController.clear();
            _heightController.clear();
            _unitWeightController.clear();
            _unitsController.clear();
          }
        });
        _showSuccessDialog('Dimension "${dimension.dimensionName}" deleted successfully!');
        // Reload saved dimensions list
        _loadSavedDimensions();
      }
    } catch (e) {
      print('❌ Error deleting dimension: $e');
      if (mounted) {
        setState(() {
          _isDeletingDimension = false;
          _isDeletingFromDropdown = false;
        });
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _loadSavedDimensions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSavedDimensions = true;
    });

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        throw Exception('Authentication token or customer ID not found.');
      }

      print('🔵 Fetching saved dimensions for customer: ${customer.id}');
      final response = await _authService.getSavedDimensions(customer.id, token);

      if (mounted) {
        setState(() {
          _savedDimensions = response.data;
          _isLoadingSavedDimensions = false;
        });
        print('✅ Saved dimensions loaded: ${_savedDimensions.length}');
      }
    } catch (e) {
      print('❌ Error loading saved dimensions: $e');
      if (mounted) {
        setState(() {
          _isLoadingSavedDimensions = false;
        });
      }
    }
  }

  Future<void> _loadBlockedKeywords() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBlockedKeywords = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Fetching blocked keywords...');
      final response = await _authService.getBlockedKeywords(token);

      if (mounted) {
        setState(() {
          _blockedKeywords = response.data;
          _isLoadingBlockedKeywords = false;
        });
        print('✅ Blocked keywords loaded: ${_blockedKeywords.length}');
      }
    } catch (e) {
      print('❌ Error loading blocked keywords: $e');
      if (mounted) {
        setState(() {
          _isLoadingBlockedKeywords = false;
        });
      }
    }
  }

  bool _isCommodityBlocked(Commodity commodity) {
    if (_blockedKeywords.isEmpty) return false;
    final commodityNameLower = commodity.name.toLowerCase();
    return _blockedKeywords.any((keyword) => 
      commodityNameLower.contains(keyword.toLowerCase())
    );
  }

  Future<void> _loadDiscountCoupons() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCoupons = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Fetching discount coupons...');
      final response = await _authService.getDiscountCoupons(token);

      if (mounted) {
        setState(() {
          _discountCoupons = response.data;
          _isLoadingCoupons = false;
        });
        print('✅ Discount coupons loaded: ${_discountCoupons.length}');
        // Log valid coupons
        final validCoupons = _discountCoupons.where((c) => c.isValid).toList();
        print('✅ Valid coupons: ${validCoupons.length}');
      }
    } catch (e) {
      print('❌ Error loading discount coupons: $e');
      if (mounted) {
        setState(() {
          _isLoadingCoupons = false;
        });
      }
    }
  }

  Future<void> _validateCoupon() async {
    final couponCode = _couponCodeController.text.trim().toUpperCase();
    
    if (couponCode.isEmpty) {
      _showErrorDialog('Please enter a coupon code');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isValidatingCoupon = true;
    });

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        throw Exception('Authentication token or customer ID not found.');
      }

      // Calculate order amount (pre-tax amount without coupon discount)
      // Use stored _preTaxAmount if available, and add back any existing coupon discount
      double orderAmount = 0.0;
      
      if (_preTaxAmount > 0) {
        // Use the stored pre-tax amount and add back coupon discount if one is already applied
        orderAmount = _preTaxAmount;
        if (_appliedCouponCode != null && _couponDiscountAmount != null) {
          final existingDiscount = double.tryParse(_couponDiscountAmount!) ?? 0;
          orderAmount += existingDiscount; // Add back the discount to get pre-coupon amount
        }
        print('🔵 Using stored pre-tax amount: $_preTaxAmount, order amount for validation: $orderAmount');
      } else {
        // Recalculate if _preTaxAmount is not available
        if (_pricingType == 'Dynamic Price') {
          // Calculate pre-tax amount for dynamic pricing
          if (_transportAmount <= 0 || _dynamicPriceConfig == null) {
            _showErrorDialog('Please calculate transportation charges first by entering dimensions');
            if (mounted) {
              setState(() {
                _isValidatingCoupon = false;
              });
            }
            return;
          }
          
          orderAmount = _transportAmount;
          
          // Add express delivery surcharge
          if (_expressDelivery) {
            orderAmount += _transportAmount * (_dynamicPriceConfig!.expressDeliverySurchargePercentage / 100);
          }
          
          // Add challan return charges
          if (_challanReturn) {
            orderAmount += _dynamicPriceConfig!.chalaanReturnCharges;
          }
          
          // Add COD charges
          if (_collectCOD) {
            final codAmount = double.tryParse(_codAmountController.text) ?? 0;
            if (codAmount > 0) {
              final codSlab = _dynamicPriceConfig!.codRanges.firstWhere(
                (slab) => codAmount >= slab.range[0] && codAmount <= slab.range[1],
                orElse: () => _dynamicPriceConfig!.codRanges.first,
              );
              orderAmount += codSlab.charge;
            }
          }
        } else {
          // Fixed Price - calculate pre-tax amount
          if (_dimensionList.isEmpty) {
            _showErrorDialog('Please add at least one dimension first');
            if (mounted) {
              setState(() {
                _isValidatingCoupon = false;
              });
            }
            return;
          }
          
          // Find first dimension with selected dimension
          final firstDimWithSelection = _dimensionList.firstWhere(
            (d) => d.selectedDimension != null,
            orElse: () => _dimensionList.first,
          );
          
          if (firstDimWithSelection.selectedDimension == null) {
            _showErrorDialog('Please select a dimension for at least one entry');
            if (mounted) {
              setState(() {
                _isValidatingCoupon = false;
              });
            }
            return;
          }
          
          final dimension = firstDimWithSelection.selectedDimension!;
          double transportAmount = 0.0;
          
          // Calculate total transport amount from all dimensions
          for (var dim in _dimensionList) {
            if (dim.selectedDimension != null) {
              final dimCharge = double.tryParse(dim.selectedDimension!.dimensionCharge) ?? 0;
              transportAmount += dimCharge;
            }
          }
          
          if (transportAmount <= 0) {
            _showErrorDialog('Please select valid dimensions with charges');
            if (mounted) {
              setState(() {
                _isValidatingCoupon = false;
              });
            }
            return;
          }
          
          orderAmount = transportAmount;
          
          // Add express delivery surcharge
          if (_expressDelivery) {
            final expressPercentage = double.tryParse(dimension.expressDeliveryPercentage) ?? 0;
            orderAmount += transportAmount * (expressPercentage / 100);
          }
          
          // Add challan return charges
          if (_challanReturn) {
            final challanCharges = double.tryParse(dimension.chalaanReturnCharges) ?? 0;
            orderAmount += challanCharges;
          }
          
          // Add COD charges
          if (_collectCOD) {
            final codAmount = double.tryParse(_codAmountController.text) ?? 0;
            if (codAmount > 0) {
              String? codCharge;
              if (dimension.codRange1 != null && codAmount >= dimension.codRange1!.min && codAmount <= dimension.codRange1!.max) {
                codCharge = dimension.codCharge1;
              } else if (dimension.codRange2 != null && codAmount >= dimension.codRange2!.min && codAmount <= dimension.codRange2!.max) {
                codCharge = dimension.codCharge2;
              } else if (dimension.codRange3 != null && codAmount >= dimension.codRange3!.min && codAmount <= dimension.codRange3!.max) {
                codCharge = dimension.codCharge3;
              } else if (dimension.codRange4 != null && codAmount >= dimension.codRange4!.min && codAmount <= dimension.codRange4!.max) {
                codCharge = dimension.codCharge4;
              } else if (dimension.codRange5 != null && codAmount >= dimension.codRange5!.min && codAmount <= dimension.codRange5!.max) {
                codCharge = dimension.codCharge5;
              } else if (dimension.codRange6 != null && codAmount >= dimension.codRange6!.min && codAmount <= dimension.codRange6!.max) {
                codCharge = dimension.codCharge6;
              }
              if (codCharge != null) {
                orderAmount += double.tryParse(codCharge) ?? 0;
              }
            }
          }
        }
      }

      if (orderAmount <= 0) {
        _showErrorDialog('Please enter valid dimensions and calculate charges first');
        if (mounted) {
          setState(() {
            _isValidatingCoupon = false;
          });
        }
        return;
      }

      // Calculate final payable amount (pre-tax + GST) for minimum order value check
      // The backend should check minimum order value against the final amount customer pays
      double finalPayableForValidation = orderAmount;
      
      // Add GST to get the final payable amount
      if (_pricingType == 'Dynamic Price' && _dynamicPriceConfig != null) {
        final gstPercentage = _dynamicPriceConfig!.gstPercentage;
        final gstAmount = orderAmount * (gstPercentage / 100);
        finalPayableForValidation = orderAmount + gstAmount;
      } else if (_pricingType == 'Fixed Price' && _dimensionList.isNotEmpty) {
        final firstDimWithSelection = _dimensionList.firstWhere(
          (d) => d.selectedDimension != null,
          orElse: () => _dimensionList.first,
        );
        if (firstDimWithSelection.selectedDimension != null) {
          final dimension = firstDimWithSelection.selectedDimension!;
          final gstPercentage = double.tryParse(dimension.gstPercentage) ?? 18.0;
          final gstAmount = orderAmount * (gstPercentage / 100);
          finalPayableForValidation = orderAmount + gstAmount;
        }
      }
      
      print('🔵 Validating coupon: $couponCode');
      print('🔵 Order amount (pre-tax): $orderAmount');
      print('🔵 Final payable for validation: $finalPayableForValidation');
      
      // Send final payable amount for minimum order value check
      final response = await _authService.validateCoupon(
        couponCode: couponCode,
        customerId: customer.id,
        orderAmount: finalPayableForValidation,
        token: token,
      );

      if (mounted) {
        setState(() {
          _isValidatingCoupon = false;
        });

        if (response.success && response.data != null) {
          // Coupon is valid - calculate discount amount based on coupon type
          final couponData = response.data!;
          double calculatedDiscount = 0;
          
          // Calculate discount based on type (same logic as website)
          // Use pre-tax orderAmount (Transport + Express + Challan + COD) for discount calculation
          if (couponData.discountType.toLowerCase() == 'percentage') {
            // Percentage discount
            final discountPercent = double.tryParse(couponData.discountValue) ?? 0;
            final maxCap = couponData.maxDiscountCap != null 
                ? double.tryParse(couponData.maxDiscountCap!) 
                : null;
            
            calculatedDiscount = orderAmount * (discountPercent / 100);
            
            // Apply max cap if exists
            if (maxCap != null && calculatedDiscount > maxCap) {
              calculatedDiscount = maxCap;
            }
            
            // Ensure discount doesn't exceed order amount
            if (calculatedDiscount > orderAmount) {
              calculatedDiscount = orderAmount;
            }
          } else {
            // Fixed discount
            calculatedDiscount = double.tryParse(couponData.discountValue) ?? 0;
            
            // Ensure discount doesn't exceed order amount
            if (calculatedDiscount > orderAmount) {
              calculatedDiscount = orderAmount;
            }
          }
          
          // Use calculated discount (API's discountAmount might be 0)
          final finalDiscount = calculatedDiscount.toStringAsFixed(2);
          
          setState(() {
            _appliedCouponCode = couponCode;
            _couponDiscountAmount = finalDiscount;
            _isValidatingCoupon = false;
          });
          
          print('🔵 Coupon applied: $couponCode');
          print('🔵 Discount type: ${couponData.discountType}');
          print('🔵 Discount value: ${couponData.discountValue}');
          print('🔵 Order amount (pre-tax): ₹$orderAmount');
          print('🔵 Calculated discount: ₹$calculatedDiscount');
          print('🔵 Final discount: ₹$finalDiscount');
          
          // Trigger recalculation after coupon is applied
          Future.microtask(() {
            if (_pricingType == 'Fixed Price') {
              _calculateFixedPrice();
            } else {
              _calculatePrice();
            }
          });
          _showSuccessDialog('Coupon applied successfully! Discount: ₹$finalDiscount');
        } else {
          // Coupon validation failed
          setState(() {
            _appliedCouponCode = null;
            _couponDiscountAmount = null;
            _isValidatingCoupon = false;
          });
          _showErrorDialog(response.message);
        }
      }
    } catch (e) {
      print('❌ Error validating coupon: $e');
      if (mounted) {
        setState(() {
          _isValidatingCoupon = false;
          _appliedCouponCode = null;
          _couponDiscountAmount = null;
        });
        _showErrorDialog('Failed to validate coupon: ${e.toString()}');
      }
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _couponDiscountAmount = null;
      _couponCodeController.clear();
    });
    // Trigger recalculation after coupon is removed
    Future.microtask(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      } else {
        _calculatePrice();
      }
    });
  }

  Future<void> _pickChallanFiles() async {
    try {
      // Show option to choose between camera and gallery
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

      if (source == null) return;

      if (source == ImageSource.camera) {
        // Pick single image from camera
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1600,
        );
        if (pickedFile != null) {
          setState(() {
            _challanFilePaths.add(pickedFile.path);
          });
          _showSuccessDialog('1 file(s) added. Total: ${_challanFilePaths.length} file(s)');
        }
      } else {
        // Pick multiple images from gallery
        final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1600,
        );
        if (pickedFiles.isNotEmpty) {
          setState(() {
            // Append new files to existing list instead of replacing
            _challanFilePaths.addAll(pickedFiles.map((file) => file.path).toList());
          });
          _showSuccessDialog('${pickedFiles.length} file(s) added. Total: ${_challanFilePaths.length} file(s)');
        }
      }
    } catch (e) {
      print('❌ Error picking files: $e');
      _showErrorDialog('Failed to pick files: ${e.toString()}');
    }
  }

  void _removeChallanFile(int index) {
    setState(() {
      _challanFilePaths.removeAt(index);
    });
  }

  Future<void> _loadActiveDynamicPrice() async {
    if (_pricingType != 'Dynamic Price') return;
    
    setState(() {
      _isLoadingDynamicPrice = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Fetching active dynamic price configuration...');
      final response = await _authService.getActiveDynamicPrice(token);

      if (mounted) {
        setState(() {
          _dynamicPriceConfig = response.data;
          _isLoadingDynamicPrice = false;
        });
        print('✅ Dynamic price configuration loaded');
        print('   Base fare per kg: ${response.data.baseFarePerKg}');
        print('   Volumetric factor: ${response.data.volumetricFactor}');
        print('   Express delivery surcharge percentage: ${response.data.expressDeliverySurchargePercentage}');
        print('   Challan return charges: ${response.data.chalaanReturnCharges}');
        print('   GST percentage: ${response.data.gstPercentage}');
        
        // Recalculate price with new configuration
        _calculatePrice();
      }
    } catch (e) {
      print('❌ Error loading dynamic price configuration: $e');
      if (mounted) {
        setState(() {
          _isLoadingDynamicPrice = false;
        });
      }
    }
  }

  void _calculatePrice() {
    if (_pricingType != 'Dynamic Price' || _dynamicPriceConfig == null) {
      return;
    }

    // Declare variables outside if/else blocks
    double totalUnitsCalc = 0;
    double totalVolumetricWeight = 0;
    double totalGrossWeight = 0;
    double totalVolumeCalc = 0;
    double chargeableWt = 0;
    double transportAmount = 0;

    // Check if using multiple dimensions or single dimension
    if (_dynamicDimensionList.isNotEmpty) {
      // Calculate from multiple dimensions
      double totalChargeableWt = 0;

      for (var dimData in _dynamicDimensionList) {
        final length = double.tryParse(dimData.lengthController.text) ?? 0;
        final breadth = double.tryParse(dimData.breadthController.text) ?? 0;
        final height = double.tryParse(dimData.heightController.text) ?? 0;
        final units = int.tryParse(dimData.unitsController.text) ?? 1;
        final perUnitWeight = double.tryParse(dimData.unitWeightController.text) ?? 0;

        if (length <= 0 || breadth <= 0 || height <= 0 || units <= 0) continue;

        final volumetricWeightPerUnit = (length * breadth * height) / _dynamicPriceConfig!.volumetricFactor;
        final dimVolumetricWeight = volumetricWeightPerUnit * units;
        final dimGrossWeight = perUnitWeight * units;
        final dimVolume = length * breadth * height * units;
        final dimChargeableWt = dimGrossWeight > dimVolumetricWeight ? dimGrossWeight : dimVolumetricWeight;

        totalUnitsCalc += units.toDouble();
        totalVolumetricWeight += dimVolumetricWeight;
        totalGrossWeight += dimGrossWeight;
        totalVolumeCalc += dimVolume;
        totalChargeableWt += dimChargeableWt;
      }

      // Calculate transport charges (base amount)
      chargeableWt = totalChargeableWt;
      transportAmount = totalChargeableWt * _dynamicPriceConfig!.baseFarePerKg;
    } else {
      // Fallback to single dimension (using old controllers)
    final length = double.tryParse(_lengthController.text) ?? 0;
    final breadth = double.tryParse(_breadthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final units = int.tryParse(_unitsController.text) ?? 1;
    final perUnitWeight = double.tryParse(_unitWeightController.text) ?? 0;

    // Calculate totals
      totalUnitsCalc = units.toDouble();
    final volumetricWeightPerUnit = (length * breadth * height) / _dynamicPriceConfig!.volumetricFactor;
      totalVolumetricWeight = volumetricWeightPerUnit * units;
      totalGrossWeight = perUnitWeight * units;
      totalVolumeCalc = length * breadth * height * units;

    // Chargeable weight is the maximum of gross weight and volumetric weight
      chargeableWt = totalGrossWeight > totalVolumetricWeight ? totalGrossWeight : totalVolumetricWeight;

    // Calculate transport charges (base amount)
      transportAmount = chargeableWt * _dynamicPriceConfig!.baseFarePerKg;
    }

    // Update state with calculated values
    if (mounted) {
      setState(() {
        _totalUnits = totalUnitsCalc;
        _totalGrossWeight = totalGrossWeight;
        _totalVolumetricWeight = totalVolumetricWeight;
        _totalVolume = totalVolumeCalc;
        _chargeableWeight = chargeableWt;
        _transportAmount = transportAmount;
      });
    }

    // Dynamic Price calculation flow (as per specification):
    // 1. Transport Charges (A)
    // 2. Add Physical POD Charge (B) and COD Charges (C)
    // 3. Apply Coupon Discount (D) on Transport Charges ONLY
    // 4. Sub Total (E) = A + B + C - D
    // 5. Express Charges (F) = percentage of original Transport (A)
    // 6. Gross Payable (G) = E + F
    // 7. GST (H) = percentage of G
    // 8. Final Payable (I) = G + H
    
    // Use the already calculated transport amount
    // transportAmount is already calculated above and stored in _transportAmount
    
    // Add Physical POD charges (B)
    double podCharges = 0;
    if (_challanReturn) {
      podCharges = _dynamicPriceConfig!.chalaanReturnCharges;
      print('🔵 Dynamic Price - Physical POD charges: ₹${podCharges}');
    }

    // Add COD charges (C)
    double codCharges = 0;
    if (_collectCOD) {
      final codAmount = double.tryParse(_codAmountController.text) ?? 0;
      if (codAmount > 0) {
        // Find applicable COD slab
        final codSlab = _dynamicPriceConfig!.codRanges.firstWhere(
          (slab) => codAmount >= slab.range[0] && codAmount <= slab.range[1],
          orElse: () => _dynamicPriceConfig!.codRanges.first,
        );
        codCharges = codSlab.charge;
        print('🔵 Dynamic Price - COD charges: ₹${codCharges} for COD amount: ₹${codAmount}');
        print('   COD slab range: ${codSlab.range[0]}-${codSlab.range[1]}');
      }
    }

    // Apply coupon discount (D) - applied ONLY on Transport Charges
    double couponDiscount = 0;
    if (_appliedCouponCode != null && _couponDiscountAmount != null) {
      couponDiscount = double.tryParse(_couponDiscountAmount!) ?? 0;
      // Ensure discount doesn't exceed transport amount
      if (couponDiscount > transportAmount) {
        couponDiscount = transportAmount;
      }
      print('🔵 Dynamic Price - Coupon discount: ₹${couponDiscount} (applied on Transport Charges only)');
    }

    // Sub Total (E) = Transport + POD + COD - Coupon
    final subTotalBeforeDiscount = transportAmount + podCharges + codCharges;
    double subTotal = subTotalBeforeDiscount - couponDiscount;
    if (subTotal < 0) {
      subTotal = 0; // Safety check
    }

    // Calculate Express Charges (F) = percentage of original Transport (A)
    double expressCharges = 0;
    if (_expressDelivery) {
      final expressPercentage = _dynamicPriceConfig!.expressDeliverySurchargePercentage;
      expressCharges = transportAmount * (expressPercentage / 100);
      print('🔵 Dynamic Price - Express delivery surcharge: ${expressPercentage}% of ${transportAmount} = ${expressCharges}');
    }

    // Gross Payable (G) = Sub Total + Express Charges
    final grossPayable = subTotal + expressCharges;

    // Calculate GST (H) = percentage of Gross Payable (G)
    final gstAmountRaw = grossPayable * (_dynamicPriceConfig!.gstPercentage / 100);
    final gstAmount = double.parse(gstAmountRaw.toStringAsFixed(2));
    
    // Final Payable (I) = Gross Payable + GST
    final finalPayable = _roundFinalPayable(grossPayable + gstAmount);
    
    // Store values for display and consistency
    double preTaxAmount = grossPayable;

    if (mounted) {
      setState(() {
        _totalUnits = totalUnitsCalc;
        _totalGrossWeight = totalGrossWeight;
        _totalVolumetricWeight = totalVolumetricWeight;
        _totalVolume = totalVolumeCalc;
        _chargeableWeight = chargeableWt;
        _transportAmount = transportAmount;
        _subTotalBeforeDiscount = subTotalBeforeDiscount;
        _subTotalAfterDiscount = subTotal;
        _expressCharges = expressCharges;
        _preTaxAmount = preTaxAmount;
        _gstAmount = gstAmount;
        _finalPayable = finalPayable;
        
        // Update charges controller
        _chargesController.text = transportAmount.toStringAsFixed(2);
        _totalWeightController.text = chargeableWt.toStringAsFixed(2);
      });
    }
  }

  void _calculateFixedPrice() {
    if (_pricingType != 'Fixed Price' || _dimensionList.isEmpty) {
      // Reset totals if no dimensions
      if (mounted) {
        setState(() {
          _totalUnits = 0;
          _totalGrossWeight = 0;
          _totalVolumetricWeight = 0;
          _totalVolume = 0;
          _chargeableWeight = 0;
          _transportAmount = 0;
          _preTaxAmount = 0;
      _subTotalBeforeDiscount = 0;
      _expressCharges = 0;
          _subTotalBeforeDiscount = 0;
      _expressCharges = 0;
          _expressCharges = 0;
          _gstAmount = 0;
          _finalPayable = 0;
        });
      }
      return;
    }
    
    // Check if at least one dimension has a selected dimension
    final hasValidDimension = _dimensionList.any((d) => d.selectedDimension != null);
    if (!hasValidDimension) {
      // Reset totals if no valid dimensions
      if (mounted) {
        setState(() {
          _totalUnits = 0;
          _totalGrossWeight = 0;
          _totalVolumetricWeight = 0;
          _totalVolume = 0;
          _chargeableWeight = 0;
          _transportAmount = 0;
          _preTaxAmount = 0;
      _subTotalBeforeDiscount = 0;
      _expressCharges = 0;
          _subTotalBeforeDiscount = 0;
      _expressCharges = 0;
          _expressCharges = 0;
          _gstAmount = 0;
          _finalPayable = 0;
        });
      }
      return;
    }

    // Sum all dimensions
    double totalUnitsCalc = 0;
    double totalVolumetricWeight = 0;
    double totalGrossWeight = 0;
    double totalVolumeCalc = 0;
    double totalChargeableWt = 0;
    double totalTransportAmount = 0;

    for (var dimData in _dimensionList) {
      if (dimData.selectedDimension == null) continue;
      
      final dimension = dimData.selectedDimension!;
      final length = double.tryParse(dimData.lengthController.text) ?? 0;
      final breadth = double.tryParse(dimData.breadthController.text) ?? 0;
      final height = double.tryParse(dimData.heightController.text) ?? 0;
      final units = int.tryParse(dimData.unitsController.text) ?? 1;
      final perUnitWeight = double.tryParse(dimData.unitWeightController.text) ?? 0;

      // Calculate for this dimension
      final volumetricFactor = double.tryParse(dimension.volumetricFactor) ?? 6000;
      final volumetricWeightPerUnit = (length * breadth * height) / volumetricFactor;
      final dimVolumetricWeight = volumetricWeightPerUnit * units;
      final dimGrossWeight = perUnitWeight * units;
      final dimVolume = length * breadth * height * units;
      final dimChargeableWt = dimGrossWeight > dimVolumetricWeight ? dimGrossWeight : dimVolumetricWeight;

      // Calculate base fare per kg for this dimension
      final dimensionCharge = double.tryParse(dimension.dimensionCharge) ?? 0;
      final dimensionWeight = double.tryParse(dimension.weight) ?? 0;
      final dimensionLength = double.tryParse(dimension.length) ?? 0;
      final dimensionBreadth = double.tryParse(dimension.breadth) ?? 0;
      final dimensionHeight = double.tryParse(dimension.height) ?? 0;
      
      final expectedVolumetricWeight = (dimensionLength * dimensionBreadth * dimensionHeight) / volumetricFactor;
      final expectedChargeableWt = dimensionWeight > expectedVolumetricWeight ? dimensionWeight : expectedVolumetricWeight;
      final baseFarePerKg = expectedChargeableWt > 0 ? (dimensionCharge / expectedChargeableWt) : dimensionCharge;
      
      // Calculate transport amount for this dimension
      final dimTransportAmount = dimChargeableWt * baseFarePerKg;

      // Sum totals
      totalUnitsCalc += units.toDouble();
      totalVolumetricWeight += dimVolumetricWeight;
      totalGrossWeight += dimGrossWeight;
      totalVolumeCalc += dimVolume;
      totalChargeableWt += dimChargeableWt;
      totalTransportAmount += dimTransportAmount;
    }

    // Use the first dimension's settings for express, challan, COD (or use the selected one if available)
    final firstDimension = _dimensionList.firstWhere((d) => d.selectedDimension != null, orElse: () => _dimensionList.first);
    if (firstDimension.selectedDimension == null) {
      return;
    }
    final dimension = firstDimension.selectedDimension!;

    double transportAmount = totalTransportAmount;
    
    // Fixed Price calculation flow (as per specification):
    // 1. Transport Charges (A)
    // 2. Add Challan Return (B) and COD Charges (C)
    // 3. Apply Coupon Discount (D) on Transport Charges
    // 4. Sub Total (E) = A + B + C - D
    // 5. Express Charges (F) = percentage of original Transport (A)
    // 6. Gross Payable (G) = E + F
    // 7. GST (H) = percentage of G
    // 8. Final Payable (I) = G + H
    
    // Start with transport charges
    double preTaxAmount = transportAmount;

    // Add challan return charges (B)
    if (_challanReturn) {
      final challanCharges = double.tryParse(dimension.chalaanReturnCharges) ?? 0;
      print('🔵 Fixed Price - Challan return charges: ₹${challanCharges}');
      print('   Dimension: ${dimension.dimensionName}, chalaanReturnCharges from API: ${dimension.chalaanReturnCharges}');
      preTaxAmount += challanCharges;
    }

    // Add COD charges (C)
    if (_collectCOD) {
      final codAmount = double.tryParse(_codAmountController.text) ?? 0;
      if (codAmount > 0) {
        // Find applicable COD charge from dimension
        String? codCharge;
        if (dimension.codRange1 != null && 
            codAmount >= dimension.codRange1!.min && 
            codAmount <= dimension.codRange1!.max) {
          codCharge = dimension.codCharge1;
          print('🔵 Fixed Price - COD charge from range1: ${dimension.codRange1!.min}-${dimension.codRange1!.max}');
        } else if (dimension.codRange2 != null && 
                   codAmount >= dimension.codRange2!.min && 
                   codAmount <= dimension.codRange2!.max) {
          codCharge = dimension.codCharge2;
          print('🔵 Fixed Price - COD charge from range2: ${dimension.codRange2!.min}-${dimension.codRange2!.max}');
        } else if (dimension.codRange3 != null && 
                   codAmount >= dimension.codRange3!.min && 
                   codAmount <= dimension.codRange3!.max) {
          codCharge = dimension.codCharge3;
          print('🔵 Fixed Price - COD charge from range3: ${dimension.codRange3!.min}-${dimension.codRange3!.max}');
        } else if (dimension.codRange4 != null && 
                   codAmount >= dimension.codRange4!.min && 
                   codAmount <= dimension.codRange4!.max) {
          codCharge = dimension.codCharge4;
          print('🔵 Fixed Price - COD charge from range4: ${dimension.codRange4!.min}-${dimension.codRange4!.max}');
        } else if (dimension.codRange5 != null && 
                   codAmount >= dimension.codRange5!.min && 
                   codAmount <= dimension.codRange5!.max) {
          codCharge = dimension.codCharge5;
          print('🔵 Fixed Price - COD charge from range5: ${dimension.codRange5!.min}-${dimension.codRange5!.max}');
        } else if (dimension.codRange6 != null && 
                   codAmount >= dimension.codRange6!.min && 
                   codAmount <= dimension.codRange6!.max) {
          codCharge = dimension.codCharge6;
          print('🔵 Fixed Price - COD charge from range6: ${dimension.codRange6!.min}-${dimension.codRange6!.max}');
        }
        
        if (codCharge != null) {
          final codCharges = double.tryParse(codCharge) ?? 0;
          print('🔵 Fixed Price - COD charges: ₹${codCharges} for COD amount: ₹${codAmount}');
          print('   Dimension: ${dimension.dimensionName}');
          preTaxAmount += codCharges;
        } else {
          print('⚠️ Fixed Price - No COD charge found for amount: ₹${codAmount}');
        }
      }
    }

    // Apply coupon discount (D) - applied on transport charges
    double couponDiscount = 0;
    if (_appliedCouponCode != null && _couponDiscountAmount != null) {
      couponDiscount = double.tryParse(_couponDiscountAmount!) ?? 0;
      preTaxAmount = preTaxAmount - couponDiscount;
      if (preTaxAmount < 0) preTaxAmount = 0;
    }

    // Store Sub Total (E) = A + B + C - D
    final subTotalBeforeDiscount = preTaxAmount;

    // Calculate Express Charges (F) = percentage of original Transport (A)
    double expressCharges = 0;
    if (_expressDelivery) {
      final expressPercentage = double.tryParse(dimension.expressDeliveryPercentage) ?? 0;
      expressCharges = transportAmount * (expressPercentage / 100);
      print('🔵 Fixed Price - Express delivery surcharge: ${expressPercentage}% of ${transportAmount} = ${expressCharges}');
      print('   Dimension: ${dimension.dimensionName}, expressDeliveryPercentage from API: ${dimension.expressDeliveryPercentage}');
    }

    // Gross Payable (G) = Sub Total + Express Charges
    final grossPayable = subTotalBeforeDiscount + expressCharges;

    // Calculate GST (H) = percentage of Gross Payable (G)
    final gstPercentage = double.tryParse(dimension.gstPercentage) ?? 18.0;
    final gstAmountRaw = grossPayable * (gstPercentage / 100);
    final gstAmount = double.parse(gstAmountRaw.toStringAsFixed(2));
    
    // Final Payable (I) = Gross Payable + GST
    final finalPayable = _roundFinalPayable(grossPayable + gstAmount);
    
    // Store preTaxAmount as grossPayable for consistency with existing code
    preTaxAmount = grossPayable;

    if (mounted) {
      setState(() {
        _totalUnits = totalUnitsCalc;
        _totalGrossWeight = totalGrossWeight;
        _totalVolumetricWeight = totalVolumetricWeight;
        _totalVolume = totalVolumeCalc;
        _chargeableWeight = totalChargeableWt;
        _transportAmount = transportAmount;
        _subTotalBeforeDiscount = subTotalBeforeDiscount;
        _expressCharges = expressCharges;
        _preTaxAmount = preTaxAmount;
        _gstAmount = gstAmount;
        _finalPayable = finalPayable;
      });
    }
  }

  // Round final payable: if decimal < 0.50 round down, if >= 0.50 round up
  double _roundFinalPayable(double value) {
    final decimalPart = value - value.floor();
    if (decimalPart < 0.50) {
      return value.floor().toDouble();
    } else {
      return value.ceil().toDouble();
    }
  }

  double _calculateVolumetricWeight(double length, double breadth, double height) {
    if (_pricingType == 'Fixed Price' && _dimensionList.isNotEmpty) {
      // Use first dimension's volumetric factor if available
      final firstDim = _dimensionList.firstWhere(
        (d) => d.selectedDimension != null,
        orElse: () => _dimensionList.first,
      );
      if (firstDim.selectedDimension != null) {
        final volumetricFactor = double.tryParse(firstDim.selectedDimension!.volumetricFactor) ?? 6000;
        return (length * breadth * height) / volumetricFactor;
      }
      // Default to 6000 if no dimension selected
      return (length * breadth * height) / 6000;
    }
    if (_dynamicPriceConfig == null) {
      // Default to 5000 if config not loaded
    return (length * breadth * height) / 5000;
    }
    return (length * breadth * height) / _dynamicPriceConfig!.volumetricFactor;
  }

  double _calculateTotalVolume(double length, double breadth, double height, int units) {
    return length * breadth * height * units;
  }
  
  // Get available dimensions for a specific dimension card (exclude already selected ones)
  List<FixedPriceDimension> _getAvailableDimensions(DimensionData currentDimension) {
    // Get IDs of dimensions already selected in other cards
    final selectedIds = _dimensionList
        .where((d) => d.id != currentDimension.id && d.selectedDimension != null)
        .map((d) => d.selectedDimension!.id)
        .toSet();
    
    // Filter out already selected dimensions, but include the current dimension's selection
    return _fixedPriceDimensions.where((dim) {
      // Include if not selected in other cards, or if it's the current dimension's selection
      return !selectedIds.contains(dim.id) || dim.id == currentDimension.selectedDimension?.id;
    }).toList();
  }

  // Check if all dimensions from backend are already selected
  bool _areAllDimensionsSelected() {
    if (_fixedPriceDimensions.isEmpty) return false;
    
    // Get all unique selected dimension IDs
    final selectedIds = _dimensionList
        .where((d) => d.selectedDimension != null)
        .map((d) => d.selectedDimension!.id)
        .toSet();
    
    // Check if all backend dimensions are selected
    return selectedIds.length >= _fixedPriceDimensions.length;
  }
  
  void _addNewDimension() {
    if (_dimensionList.length >= 10) {
      _showErrorDialog('Maximum 10 dimensions allowed');
      return;
    }
    
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final dimension = DimensionData(
      id: newId,
      lengthController: TextEditingController(),
      breadthController: TextEditingController(),
      heightController: TextEditingController(),
      unitsController: TextEditingController(text: '1'),
      unitWeightController: TextEditingController(),
      chargesController: TextEditingController(),
    );
    
    // Add listeners for auto-calculation
    dimension.lengthController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      }
    });
    dimension.breadthController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      }
    });
    dimension.heightController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      }
    });
    dimension.unitsController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      }
    });
    dimension.unitWeightController.addListener(() {
      if (_pricingType == 'Fixed Price') {
        _calculateFixedPrice();
      }
    });
    
    setState(() {
      _dimensionList.add(dimension);
    });
  }
  
  void _addNewDynamicDimension() {
    if (_dynamicDimensionList.length >= 10) {
      _showErrorDialog('Maximum 10 dimensions allowed');
      return;
    }
    
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final dimension = DimensionData(
      id: newId,
      lengthController: TextEditingController(),
      breadthController: TextEditingController(),
      heightController: TextEditingController(),
      unitsController: TextEditingController(text: '1'),
      unitWeightController: TextEditingController(),
      chargesController: TextEditingController(),
    );
    
    // Add listeners for auto-calculation
    dimension.lengthController.addListener(() {
      if (_pricingType == 'Dynamic Price') {
        _calculatePrice();
      }
    });
    dimension.breadthController.addListener(() {
      if (_pricingType == 'Dynamic Price') {
        _calculatePrice();
      }
    });
    dimension.heightController.addListener(() {
      if (_pricingType == 'Dynamic Price') {
        _calculatePrice();
      }
    });
    dimension.unitsController.addListener(() {
      if (_pricingType == 'Dynamic Price') {
        _calculatePrice();
      }
    });
    dimension.unitWeightController.addListener(() {
      if (_pricingType == 'Dynamic Price') {
        _calculatePrice();
      }
    });
    
    setState(() {
      _dynamicDimensionList.add(dimension);
    });
  }
  
  void _removeDimension(String id) {
    // Prevent deletion if it's the last dimension (minimum one required)
    if (_pricingType == 'Fixed Price') {
      if (_dimensionList.length <= 1) {
        _showErrorDialog('At least one dimension is required');
        return;
      }
    } else {
      if (_dynamicDimensionList.length <= 1) {
        _showErrorDialog('At least one dimension is required');
        return;
      }
    }
    
    setState(() {
      if (_pricingType == 'Fixed Price') {
      final dimension = _dimensionList.firstWhere((d) => d.id == id);
      dimension.dispose();
      _dimensionList.removeWhere((d) => d.id == id);
      } else {
        final dimension = _dynamicDimensionList.firstWhere((d) => d.id == id);
        dimension.dispose();
        _dynamicDimensionList.removeWhere((d) => d.id == id);
      }
    });
    // Recalculate after removal
    if (_pricingType == 'Fixed Price') {
      _calculateFixedPrice();
    } else {
      _calculatePrice();
    }
  }
  
  Widget _buildDynamicDimensionCard(DimensionData dimension, int index) {
    // Calculate individual dimension values
    final length = double.tryParse(dimension.lengthController.text) ?? 0;
    final breadth = double.tryParse(dimension.breadthController.text) ?? 0;
    final height = double.tryParse(dimension.heightController.text) ?? 0;
    final units = int.tryParse(dimension.unitsController.text) ?? 1;
    final perUnitWeight = double.tryParse(dimension.unitWeightController.text) ?? 0;
    
    final volumetricFactor = _dynamicPriceConfig?.volumetricFactor ?? 6000;
    final volumetricWeightPerUnit = (length * breadth * height) / volumetricFactor;
    final totalVolumetricWeight = volumetricWeightPerUnit * units;
    final totalVolume = length * breadth * height * units;
    final totalWeight = perUnitWeight * units;
    
    // Get selected saved dimension for this card
    String? selectedSavedDimId = dimension.selectedSavedDimension?.id;
    
    return Container(
      padding: Responsive.padding(context),
      margin: EdgeInsets.only(bottom: Responsive.spacing(context, 20)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dimension ${index + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (_dynamicDimensionList.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeDimension(dimension.id),
                ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 16)),
          
          // Saved Dimensions Dropdown
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSavedDimId,
                      hint: const Text(
                        'Select saved dimensions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      isExpanded: true,
                      items: _isLoadingSavedDimensions
                          ? [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'Loading dimensions...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ]
                          : _savedDimensions.isEmpty
                              ? [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text(
                                      'No saved dimensions',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ]
                              : _savedDimensions.map<DropdownMenuItem<String>>((SavedDimension savedDim) {
                                  return DropdownMenuItem<String>(
                                    value: savedDim.id,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${savedDim.dimensionName} (${savedDim.length}x${savedDim.breadth}x${savedDim.height}cm, ${savedDim.weight}kg)',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            _handleDeleteDimension(savedDim);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            margin: const EdgeInsets.only(left: 8),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                      onChanged: _isLoadingSavedDimensions
                          ? null
                          : (String? newValue) {
                              if (_isDeletingFromDropdown) {
                                _isDeletingFromDropdown = false;
                                return;
                              }
                              setState(() {
                                if (newValue != null) {
                                  final selectedDimension = _savedDimensions.firstWhere(
                                    (d) => d.id == newValue,
                                  );
                                  dimension.selectedSavedDimension = selectedDimension;
                                  dimension.lengthController.text = selectedDimension.length;
                                  dimension.breadthController.text = selectedDimension.breadth;
                                  dimension.heightController.text = selectedDimension.height;
                                  dimension.unitWeightController.text = selectedDimension.weight;
                                  dimension.unitsController.text = '1';
                                } else {
                                  dimension.selectedSavedDimension = null;
                                }
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _calculatePrice();
                              });
                            },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSavingDimension ? null : () => _handleSaveDimensionsForCard(dimension),
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: _isSavingDimension
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 20)),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: dimension.lengthController,
                  label: 'Length (cm)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  controller: dimension.breadthController,
                  label: 'Breadth (cm)',
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 16)),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: dimension.heightController,
                  label: 'Height (cm)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  controller: dimension.unitsController,
                  label: 'No. of Units',
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 16)),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: dimension.unitWeightController,
                  label: 'Per Unit Weight (kg)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Weight (kg)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalWeight.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 20)),
          // Calculated Values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Volumetric Weight',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalVolumetricWeight.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Total Volume',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalVolume.toStringAsFixed(0)} cm³',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleSaveDimensionsForCard(DimensionData dimension) async {
    final length = double.tryParse(dimension.lengthController.text) ?? 0;
    final breadth = double.tryParse(dimension.breadthController.text) ?? 0;
    final height = double.tryParse(dimension.heightController.text) ?? 0;
    final weight = double.tryParse(dimension.unitWeightController.text) ?? 0;

    if (length <= 0 || breadth <= 0 || height <= 0 || weight <= 0) {
      _showErrorDialog('Please enter valid dimensions and weight');
      return;
    }

    // Show dialog to get dimension name
    final dimensionName = await showDialog<String>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Save Dimensions'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Dimension Name',
              hintText: 'e.g., Carton, Box',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(nameController.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (dimensionName == null || dimensionName.isEmpty) {
      return; // User cancelled or didn't enter a name
    }

    if (!mounted) return;
    setState(() {
      _isSavingDimension = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      final customer = await UserService.getCustomer();
      if (customer == null) {
        throw Exception('Customer information not found.');
      }

      print('🔵 Saving dimension: $dimensionName');
      final request = SaveDimensionRequest(
        customerId: customer.id,
        dimensionName: dimensionName,
        length: length.toString(),
        breadth: breadth.toString(),
        height: height.toString(),
        weight: weight.toString(),
        unitType: 'carton',
      );
      
      await _authService.saveDimension(request, token);

      print('✅ Dimension saved successfully');

      if (mounted) {
        setState(() {
          _isSavingDimension = false;
        });
        _showSuccessDialog('Dimensions saved successfully!');
        // Reload saved dimensions list
        _loadSavedDimensions();
      }
    } catch (e) {
      print('❌ Error saving dimension: $e');
      if (mounted) {
        setState(() {
          _isSavingDimension = false;
        });
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }
  
  Widget _buildDimensionCard(DimensionData dimension, int index) {
    // Calculate individual dimension values
    final length = double.tryParse(dimension.lengthController.text) ?? 0;
    final breadth = double.tryParse(dimension.breadthController.text) ?? 0;
    final height = double.tryParse(dimension.heightController.text) ?? 0;
    final units = int.tryParse(dimension.unitsController.text) ?? 1;
    final perUnitWeight = double.tryParse(dimension.unitWeightController.text) ?? 0;
    
    final volumetricFactor = dimension.selectedDimension != null
        ? (double.tryParse(dimension.selectedDimension!.volumetricFactor) ?? 6000)
        : 6000;
    final volumetricWeightPerUnit = (length * breadth * height) / volumetricFactor;
    final totalVolumetricWeight = volumetricWeightPerUnit * units;
    final totalVolume = length * breadth * height * units;
    
    return Container(
      padding: Responsive.padding(context),
      margin: EdgeInsets.only(bottom: Responsive.spacing(context, 20)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dimension ${index + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (_dimensionList.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeDimension(dimension.id),
                ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 16)),
          _buildFixedPriceDimensionDropdownForCard(dimension),
          SizedBox(height: Responsive.spacing(context, 20)),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: dimension.lengthController,
                  label: 'Length (cm)',
                  readOnly: true, // Always read-only in fixed pricing - only editable via dropdown
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  controller: dimension.breadthController,
                  label: 'Breadth (cm)',
                  readOnly: true, // Always read-only in fixed pricing - only editable via dropdown
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 16)),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: dimension.heightController,
                  label: 'Height (cm)',
                  readOnly: true, // Always read-only in fixed pricing - only editable via dropdown
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  controller: dimension.unitsController,
                  label: 'No. of Units',
                  readOnly: false, // Units should always be editable
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 16)),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: dimension.unitWeightController,
                  label: 'Per Unit Weight (kg)',
                  readOnly: true, // Always read-only in fixed pricing - only editable via dropdown
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  controller: dimension.chargesController,
                  label: 'Charges (Rs)',
                  readOnly: true,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 20)),
          // Calculated Values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Volumetric Weight',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalVolumetricWeight.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Total Volume',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalVolume.toStringAsFixed(0)} cm³',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFixedPriceDimensionDropdownForCard(DimensionData dimension) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dimension.selectedDimension?.id,
          hint: const Text(
            '-- Select Predefined Dimension --',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          isExpanded: true,
          items: _isLoadingFixedPriceDimensions
              ? null
              : _getAvailableDimensions(dimension).map((dim) {
                  return DropdownMenuItem<String>(
                    value: dim.id,
                    child: Text(
                      dim.dimensionName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
          onChanged: _isLoadingFixedPriceDimensions
              ? null
              : (String? newValue) {
                  setState(() {
                    if (newValue != null) {
                      dimension.selectedDimension = _fixedPriceDimensions.firstWhere(
                        (dim) => dim.id == newValue,
                      );
                      // Populate dimension fields
                      dimension.lengthController.text = dimension.selectedDimension!.length;
                      dimension.breadthController.text = dimension.selectedDimension!.breadth;
                      dimension.heightController.text = dimension.selectedDimension!.height;
                      dimension.unitWeightController.text = dimension.selectedDimension!.weight;
                      dimension.unitsController.text = '1'; // Default to 1 unit
                      // Set charges from dimension
                      dimension.chargesController.text = dimension.selectedDimension!.dimensionCharge;
                    } else {
                      dimension.selectedDimension = null;
                      dimension.lengthController.clear();
                      dimension.breadthController.clear();
                      dimension.heightController.clear();
                      dimension.unitWeightController.clear();
                      dimension.unitsController.text = '1';
                      dimension.chargesController.clear();
                    }
                  });
                  // Trigger price calculation
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_pricingType == 'Fixed Price') {
                      _calculateFixedPrice();
                    }
                  });
                },
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.grey[600],
            size: 28,
          ),
        ),
      ),
    );
  }

  double _getCodChargeForFixedPrice() {
    if (!_collectCOD) {
      return 0.0;
    }
    
    final codAmount = double.tryParse(_codAmountController.text) ?? 0;
    if (codAmount <= 0) {
      return 0.0;
    }
    
    // Get dimension from first dimension in list with selected dimension
    if (_dimensionList.isEmpty) {
      return 0.0;
    }
    
    final firstDim = _dimensionList.firstWhere(
      (d) => d.selectedDimension != null,
      orElse: () => _dimensionList.first,
    );
    
    if (firstDim.selectedDimension == null) {
      return 0.0;
    }
    
    final dimension = firstDim.selectedDimension!;
    String? codCharge;
    
    if (dimension.codRange1 != null && 
        codAmount >= dimension.codRange1!.min && 
        codAmount <= dimension.codRange1!.max) {
      codCharge = dimension.codCharge1;
    } else if (dimension.codRange2 != null && 
               codAmount >= dimension.codRange2!.min && 
               codAmount <= dimension.codRange2!.max) {
      codCharge = dimension.codCharge2;
    } else if (dimension.codRange3 != null && 
               codAmount >= dimension.codRange3!.min && 
               codAmount <= dimension.codRange3!.max) {
      codCharge = dimension.codCharge3;
    } else if (dimension.codRange4 != null && 
               codAmount >= dimension.codRange4!.min && 
               codAmount <= dimension.codRange4!.max) {
      codCharge = dimension.codCharge4;
    } else if (dimension.codRange5 != null && 
               codAmount >= dimension.codRange5!.min && 
               codAmount <= dimension.codRange5!.max) {
      codCharge = dimension.codCharge5;
    } else if (dimension.codRange6 != null && 
               codAmount >= dimension.codRange6!.min && 
               codAmount <= dimension.codRange6!.max) {
      codCharge = dimension.codCharge6;
    }
    
    return codCharge != null ? (double.tryParse(codCharge) ?? 0.0) : 0.0;
  }

  Future<void> _showOrderConfirmation() async {
    // Validate required fields first
    if (_commodityController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a commodity');
      return;
    }

    if (_selectedShipperId == null || _shipperController.text.trim().isEmpty) {
      _showErrorDialog('Please select a shipper');
      return;
    }

    if (_selectedConsigneeId == null || _consigneeController.text.trim().isEmpty) {
      _showErrorDialog('Please select a consignee');
      return;
    }

    if (_pickupDateController.text.trim().isEmpty) {
      _showErrorDialog('Please select pickup date');
      return;
    }

    if (_pickupTimeController.text.trim().isEmpty) {
      _showErrorDialog('Please select pickup time');
      return;
    }

    if (_consigneeClosingTimeController.text.trim().isEmpty) {
      _showErrorDialog('Please enter consignee closing time');
      return;
    }

    // Validate dimensions based on pricing type
    if (_pricingType == 'Fixed Price') {
      // Validate Fixed Price dimensions
      if (_dimensionList.isEmpty) {
        _showErrorDialog('Please add at least one dimension');
        return;
      }
      
      bool hasValidDimension = false;
      for (var dimData in _dimensionList) {
        if (dimData.selectedDimension == null) continue;
        
        final length = double.tryParse(dimData.lengthController.text) ?? 0;
        final breadth = double.tryParse(dimData.breadthController.text) ?? 0;
        final height = double.tryParse(dimData.heightController.text) ?? 0;
        final units = int.tryParse(dimData.unitsController.text) ?? 0;
        
        if (length > 0 && breadth > 0 && height > 0 && units > 0) {
          hasValidDimension = true;
          break;
        }
      }
      
      if (!hasValidDimension) {
        _showErrorDialog('Please enter valid dimensions');
        return;
      }
      
      // Validate COD amount if COD is toggled
      if (_collectCOD) {
        final codAmount = double.tryParse(_codAmountController.text) ?? 0;
        if (codAmount <= 0) {
          _showErrorDialog('Please enter a valid COD amount');
          return;
        }
      }
    } else {
      // Validate Dynamic Price dimensions
      if (_dynamicDimensionList.isNotEmpty) {
        // Check multiple dimensions
        bool hasValidDimension = false;
        for (var dimData in _dynamicDimensionList) {
          final length = double.tryParse(dimData.lengthController.text) ?? 0;
          final breadth = double.tryParse(dimData.breadthController.text) ?? 0;
          final height = double.tryParse(dimData.heightController.text) ?? 0;
          final units = int.tryParse(dimData.unitsController.text) ?? 0;
          final perUnitWeight = double.tryParse(dimData.unitWeightController.text) ?? 0;
          if (length > 0 && breadth > 0 && height > 0 && units > 0 && perUnitWeight > 0) {
            hasValidDimension = true;
            break;
          }
        }
        if (!hasValidDimension) {
          _showErrorDialog('Please enter valid dimensions for all dimension entries');
          return;
        }
      } else {
        // Fallback to single dimension (using old controllers)
    final length = double.tryParse(_lengthController.text) ?? 0;
    final breadth = double.tryParse(_breadthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final units = int.tryParse(_unitsController.text) ?? 0;

    if (length <= 0 || breadth <= 0 || height <= 0 || units <= 0) {
      _showErrorDialog('Please enter valid dimensions');
      return;
    }
      }
    }

    // Validate charges based on pricing type
    double transportationCharges;
    if (_pricingType == 'Fixed Price') {
      // In Fixed Price mode, charges are calculated and stored in _transportAmount
      transportationCharges = _transportAmount;
    if (transportationCharges <= 0) {
        _showErrorDialog('Please enter valid dimensions to calculate transportation charges');
      return;
      }
    } else {
      // In Dynamic Price mode, charges are calculated and stored in _transportAmount
      transportationCharges = _transportAmount; // Use calculated amount
      if (transportationCharges <= 0) {
        _showErrorDialog('Please enter valid dimensions to calculate transportation charges');
        return;
      }
    }

    // Calculate all values for display - use same logic as summary screen
    double expressCharges = 0;
    double challanCharges = 0;
    double codCharges = 0;
    double codAmount = 0;
    double preTaxAmount;
    double couponDiscount = 0;
    double gstAmount;
    double finalPayable;
    double gstPercentage;

    if (_pricingType == 'Dynamic Price') {
      // Use same calculation as summary screen
      expressCharges = _expressDelivery 
          ? _transportAmount * (_dynamicPriceConfig!.expressDeliverySurchargePercentage / 100)
          : 0;
      challanCharges = _challanReturn ? _dynamicPriceConfig!.chalaanReturnCharges : 0;
      if (_collectCOD) {
        codAmount = double.tryParse(_codAmountController.text) ?? 0;
        if (codAmount > 0 && _dynamicPriceConfig != null) {
          final codSlab = _dynamicPriceConfig!.codRanges.firstWhere(
            (slab) => codAmount >= slab.range[0] && codAmount <= slab.range[1],
            orElse: () => _dynamicPriceConfig!.codRanges.first,
          );
          codCharges = codSlab.charge;
        }
      }
      // Use pre-calculated values from summary screen
      preTaxAmount = _preTaxAmount;
      couponDiscount = _appliedCouponCode != null && _couponDiscountAmount != null
          ? (double.tryParse(_couponDiscountAmount!) ?? 0)
          : 0;
      gstAmount = _gstAmount;
      finalPayable = _finalPayable;
      gstPercentage = _dynamicPriceConfig!.gstPercentage;
    } else {
      // Fixed Price - use same calculation as summary screen
      if (_dimensionList.isNotEmpty) {
        final firstDim = _dimensionList.firstWhere(
          (d) => d.selectedDimension != null,
          orElse: () => _dimensionList.first,
        );
        if (firstDim.selectedDimension != null) {
          final dimension = firstDim.selectedDimension!;
          
          // Calculate express charges from dimension data
          if (_expressDelivery) {
            final expressPercentage = double.tryParse(dimension.expressDeliveryPercentage) ?? 0;
            expressCharges = _transportAmount * (expressPercentage / 100);
          }
          
          // Calculate challan charges from dimension data
          if (_challanReturn) {
            challanCharges = double.tryParse(dimension.chalaanReturnCharges) ?? 0;
          }
          
          // Calculate COD charges using same method as summary screen
          if (_collectCOD) {
            codAmount = double.tryParse(_codAmountController.text) ?? 0;
            codCharges = _getCodChargeForFixedPrice();
          }
          
          // Get GST percentage from dimension
          gstPercentage = double.tryParse(dimension.gstPercentage) ?? 18.0;
        } else {
          // Fallback if no dimension selected
          expressCharges = _expressDelivery ? transportationCharges * 0.10 : 0;
          challanCharges = _challanReturn ? 10.0 : 0;
          if (_collectCOD) {
            codAmount = double.tryParse(_codAmountController.text) ?? 0;
            codCharges = 10.0;
          }
          gstPercentage = 18.0;
        }
      } else {
        // Fallback if no dimensions
        expressCharges = _expressDelivery ? transportationCharges * 0.10 : 0;
        challanCharges = _challanReturn ? 10.0 : 0;
        if (_collectCOD) {
          codAmount = double.tryParse(_codAmountController.text) ?? 0;
          codCharges = 10.0;
        }
        gstPercentage = 18.0;
      }
      
      // Use pre-calculated values from summary screen instead of recalculating
      preTaxAmount = _preTaxAmount;
      couponDiscount = _appliedCouponCode != null && _couponDiscountAmount != null
          ? (double.tryParse(_couponDiscountAmount!) ?? 0)
          : 0;
      gstAmount = _gstAmount;
      finalPayable = _finalPayable;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirm Order',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Commodity', _commodityController.text),
              _buildSummaryRow('Shipper', _shipperController.text),
              _buildSummaryRow('Consignee', _consigneeController.text),
              _buildSummaryRow('Pickup Date', _pickupDateController.text),
              _buildSummaryRow('Pickup Time', _pickupTimeController.text),
              SizedBox(height: Responsive.spacing(context, 16)),
              const Divider(),
              SizedBox(height: Responsive.spacing(context, 16)),
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Transportation Charges', '₹${transportationCharges.toStringAsFixed(2)}'),
              if (_expressDelivery)
                _buildSummaryRow('Express Delivery', '₹${expressCharges.toStringAsFixed(2)}'),
              if (_challanReturn)
                _buildSummaryRow('Physical POD Charges', '₹${challanCharges.toStringAsFixed(2)}'),
              if (_collectCOD)
                _buildSummaryRow('COD Charges', '₹${codCharges.toStringAsFixed(2)}'),
              if (couponDiscount > 0)
                _buildSummaryRow('Coupon Discount', '-₹${couponDiscount.toStringAsFixed(2)}', isDiscount: true),
              _buildSummaryRow('Pre-Tax Amount', '₹${preTaxAmount.toStringAsFixed(2)}'),
              _buildSummaryRow('GST (${gstPercentage.toStringAsFixed(0)}%)', '₹${gstAmount.toStringAsFixed(2)}'),
              const Divider(),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Total Payable',
                '₹${finalPayable.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitOrder();
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isTotal = false, bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: (isTotal || isHighlighted) ? FontWeight.bold : FontWeight.normal,
              color: (isTotal || isHighlighted) ? const Color(0xFF1E3A8A) : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: (isTotal || isHighlighted) ? FontWeight.bold : FontWeight.normal,
              color: isDiscount
                  ? Colors.green
                  : (isTotal || isHighlighted)
                      ? const Color(0xFF1E3A8A)
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!mounted) return;
    setState(() {
      _isSubmittingOrder = true;
    });

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();

      if (token == null || customer == null) {
        throw Exception('Authentication token or customer ID not found.');
      }

      // Get commodity name - use selected commodity if available, otherwise use entered text
      String commodityName;
      if (_selectedCommodityId != null) {
        try {
          final selectedCommodity = _commodities.firstWhere(
            (c) => c.id == _selectedCommodityId,
          );
          commodityName = selectedCommodity.name;
        } catch (e) {
          // If selected commodity not found in list, use entered text
          commodityName = _commodityController.text.trim();
        }
      } else {
        // No commodity selected from list, use entered text
        commodityName = _commodityController.text.trim();
      }
      final commodityList = [commodityName];

      // Parse dimension values from controllers
      final length = double.tryParse(_lengthController.text) ?? 0;
      final breadth = double.tryParse(_breadthController.text) ?? 0;
      final height = double.tryParse(_heightController.text) ?? 0;
      final units = int.tryParse(_unitsController.text) ?? 0;
      final perUnitWeight = double.tryParse(_unitWeightController.text) ?? 0;

      // Use calculated values for dynamic pricing, or calculate for fixed pricing
      double transportationCharges;
      double expressCharges = 0;
      double challanCharges = 0;
      double codCharges = 0;
      double codAmount = 0;
      double preTaxAmount;
      double couponDiscount = 0;
      double gstAmount;
      double finalPayable;
      double gstPercentage;
      
      double volumetricWeightPerUnit;
      double totalVolume;
      double totalWeight;
      double totalVolWeight;
      double chargeableWeight;

      // Use pre-calculated values from _calculateFixedPrice() or _calculatePrice()
      // Both methods already handle multiple dimensions and calculate all totals correctly
      if (_pricingType == 'Dynamic Price') {
        // Use pre-calculated values from _calculatePrice() which handles multiple dimensions
        // These values are already calculated from _dynamicDimensionList
        totalVolume = _totalVolume;
        totalWeight = _totalGrossWeight;
        totalVolWeight = _totalVolumetricWeight;
        chargeableWeight = _chargeableWeight;
        transportationCharges = _transportAmount;
        expressCharges = _expressDelivery 
            ? _transportAmount * (_dynamicPriceConfig!.expressDeliverySurchargePercentage / 100)
            : 0;
        challanCharges = _challanReturn ? _dynamicPriceConfig!.chalaanReturnCharges : 0;
        // Calculate average volumetric weight per unit for display
        volumetricWeightPerUnit = _totalUnits > 0 ? _totalVolumetricWeight / _totalUnits : 0;
        
        if (_collectCOD) {
          codAmount = double.tryParse(_codAmountController.text) ?? 0;
          if (codAmount <= 0) {
            _showErrorDialog('Please enter valid COD amount');
            if (mounted) {
              setState(() {
                _isSubmittingOrder = false;
              });
            }
            return;
          }
          final codSlab = _dynamicPriceConfig!.codRanges.firstWhere(
            (slab) => codAmount >= slab.range[0] && codAmount <= slab.range[1],
            orElse: () => _dynamicPriceConfig!.codRanges.first,
          );
          codCharges = codSlab.charge;
        }
        
        preTaxAmount = _preTaxAmount;
        couponDiscount = _appliedCouponCode != null && _couponDiscountAmount != null
            ? (double.tryParse(_couponDiscountAmount!) ?? 0)
            : 0;
        gstAmount = _gstAmount;
        finalPayable = _finalPayable;
        gstPercentage = _dynamicPriceConfig!.gstPercentage;
      } else {
        // Fixed Price - use pre-calculated values from _calculateFixedPrice()
        // This already handles multiple dimensions correctly
        volumetricWeightPerUnit = _totalVolumetricWeight > 0 && _totalUnits > 0
            ? _totalVolumetricWeight / _totalUnits
            : 0;
        totalVolume = _totalVolume;
        totalWeight = _totalGrossWeight;
        totalVolWeight = _totalVolumetricWeight;
        chargeableWeight = _chargeableWeight;
        transportationCharges = _transportAmount;
        
        // Get first dimension for express, challan, COD calculations
        final firstDim = _dimensionList.firstWhere(
          (d) => d.selectedDimension != null,
          orElse: () => _dimensionList.isNotEmpty ? _dimensionList.first : DimensionData(
            id: '',
            lengthController: TextEditingController(),
            breadthController: TextEditingController(),
            heightController: TextEditingController(),
            unitsController: TextEditingController(),
            unitWeightController: TextEditingController(),
            chargesController: TextEditingController(),
          ),
        );
        
        if (firstDim.selectedDimension != null) {
          final dimension = firstDim.selectedDimension!;
          
          // Calculate express charges
          if (_expressDelivery) {
            final expressPercentage = double.tryParse(dimension.expressDeliveryPercentage) ?? 0;
            expressCharges = transportationCharges * (expressPercentage / 100);
          }

          // Calculate challan charges
          if (_challanReturn) {
            challanCharges = double.tryParse(dimension.chalaanReturnCharges) ?? 0;
          }

          // Calculate COD charges
          if (_collectCOD) {
            codAmount = double.tryParse(_codAmountController.text) ?? 0;
            if (codAmount > 0) {
            String? codCharge;
            if (dimension.codRange1 != null && 
                codAmount >= dimension.codRange1!.min && 
                codAmount <= dimension.codRange1!.max) {
              codCharge = dimension.codCharge1;
            } else if (dimension.codRange2 != null && 
                       codAmount >= dimension.codRange2!.min && 
                       codAmount <= dimension.codRange2!.max) {
              codCharge = dimension.codCharge2;
            } else if (dimension.codRange3 != null && 
                       codAmount >= dimension.codRange3!.min && 
                       codAmount <= dimension.codRange3!.max) {
              codCharge = dimension.codCharge3;
            } else if (dimension.codRange4 != null && 
                       codAmount >= dimension.codRange4!.min && 
                       codAmount <= dimension.codRange4!.max) {
              codCharge = dimension.codCharge4;
            } else if (dimension.codRange5 != null && 
                       codAmount >= dimension.codRange5!.min && 
                       codAmount <= dimension.codRange5!.max) {
              codCharge = dimension.codCharge5;
            } else if (dimension.codRange6 != null && 
                       codAmount >= dimension.codRange6!.min && 
                       codAmount <= dimension.codRange6!.max) {
              codCharge = dimension.codCharge6;
            }
            codCharges = codCharge != null ? (double.tryParse(codCharge) ?? 0) : 0;
          }
          }
          
          // Use pre-calculated values from _calculateFixedPrice()
          preTaxAmount = _preTaxAmount;
          couponDiscount = _appliedCouponCode != null && _couponDiscountAmount != null
              ? (double.tryParse(_couponDiscountAmount!) ?? 0)
              : 0;
          gstAmount = _gstAmount;
          finalPayable = _finalPayable;
          gstPercentage = double.tryParse(dimension.gstPercentage) ?? 18.0;
        } else {
          // Fallback if no dimension selected
          expressCharges = _expressDelivery ? transportationCharges * 0.10 : 0;
          challanCharges = _challanReturn ? 10.0 : 0;
      if (_collectCOD) {
        codAmount = double.tryParse(_codAmountController.text) ?? 0;
          codCharges = 10.0;
      }
        preTaxAmount = transportationCharges + expressCharges + challanCharges + codCharges;
      if (_appliedCouponCode != null && _couponDiscountAmount != null) {
        couponDiscount = double.tryParse(_couponDiscountAmount!) ?? 0;
        preTaxAmount = preTaxAmount - couponDiscount;
        if (preTaxAmount < 0) preTaxAmount = 0;
      }
        gstPercentage = 18.0;
        final gstAmountRaw = preTaxAmount * (gstPercentage / 100);
        gstAmount = double.parse(gstAmountRaw.toStringAsFixed(2));
        finalPayable = _roundFinalPayable(preTaxAmount + gstAmount);
        }
      }

      // Create dimension data list and calculate totals
      List<order_submit_model.DimensionData> dimensionList = [];
      
      // Variables for totals (will be calculated from dimensions)
      int totalUnitsForSubmit = 0;
      double totalGrossWeightForSubmit = 0;
      double totalVolWeightForSubmit = 0;
      double totalVolumeForSubmit = 0;
      double chargeableWeightForSubmit = 0;
      
      if (_pricingType == 'Fixed Price' && _dimensionList.isNotEmpty) {
        // Create dimensions from multiple dimension cards and calculate totals
        for (int i = 0; i < _dimensionList.length; i++) {
          final dimData = _dimensionList[i];
          if (dimData.selectedDimension == null) continue;
          
          final dimLength = double.tryParse(dimData.lengthController.text) ?? 0;
          final dimBreadth = double.tryParse(dimData.breadthController.text) ?? 0;
          final dimHeight = double.tryParse(dimData.heightController.text) ?? 0;
          final dimUnits = int.tryParse(dimData.unitsController.text) ?? 1;
          final dimPerUnitWeight = double.tryParse(dimData.unitWeightController.text) ?? 0;
          
          // Calculate volumetric weight for this dimension
          final dimVolumetricFactor = double.tryParse(dimData.selectedDimension!.volumetricFactor) ?? 6000;
          final dimVolumetricWeightPerUnit = (dimLength * dimBreadth * dimHeight) / dimVolumetricFactor;
          final dimTotalVolume = dimLength * dimBreadth * dimHeight * dimUnits;
          final dimTotalWeight = dimPerUnitWeight * dimUnits;
          final dimVolumetricWeight = dimVolumetricWeightPerUnit * dimUnits;
          final dimChargeableWeight = dimTotalWeight > dimVolumetricWeight ? dimTotalWeight : dimVolumetricWeight;
          
          // Accumulate totals
          totalUnitsForSubmit += dimUnits;
          totalGrossWeightForSubmit += dimTotalWeight;
          totalVolWeightForSubmit += dimVolumetricWeight;
          totalVolumeForSubmit += dimTotalVolume;
          chargeableWeightForSubmit += dimChargeableWeight;
          
          dimensionList.add(
            order_submit_model.DimensionData(
              id: i + 1,
              length: dimLength.toString(),
              breadth: dimBreadth.toString(),
              height: dimHeight.toString(),
              units: dimUnits,
              perUnitWeight: dimPerUnitWeight.toString(),
              volumetricWeightPerUnit: dimVolumetricWeightPerUnit.toStringAsFixed(2),
              totalVolume: dimTotalVolume.toStringAsFixed(4),
              totalWeight: dimTotalWeight.toString(),
            ),
          );
        }
      } else if (_pricingType == 'Dynamic Price' && _dynamicDimensionList.isNotEmpty) {
        // Dynamic Price - create dimensions from multiple dimension cards
        for (int i = 0; i < _dynamicDimensionList.length; i++) {
          final dimData = _dynamicDimensionList[i];
          
          final dimLength = double.tryParse(dimData.lengthController.text) ?? 0;
          final dimBreadth = double.tryParse(dimData.breadthController.text) ?? 0;
          final dimHeight = double.tryParse(dimData.heightController.text) ?? 0;
          final dimUnits = int.tryParse(dimData.unitsController.text) ?? 1;
          final dimPerUnitWeight = double.tryParse(dimData.unitWeightController.text) ?? 0;
          
          // Calculate volumetric weight for this dimension
          final dimVolumetricFactor = 6000; // Standard volumetric factor
          final dimVolumetricWeightPerUnit = (dimLength * dimBreadth * dimHeight) / dimVolumetricFactor;
          final dimTotalVolume = dimLength * dimBreadth * dimHeight * dimUnits;
          final dimTotalWeight = dimPerUnitWeight * dimUnits;
          final dimVolumetricWeight = dimVolumetricWeightPerUnit * dimUnits;
          final dimChargeableWeight = dimTotalWeight > dimVolumetricWeight ? dimTotalWeight : dimVolumetricWeight;
          
          // Accumulate totals
          totalUnitsForSubmit += dimUnits;
          totalGrossWeightForSubmit += dimTotalWeight;
          totalVolWeightForSubmit += dimVolumetricWeight;
          totalVolumeForSubmit += dimTotalVolume;
          chargeableWeightForSubmit += dimChargeableWeight;
          
          dimensionList.add(
            order_submit_model.DimensionData(
              id: i + 1,
              length: dimLength.toString(),
              breadth: dimBreadth.toString(),
              height: dimHeight.toString(),
              units: dimUnits,
              perUnitWeight: dimPerUnitWeight.toString(),
              volumetricWeightPerUnit: dimVolumetricWeightPerUnit.toStringAsFixed(2),
              totalVolume: dimTotalVolume.toStringAsFixed(4),
              totalWeight: dimTotalWeight.toString(),
            ),
          );
        }
        
        // For Dynamic Price, use the pre-calculated totals from _calculatePrice() 
        // which are already calculated from _dynamicDimensionList
        // This ensures consistency with what's displayed on screen
        totalUnitsForSubmit = _totalUnits.toInt();
        totalGrossWeightForSubmit = _totalGrossWeight;
        totalVolWeightForSubmit = _totalVolumetricWeight;
        totalVolumeForSubmit = _totalVolume;
        chargeableWeightForSubmit = _chargeableWeight;
      } else {
        // Fallback for single dimension (should not happen with current UI)
        dimensionList.add(
          order_submit_model.DimensionData(
            id: 1,
            length: length.toString(),
            breadth: breadth.toString(),
            height: height.toString(),
            units: units,
            perUnitWeight: perUnitWeight.toString(),
            volumetricWeightPerUnit: volumetricWeightPerUnit.toStringAsFixed(2),
            totalVolume: totalVolume.toStringAsFixed(4),
            totalWeight: totalWeight.toString(),
          ),
        );
      }

      // Format date (convert from dd-mm-yyyy to yyyy-mm-dd)
      String scheduleDate = _pickupDateController.text.trim();
      if (scheduleDate.contains('-')) {
        final parts = scheduleDate.split('-');
        if (parts.length == 3) {
          scheduleDate = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }

      // Create order request
      final orderRequest = OrderSubmitRequest(
        customerId: customer.id,
        pickupPlaceId: _selectedShipperId!,
        dropPlaceId: _selectedConsigneeId!,
        scheduleDate: scheduleDate,
        preferredPickupTime: _pickupTimeController.text.trim(),
        consigneeClosingTime: '${_consigneeClosingTimeController.text.trim()}:00',
        pickupNote: _pickupNoteController.text.trim().isEmpty ? 'Note' : _pickupNoteController.text.trim(),
        dropNote: _dropNoteController.text.trim().isEmpty ? 'Note' : _dropNoteController.text.trim(),
        commodity: commodityList,
        priceModuleType: _pricingType == 'Fixed Price' ? 'fixed' : 'dynamic',
        expressDelivery: _expressDelivery,
        expressCharges: expressCharges.toStringAsFixed(2),
        challanReturn: _challanReturn,
        challanCharges: challanCharges.toStringAsFixed(2),
        challanReturnStatus: 'pending',
        codCollection: _collectCOD,
        codAmount: _collectCOD ? codAmount.toStringAsFixed(2) : null,
        codStatus: 'pending',
        codCharges: codCharges.toStringAsFixed(2),
        dimensions: dimensionList,
        totalUnits: totalUnitsForSubmit,
        totalGrossWeight: totalGrossWeightForSubmit.toStringAsFixed(2),
        totalVolWeight: totalVolWeightForSubmit.toStringAsFixed(2),
        totalVolume: totalVolumeForSubmit.toStringAsFixed(4),
        chargeableWeight: chargeableWeightForSubmit.toStringAsFixed(2),
        transportationCharges: transportationCharges.toStringAsFixed(2),
        couponDiscount: couponDiscount.toStringAsFixed(2),
        preTaxAmount: preTaxAmount.toStringAsFixed(2),
        gstPercentage: gstPercentage.toStringAsFixed(2),
        gstAmount: gstAmount.toStringAsFixed(2),
        finalPayable: finalPayable.toStringAsFixed(2),
        totalCommodityValue: _collectCOD && codAmount > 0 
            ? codAmount.toStringAsFixed(2) 
            : '0.00',
      );

      print('🔵 Submitting order...');
      print('🔵 Order Request Details:');
      print('   - Dimensions count: ${dimensionList.length}');
      print('   - Total Units: $totalUnitsForSubmit');
      print('   - Total Gross Weight: $totalGrossWeightForSubmit');
      print('   - Total Vol Weight: $totalVolWeightForSubmit');
      print('   - Total Volume: $totalVolumeForSubmit');
      print('   - Chargeable Weight: $chargeableWeightForSubmit');
      print('   - Transportation Charges: $transportationCharges');
      print('   - Pre-Tax Amount: $preTaxAmount');
      print('   - GST Amount: $gstAmount');
      print('   - Final Payable: $finalPayable');
      print('   - Dimensions JSON: ${jsonEncode(dimensionList.map((d) => d.toJson()).toList())}');
      
      final response = await _authService.submitOrder(
        request: orderRequest,
        token: token,
        challanFilePaths: _challanFilePaths.isNotEmpty ? _challanFilePaths : null,
      );

      if (mounted) {
        setState(() {
          _isSubmittingOrder = false;
        });

        // Show success screen
        _showOrderSuccessScreen(response.data.orderId);
      }
    } catch (e) {
      print('❌ Error submitting order: $e');
      if (mounted) {
        setState(() {
          _isSubmittingOrder = false;
        });
        _showErrorDialog('Failed to submit order: ${e.toString()}');
      }
    }
  }

  void _showOrderSuccessScreen(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              SizedBox(height: Responsive.spacing(context, 24)),
              // Success message
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your valuable order has been successfully submitted.\nOrder ID: $orderId',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.spacing(context, 32)),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close success dialog
                        Navigator.of(context).pop(); // Go back to previous screen
                        // Navigate to track order screen
                        Navigator.of(context).pushNamed('/track-order');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Track Order'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close success dialog
                        // Reset form for new order
                        _resetForm();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('New Order'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      // Clear commodity
      _commodityController.clear();
      _selectedCommodityId = null;
      _filteredCommodities = [];
      
      // Clear shipper
      _shipperController.clear();
      _selectedShipperId = null;
      _selectedShipper = null;
      _shipperResults = [];
      
      // Clear consignee
      _consigneeController.clear();
      _selectedConsigneeId = null;
      _selectedConsignee = null;
      _consigneeResults = [];
      
      // Clear pickup details
      _pickupDateController.clear();
      _pickupDate = null;
      _pickupTimeController.clear();
      _pickupNoteController.clear();
      
      // Clear consignee details
      _consigneeClosingTimeController.clear();
      _dropNoteController.clear();
      
      // Clear dimension lists and dispose controllers
      for (var dim in _dimensionList) {
        dim.dispose();
      }
      _dimensionList.clear();
      
      for (var dim in _dynamicDimensionList) {
        dim.dispose();
      }
      _dynamicDimensionList.clear();
      
      // Clear old single dimension controllers (for backward compatibility)
      _lengthController.clear();
      _breadthController.clear();
      _heightController.clear();
      _unitsController.text = '1';
      _unitWeightController.clear();
      _chargesController.clear();
      _totalWeightController.text = '0.00';
      
      // Clear toggles
      _expressDelivery = false;
      _challanReturn = false;
      _collectCOD = false;
      
      // Clear COD and coupon
      _codAmountController.clear();
      _couponCodeController.clear();
      _appliedCouponCode = null;
      _couponDiscountAmount = null;
      
      // Clear challan files
      _challanFilePaths = [];
      
      // Clear calculated values
      _totalUnits = 0;
      _totalGrossWeight = 0;
      _totalVolumetricWeight = 0;
      _totalVolume = 0;
      _chargeableWeight = 0;
      _transportAmount = 0;
      _preTaxAmount = 0;
          _subTotalBeforeDiscount = 0;
          _subTotalAfterDiscount = 0;
          _expressCharges = 0;
          _gstAmount = 0;
          _finalPayable = 0;
      
      // Clear DC closing time
      _dcClosingTime = null;
      
      // Reinitialize with one dimension based on pricing type
      if (_pricingType == 'Fixed Price') {
        _addNewDimension();
      } else {
        _addNewDynamicDimension();
      }
    });
  }

  Future<void> _loadCommodities() async {
    if (!mounted) return;
    
    // Don't update loading state if field has focus (to avoid closing keyboard)
    // Just set the flag without setState
    if (!_commodityFocusNode.hasFocus) {
    setState(() {
      _isLoadingCommodities = true;
    });
    } else {
      // If field has focus, don't call setState - just set the flag directly
      _isLoadingCommodities = true;
    }

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Fetching commodities...');
      final response = await _authService.getCommodities(token);

      if (mounted) {
        // Update commodities without setState if field has focus (to avoid closing keyboard)
        final hadFocus = _commodityFocusNode.hasFocus;
          _commodities = response.data;
          _isLoadingCommodities = false;
        
        print('✅ Commodities loaded: ${_commodities.length}');
        if (_commodities.isEmpty) {
          print('⚠️ Warning: No commodities found in API response');
          print('⚠️ API returned empty data array. Please check if commodities exist in the database.');
        } else {
          print('🔵 First commodity: id=${_commodities.first.id}, name="${_commodities.first.name}"');
        }
        
        // Only call setState if field doesn't have focus, or after a delay if it does
        if (hadFocus && _commodityFocusNode.hasFocus) {
          // Field still has focus - defer setState to avoid closing keyboard
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted || !_commodityFocusNode.hasFocus) return;
            
            // Now safe to call setState
            setState(() {
              // Update filtered list based on current text
              if (_commodityController.text.isEmpty) {
                _filteredCommodities = _commodities;
              } else {
                // Trigger search to filter
                _onCommoditySearch();
              }
            });
          });
        } else {
          // Field doesn't have focus - safe to call setState immediately
          setState(() {
            _filteredCommodities = [];
          });
        }
      }
    } catch (e) {
      print('❌ Error loading commodities: $e');
      if (mounted) {
        setState(() {
          _isLoadingCommodities = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _shipperController.removeListener(_onShipperSearch);
    _shipperFocusNode.removeListener(_onShipperFocusChange);
    _shipperFocusNode.dispose();
    _commodityController.removeListener(_onCommoditySearch);
    _commodityFocusNode.removeListener(_onCommodityFocusChange);
    _commodityFocusNode.dispose();
    _consigneeController.removeListener(_onConsigneeSearch);
    _consigneeFocusNode.removeListener(_onConsigneeFocusChange);
    _consigneeFocusNode.dispose();
    _lengthController.removeListener(_calculatePrice);
    _breadthController.removeListener(_calculatePrice);
    _heightController.removeListener(_calculatePrice);
    _unitsController.removeListener(_calculatePrice);
    _unitWeightController.removeListener(_calculatePrice);
    _codAmountController.removeListener(_calculatePrice);
    _commodityController.dispose();
    _shipperController.dispose();
    _pickupDateController.dispose();
    _pickupTimeController.dispose();
    _pickupNoteController.dispose();
    _consigneeController.dispose();
    _consigneeClosingTimeController.dispose();
    _dimensionNameController.dispose();
    _dropNoteController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    _heightController.dispose();
    _unitsController.dispose();
    _unitWeightController.dispose();
    _chargesController.dispose();
    _totalWeightController.dispose();
    _couponCodeController.dispose();
    _codAmountController.dispose();
    // Dispose all dimension controllers
    for (var dimension in _dimensionList) {
      dimension.dispose();
    }
    _dimensionList.clear();
    for (var dimension in _dynamicDimensionList) {
      dimension.dispose();
    }
    _dynamicDimensionList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
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
                Icon(
                  Icons.inventory_2,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '₹$_walletBalance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: Responsive.padding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: Responsive.maxContentWidth(context),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2,
                  color: Colors.brown[700],
                        size: Responsive.iconSize(context, 24),
                ),
                      SizedBox(width: Responsive.spacing(context, 8)),
                      Text(
                  'Place Your Order',
                  style: TextStyle(
                          fontSize: Responsive.fontSize(context, 24),
                    fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
                  SizedBox(height: Responsive.spacing(context, 24)),

            // Pricing Type Selection
            Row(
              children: [
                if (widget.hasFixedPriceAccess) ...[
                  Expanded(
                    child: _buildPricingButton('Fixed Price', _pricingType == 'Fixed Price'),
                  ),
                        SizedBox(width: Responsive.spacing(context, 12)),
                ],
                Expanded(
                  child: _buildPricingButton('Dynamic Price', _pricingType == 'Dynamic Price'),
                ),
              ],
            ),
                  SizedBox(height: Responsive.spacing(context, 32)),

            // Show different forms based on pricing type
            if (_pricingType == 'Fixed Price')
              _buildFixedPriceForm()
            else
              _buildDynamicPriceForm(),
          ],
        ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFixedPriceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Commodity Field
        _buildCommodityDropdown(),
        const SizedBox(height: 20),

        // Select Pre-Registered Shipper
        _buildShipperSearchField(),
        const SizedBox(height: 20),

        // Preferred Pickup Date
        _buildTextField(
          controller: _pickupDateController,
          label: 'Preferred Pickup Date',
          hint: 'dd-mm-yyyy',
          suffixIcon: Icons.calendar_today,
          onTap: _selectPickupDate,
        ),
        const SizedBox(height: 20),

        // Preferred Pickup Time
        _buildPickupTimeDropdown(),
        const SizedBox(height: 20),

        // Pickup Note
        _buildTextArea(
          controller: _pickupNoteController,
          label: 'Pickup Note',
          hint: 'Enter any pickup instructions...',
        ),
        const SizedBox(height: 20),

        // Select Pre-Registered Consignee
        _buildConsigneeSearchField(),
        const SizedBox(height: 20),

        // Consignee Closing Time
        _buildTextField(
          controller: _consigneeClosingTimeController,
          label: 'Consignee Closing Time',
          hint: '11:30',
          suffixIcon: Icons.access_time,
          onTap: _selectConsigneeClosingTime,
        ),
        const SizedBox(height: 20),

        // Drop Note
        _buildTextArea(
          controller: _dropNoteController,
          label: 'Drop Note',
          hint: 'Enter any delivery instructions...',
        ),
        const SizedBox(height: 24),

        // Toggle Options
        _buildToggleOption('Express Delivery', _expressDelivery, (value) {
          setState(() {
            _expressDelivery = value;
          });
          // Trigger recalculation after state update
          Future.microtask(() {
            if (_pricingType == 'Fixed Price') {
              _calculateFixedPrice();
            } else {
          _calculatePrice();
            }
          });
        }),
        const SizedBox(height: 16),
        _buildToggleOption('Physical POD', _challanReturn, (value) {
          setState(() {
            _challanReturn = value;
          });
          // Trigger recalculation after state update
          Future.microtask(() {
            if (_pricingType == 'Fixed Price') {
              _calculateFixedPrice();
            } else {
          _calculatePrice();
            }
          });
        }),
        if (_challanReturn) ...[
          SizedBox(height: Responsive.spacing(context, 16)),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _challanFilePaths.isEmpty
                        ? 'No files selected'
                        : '${_challanFilePaths.length} file(s) selected',
                    style: TextStyle(
                      color: _challanFilePaths.isEmpty ? Colors.grey[600] : Colors.green[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickChallanFiles,
                    borderRadius: BorderRadius.circular(8),
                    child: const Center(
                      child: Text(
                        'Upload Challan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_challanFilePaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _challanFilePaths.asMap().entries.map((entry) {
                  final index = entry.key;
                  final filePath = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(filePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => _removeChallanFile(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
        _buildToggleOption('Collect COD', _collectCOD, (value) {
          setState(() {
            _collectCOD = value;
          });
          // Trigger recalculation after state update
          Future.microtask(() {
            if (_pricingType == 'Fixed Price') {
              _calculateFixedPrice();
            } else {
          _calculatePrice();
            }
          });
        }),
        if (_collectCOD) ...[
          SizedBox(height: Responsive.spacing(context, 16)),
          _buildTextField(
            controller: _codAmountController,
            label: 'COD Amount (Rs)',
            hint: 'Enter COD amount',
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 32),

        // Dimensions Section
        const Text(
          'Dimensions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 20),

        // Dimension Cards
        ..._dimensionList.asMap().entries.map((entry) {
          final index = entry.key;
          final dimension = entry.value;
          return _buildDimensionCard(dimension, index);
        }).toList(),

        // Add More Dimensions Button - Only show if less than 10 dimensions AND dimensions are available
        if (_dimensionList.length < 10 && 
            _fixedPriceDimensions.isNotEmpty && 
            !_areAllDimensionsSelected())
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: _addNewDimension,
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Text(
                  'Add More Dimensions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Weight & Price Summary
        Container(
          padding: const EdgeInsets.all(20.0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weight & Price Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, 20)),
              _buildSummaryRow('Total Units:', '${_totalUnits.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              _buildSummaryRow('Total Gross Weight:', '${_totalGrossWeight.toStringAsFixed(2)} kg'),
              const SizedBox(height: 12),
              _buildSummaryRow('Total Volumetric Weight:', '${_totalVolumetricWeight.toStringAsFixed(2)} kg'),
              const SizedBox(height: 12),
              _buildSummaryRow('Total Volume:', '${_totalVolume.toStringAsFixed(0)} cm³'),
              const SizedBox(height: 12),
              _buildSummaryRow('Chargeable Weight:', '${_chargeableWeight.toStringAsFixed(2)} kg', isHighlighted: true),
              SizedBox(height: Responsive.spacing(context, 24)),
              // Coupon Code Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discount Coupon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponCodeController,
                            enabled: _appliedCouponCode == null,
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_appliedCouponCode != null)
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _removeCoupon,
                                borderRadius: BorderRadius.circular(8),
                                child: const Center(
                                  child: Text(
                                    'Remove',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isValidatingCoupon ? null : _validateCoupon,
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: _isValidatingCoupon
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Apply',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_appliedCouponCode != null && _couponDiscountAmount != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Coupon $_appliedCouponCode applied! Discount: ₹$_couponDiscountAmount',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
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
              SizedBox(height: Responsive.spacing(context, 24)),
              const Text(
                'Price Calculation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, 20)),
              _buildSummaryRow('Transport Charges:', '₹${_transportAmount.toStringAsFixed(2)}'),
              if (_challanReturn) ...[
                Builder(
                  builder: (context) {
                    // Get challan charges from first dimension with selected dimension
                    double challanCharges = 0;
                    if (_dimensionList.isNotEmpty) {
                      final firstDim = _dimensionList.firstWhere(
                        (d) => d.selectedDimension != null,
                        orElse: () => _dimensionList.first,
                      );
                      if (firstDim.selectedDimension != null) {
                        challanCharges = double.tryParse(firstDim.selectedDimension!.chalaanReturnCharges) ?? 0;
                      }
                    }
                    return _buildSummaryRow('Physical POD Charges:', '₹${challanCharges.toStringAsFixed(2)}');
                  },
                ),
              ],
              if (_collectCOD)
                _buildSummaryRow('COD Charges:', '₹${_getCodChargeForFixedPrice().toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _buildSummaryRow('Sub Total:', '₹${_subTotalBeforeDiscount.toStringAsFixed(2)}'),
              if (_appliedCouponCode != null && _couponDiscountAmount != null) ...[
                const SizedBox(height: 12),
                _buildSummaryRow('Discount:', '-₹$_couponDiscountAmount', isHighlighted: false),
              ],
              if (_expressDelivery) ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    // Get express percentage from first dimension with selected dimension
                    double expressPercentage = 0;
                    if (_dimensionList.isNotEmpty) {
                      final firstDim = _dimensionList.firstWhere(
                        (d) => d.selectedDimension != null,
                        orElse: () => _dimensionList.first,
                      );
                      if (firstDim.selectedDimension != null) {
                        expressPercentage = double.tryParse(firstDim.selectedDimension!.expressDeliveryPercentage) ?? 0;
                      }
                    }
                    return _buildSummaryRow(
                      'Express Surcharge (${expressPercentage.toStringAsFixed(0)}%):',
                      '₹${_expressCharges.toStringAsFixed(2)}',
                    );
                  },
                ),
              ],
              if (_expressDelivery) ...[
                const SizedBox(height: 12),
                _buildSummaryRow('Gross Payable:', '₹${_preTaxAmount.toStringAsFixed(2)}'),
              ],
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  // Get GST percentage from first dimension with selected dimension
                  double gstPercentage = 18.0;
                  if (_dimensionList.isNotEmpty) {
                    final firstDim = _dimensionList.firstWhere(
                      (d) => d.selectedDimension != null,
                      orElse: () => _dimensionList.first,
                    );
                    if (firstDim.selectedDimension != null) {
                      gstPercentage = double.tryParse(firstDim.selectedDimension!.gstPercentage) ?? 18.0;
                    }
                  }
                  return _buildSummaryRow('GST (${gstPercentage.toStringAsFixed(0)}%):', '₹${_gstAmount.toStringAsFixed(2)}');
                },
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Final Payable:', '₹${_finalPayable.toStringAsFixed(2)}', isHighlighted: true),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmittingOrder ? null : _showOrderConfirmation,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: _isSubmittingOrder
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Order',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _resetForm();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Center(
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Handle bulk order
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Center(
                      child: Text(
                        'Bulk Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
      ],
    );
  }

  Widget _buildDynamicPriceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Commodity Field
        _buildCommodityDropdown(),
        const SizedBox(height: 20),

        // Select Pre-Registered Shipper
        _buildShipperSearchField(),
        const SizedBox(height: 20),

        // Preferred Pickup Date
        _buildTextField(
          controller: _pickupDateController,
          label: 'Preferred Pickup Date',
          hint: 'dd-mm-yyyy',
          suffixIcon: Icons.calendar_today,
          onTap: _selectPickupDate,
        ),
        const SizedBox(height: 20),

        // Preferred Pickup Time
        _buildPickupTimeDropdown(),
        const SizedBox(height: 20),

        // Pickup Note
        _buildTextArea(
          controller: _pickupNoteController,
          label: 'Pickup Note',
          hint: 'Enter any pickup instructions...',
        ),
        const SizedBox(height: 20),

        // Select Pre-Registered Consignee
        _buildConsigneeSearchField(),
        const SizedBox(height: 20),

        // Consignee Closing Time
        _buildTextField(
          controller: _consigneeClosingTimeController,
          label: 'Consignee Closing Time',
          hint: '11:30',
          suffixIcon: Icons.access_time,
          onTap: _selectConsigneeClosingTime,
        ),
        const SizedBox(height: 20),

        // Drop Note
        _buildTextArea(
          controller: _dropNoteController,
          label: 'Drop Note',
          hint: 'Enter any delivery instructions...',
        ),
        const SizedBox(height: 24),

        // Toggle Options
        _buildToggleOption('Express Delivery', _expressDelivery, (value) {
          setState(() {
            _expressDelivery = value;
          });
          // Trigger recalculation after state update
          Future.microtask(() {
            if (_pricingType == 'Fixed Price') {
              _calculateFixedPrice();
            } else {
          _calculatePrice();
            }
          });
        }),
        const SizedBox(height: 16),
        _buildToggleOption('Physical POD', _challanReturn, (value) {
          setState(() {
            _challanReturn = value;
          });
          // Trigger recalculation after state update
          Future.microtask(() {
            if (_pricingType == 'Fixed Price') {
              _calculateFixedPrice();
            } else {
          _calculatePrice();
            }
          });
        }),
        if (_challanReturn) ...[
          SizedBox(height: Responsive.spacing(context, 16)),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _challanFilePaths.isEmpty
                        ? 'No files selected'
                        : '${_challanFilePaths.length} file(s) selected',
                    style: TextStyle(
                      color: _challanFilePaths.isEmpty ? Colors.grey[600] : Colors.green[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickChallanFiles,
                    borderRadius: BorderRadius.circular(8),
                    child: const Center(
                      child: Text(
                        'Upload Challan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_challanFilePaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _challanFilePaths.asMap().entries.map((entry) {
                  final index = entry.key;
                  final filePath = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(filePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => _removeChallanFile(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
        _buildToggleOption('Collect COD', _collectCOD, (value) {
          setState(() {
            _collectCOD = value;
          });
          // Trigger recalculation after state update
          Future.microtask(() {
            if (_pricingType == 'Fixed Price') {
              _calculateFixedPrice();
            } else {
          _calculatePrice();
            }
          });
        }),
        if (_collectCOD) ...[
          SizedBox(height: Responsive.spacing(context, 16)),
          _buildTextField(
            controller: _codAmountController,
            label: 'COD Amount (Rs)',
            hint: 'Enter COD amount',
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 32),

        // Dimensions Section
        const Text(
          'Dimensions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 20),

        // Dynamic Dimension Cards
        ..._dynamicDimensionList.asMap().entries.map((entry) {
          final index = entry.key;
          final dimension = entry.value;
          return _buildDynamicDimensionCard(dimension, index);
                              }).toList(),

        // Add More Dimensions Button - Only show if less than 10 dimensions
        if (_dynamicDimensionList.length < 10)
            Container(
            width: double.infinity,
            height: 50,
              decoration: BoxDecoration(
                color: Colors.green,
              borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                onTap: _addNewDynamicDimension,
            borderRadius: BorderRadius.circular(12),
                child: const Center(
                  child: Text(
                    'Add More Dimensions',
                style: TextStyle(
                      color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                    ),
                        ),
                      ),
              ),
          ),
        ),
        const SizedBox(height: 32),

        // Weight & Price Summary
        Container(
          padding: const EdgeInsets.all(20.0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weight & Price Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, 20)),
              _buildSummaryRow('Total Units:', '${_totalUnits.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              _buildSummaryRow('Total Gross Weight:', '${_totalGrossWeight.toStringAsFixed(2)} kg'),
              const SizedBox(height: 12),
              _buildSummaryRow('Total Volumetric Weight:', '${_totalVolumetricWeight.toStringAsFixed(2)} kg'),
              const SizedBox(height: 12),
              _buildSummaryRow('Total Volume:', '${_totalVolume.toStringAsFixed(0)} cm³'),
              const SizedBox(height: 12),
              _buildSummaryRow('Chargeable Weight:', '${_chargeableWeight.toStringAsFixed(2)} kg', isHighlighted: true),
              SizedBox(height: Responsive.spacing(context, 24)),
              // Coupon Code Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discount Coupon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponCodeController,
                            enabled: _appliedCouponCode == null,
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_appliedCouponCode != null)
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _removeCoupon,
                                borderRadius: BorderRadius.circular(8),
                                child: const Center(
                                  child: Text(
                                    'Remove',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isValidatingCoupon ? null : _validateCoupon,
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: _isValidatingCoupon
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Apply',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_appliedCouponCode != null && _couponDiscountAmount != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Coupon $_appliedCouponCode applied! Discount: ₹$_couponDiscountAmount',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
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
              SizedBox(height: Responsive.spacing(context, 24)),
              const Text(
                'Price Calculation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, 20)),
              _buildSummaryRow('Transport Charges:', '₹${_transportAmount.toStringAsFixed(2)}'),
              if (_challanReturn) ...[
                Builder(
                  builder: (context) {
                    final challanCharges = _dynamicPriceConfig?.chalaanReturnCharges ?? 0;
                    return _buildSummaryRow('Physical POD Charges:', '₹${challanCharges.toStringAsFixed(2)}');
                  },
                ),
              ],
              if (_collectCOD) ...[
                Builder(
                  builder: (context) {
                    final codAmount = double.tryParse(_codAmountController.text) ?? 0;
                    double codCharges = 0;
                    if (codAmount > 0 && _dynamicPriceConfig != null) {
                      final codSlab = _dynamicPriceConfig!.codRanges.firstWhere(
                        (slab) => codAmount >= slab.range[0] && codAmount <= slab.range[1],
                        orElse: () => _dynamicPriceConfig!.codRanges.first,
                      );
                      codCharges = codSlab.charge;
                    }
                    return _buildSummaryRow('COD Charges:', '₹${codCharges.toStringAsFixed(2)}');
                  },
                ),
              ],
              const SizedBox(height: 12),
              _buildSummaryRow('Sub Total:', '₹${_subTotalAfterDiscount.toStringAsFixed(2)}'),
              if (_appliedCouponCode != null && _couponDiscountAmount != null) ...[
                const SizedBox(height: 12),
                _buildSummaryRow('Discount:', '-₹$_couponDiscountAmount', isHighlighted: false),
              ],
              if (_expressDelivery) ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final expressPercentage = _dynamicPriceConfig?.expressDeliverySurchargePercentage ?? 0;
                    return _buildSummaryRow(
                      'Express Surcharge (${expressPercentage.toStringAsFixed(0)}%):',
                      '₹${_expressCharges.toStringAsFixed(2)}',
                    );
                  },
                ),
              ],
              if (_expressDelivery) ...[
                const SizedBox(height: 12),
                _buildSummaryRow('Gross Payable:', '₹${_preTaxAmount.toStringAsFixed(2)}'),
              ],
              const SizedBox(height: 12),
              _buildSummaryRow('GST (${_dynamicPriceConfig?.gstPercentage.toStringAsFixed(0) ?? 18}%):', '₹${_gstAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _buildSummaryRow('Final Payable:', '₹${_finalPayable.toStringAsFixed(2)}', isHighlighted: true),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmittingOrder ? null : _showOrderConfirmation,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: _isSubmittingOrder
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Order',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _resetForm();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Center(
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Handle bulk order
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Center(
                      child: Text(
                        'Bulk Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
      ],
    );
  }

  Widget _buildPricingButton(String label, bool isSelected) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E3A8A),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
                  onTap: () {
                    setState(() {
                      _pricingType = label;
                      // Load saved dimensions when switching to Dynamic Price
                      if (label == 'Dynamic Price') {
                        if (_savedDimensions.isEmpty) {
                        _loadSavedDimensions();
                        }
                        _loadActiveDynamicPrice();
                        // Ensure at least one dimension is always present
                        if (_dynamicDimensionList.isEmpty) {
                          _addNewDynamicDimension();
                        }
                      }
                      // Load fixed price dimensions when switching to Fixed Price
                      if (label == 'Fixed Price') {
                        if (_fixedPriceDimensions.isEmpty) {
                        if (widget.fixedPriceDimensions.isNotEmpty) {
                          _fixedPriceDimensions = widget.fixedPriceDimensions;
                        } else {
                          _loadFixedPriceDimensions();
                          }
                        }
                        // Ensure at least one dimension is always present
                        if (_dimensionList.isEmpty) {
                          _addNewDimension();
                        }
                      }
                    });
                  },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? suffixIcon,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onTap: onTap,
        readOnly: onTap != null,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelStyle: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          suffixIcon: suffixIcon != null
              ? (onTap != null
                  ? InkWell(
                      onTap: onTap,
                      child: Icon(
                  suffixIcon,
                  color: Colors.grey[600],
                  size: 22,
                      ),
                )
                  : Icon(
                      suffixIcon,
                      color: Colors.grey[600],
                      size: 22,
                    ))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1E3A8A),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPickupTimeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPickupTime,
        decoration: InputDecoration(
          labelText: 'Preferred Pickup Time',
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelStyle: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintText: 'Choose a Time',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1E3A8A),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        items: _pickupTimeWindows.map((String time) {
          return DropdownMenuItem<String>(
            value: time,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedPickupTime = newValue;
            if (newValue != null) {
              _pickupTimeController.text = newValue;
            }
          });
        },
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.grey[600],
          size: 28,
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFixedPriceDimensionDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedFixedPriceDimension?.id,
        decoration: InputDecoration(
          labelText: 'Select Predefined Dimension',
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintText: _isLoadingFixedPriceDimensions
              ? 'Loading dimensions...'
              : '-- Select Predefined Dimension --',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1E3A8A),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        items: _isLoadingFixedPriceDimensions
            ? null
            : _fixedPriceDimensions.map((dimension) {
                return DropdownMenuItem<String>(
                  value: dimension.id,
                  child: Text(
                    dimension.dimensionName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
        onChanged: _isLoadingFixedPriceDimensions
            ? null
            : (String? newValue) {
                setState(() {
                  if (newValue != null) {
                    _selectedFixedPriceDimension = _fixedPriceDimensions.firstWhere(
                      (dim) => dim.id == newValue,
                    );
                    // Populate dimension fields
                    _lengthController.text = _selectedFixedPriceDimension!.length;
                    _breadthController.text = _selectedFixedPriceDimension!.breadth;
                    _heightController.text = _selectedFixedPriceDimension!.height;
                    _unitWeightController.text = _selectedFixedPriceDimension!.weight;
                    _unitsController.text = '1'; // Default to 1 unit
                    // Set charges from dimension
                    _chargesController.text = _selectedFixedPriceDimension!.dimensionCharge;
                  } else {
                    _selectedFixedPriceDimension = null;
                    _lengthController.clear();
                    _breadthController.clear();
                    _heightController.clear();
                    _unitWeightController.clear();
                    _unitsController.text = '1';
                    _chargesController.clear();
                  }
                });
                // Trigger price calculation
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _calculateFixedPrice();
          });
        },
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.grey[600],
          size: 28,
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.grey,
            size: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1E3A8A),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: 4,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelStyle: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1E3A8A),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildShipperSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _shipperController,
            focusNode: _shipperFocusNode,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Select Pre-Registered Shipper:',
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: 'Search Shipper',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              suffixIcon: _isSearchingShippers
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 22,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),
        ),
        // Show dropdown results
        if (_shipperResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _shipperResults.length,
              itemBuilder: (context, index) {
                final shipper = _shipperResults[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedShipperId = shipper.placeId; // Use placeId instead of id
                      _selectedShipper = shipper;
                      _shipperController.text = '${shipper.companyName} - ${shipper.contactPersonName}';
                      _shipperResults = [];
                    });
                    _shipperFocusNode.unfocus();
                    // Fetch DC closing time for the selected shipper
                    _loadDcClosingTime(shipper.placeId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipper.companyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${shipper.contactPersonName} • ${shipper.contactPersonMobile}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (shipper.placeId.isNotEmpty)
                          Text(
                            'Place ID: ${shipper.placeId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
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
    );
  }

  Widget _buildConsigneeSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _consigneeController,
            focusNode: _consigneeFocusNode,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Select Pre-Registered Consignee',
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: 'Search Consignee',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              suffixIcon: _isSearchingConsignees
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 22,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),
        ),
        // Show dropdown results
        if (_consigneeResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _consigneeResults.length,
              itemBuilder: (context, index) {
                final consignee = _consigneeResults[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedConsigneeId = consignee.placeId; // Use placeId instead of id
                      _selectedConsignee = consignee;
                      _consigneeController.text = '${consignee.companyName} - ${consignee.contactPersonName}';
                      _consigneeResults = [];
                    });
                    _consigneeFocusNode.unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consignee.companyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${consignee.contactPersonName} • ${consignee.contactPersonMobile}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (consignee.placeId.isNotEmpty)
                          Text(
                            'Place ID: ${consignee.placeId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
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
    );
  }

  Widget _buildCommodityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _commodityController,
            focusNode: _commodityFocusNode,
            enabled: true, // Always enabled to allow typing
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Commodity',
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: _commodities.isEmpty
                      ? 'No commodities available'
                      : 'Type to search commodity',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              suffixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 22,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),
        ),
        // Show dropdown results - only when field has focus or has text (like web)
        if (_filteredCommodities.isNotEmpty && 
            (_commodityFocusNode.hasFocus || _commodityController.text.isNotEmpty))
          Builder(
            builder: (context) {
              print('🔵 Rendering dropdown with ${_filteredCommodities.length} items, focus: ${_commodityFocusNode.hasFocus}, text: "${_commodityController.text}"');
              return Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: _filteredCommodities.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
              shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _filteredCommodities.length,
              itemBuilder: (context, index) {
                final commodity = _filteredCommodities[index];
                final isBlocked = _isCommodityBlocked(commodity);
                      print('🔵 Building item $index: ${commodity.name}');
                return InkWell(
                  onTap: isBlocked
                      ? null
                      : () {
                          // Remove listener temporarily to avoid triggering search
                          _commodityController.removeListener(_onCommoditySearch);
                          setState(() {
                            _selectedCommodityId = commodity.id;
                            _commodityController.text = commodity.name;
                            _filteredCommodities = [];
                          });
                          // Re-add listener after a short delay
                                Future.delayed(const Duration(milliseconds: 200), () {
                            if (mounted) {
                              _commodityController.addListener(_onCommoditySearch);
                              _commodityFocusNode.unfocus();
                            }
                          });
                        },
                        child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            commodity.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isBlocked
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (isBlocked)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.block,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
              );
            },
          ),
      ],
    );
  }

  String _getPlaceholderForLabel(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('length')) {
      return 'Enter length';
    } else if (lowerLabel.contains('breadth')) {
      return 'Enter breadth';
    } else if (lowerLabel.contains('height')) {
      return 'Enter height';
    } else if (lowerLabel.contains('weight')) {
      return 'Enter weight';
    } else if (lowerLabel.contains('units')) {
      return 'Enter units';
    } else if (lowerLabel.contains('charges')) {
      return 'Enter charges';
    }
    return '';
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: readOnly ? Colors.grey[600] : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: _getPlaceholderForLabel(label),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          floatingLabelStyle: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1E3A8A),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey[100] : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1E3A8A),
          ),
        ],
      ),
    );
  }

}

