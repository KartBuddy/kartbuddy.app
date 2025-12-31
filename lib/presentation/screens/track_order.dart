import 'package:flutter/material.dart';
import 'customer_home.dart';
import 'customer_wallet.dart';
import 'place_order.dart';
import 'my_orders.dart';
import 'place_manager.dart';
import 'support.dart';
import 'user_profile.dart';
import 'tracking_status.dart';
import '../../auth/login.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../models/orders_model.dart';

class TrackOrder extends StatefulWidget {
  const TrackOrder({super.key});

  @override
  State<TrackOrder> createState() => _TrackOrderState();
}

class _TrackOrderState extends State<TrackOrder> {
  final TextEditingController _orderIdController = TextEditingController();
  final FocusNode _orderIdFocusNode = FocusNode();
  String _userName = 'User';
  String _userInitial = 'U';
  String _userFullName = 'User';
  String _userEmail = '';
  
  List<Order> _allOrders = [];
  List<String> _orderSuggestions = [];
  bool _showSuggestions = false;
  bool _isLoadingOrders = false;
  final AuthService _authService = AuthService();
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrders();
    _orderIdController.addListener(_onOrderIdChanged);
    _orderIdFocusNode.addListener(_onFocusChanged);
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
    _orderIdController.removeListener(_onOrderIdChanged);
    _orderIdFocusNode.removeListener(_onFocusChanged);
    _orderIdController.dispose();
    _orderIdFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoadingOrders = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingOrders = false;
          });
        }
        return;
      }

      // Get customer ID from customer details
      final customerResponse = await _authService.getCustomerDetails(token);
      final customerId = customerResponse.data.customerId;

      // Fetch orders
      print('🔵 Fetching orders for autocomplete...');
      final ordersResponse = await _authService.getCustomerOrders(customerId, token);
      
      if (mounted) {
        setState(() {
          _allOrders = ordersResponse.data;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
      }
    }
  }

  void _onOrderIdChanged() {
    final query = _orderIdController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _orderSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Filter orders that match the query
    final matchingOrders = _allOrders.where((order) {
      return order.orderId.toLowerCase().contains(query) ||
          order.pickupSnapshot.companyName.toLowerCase().contains(query) ||
          order.dropSnapshot.companyName.toLowerCase().contains(query);
    }).toList();

    // Get order IDs and limit to 5 suggestions
    final suggestions = matchingOrders
        .map((order) => order.orderId)
        .take(5)
        .toList();

    setState(() {
      _orderSuggestions = suggestions;
      _showSuggestions = _orderIdFocusNode.hasFocus && suggestions.isNotEmpty;
    });
  }

  void _onFocusChanged() {
    final query = _orderIdController.text.trim().toLowerCase();
    setState(() {
      _showSuggestions = _orderIdFocusNode.hasFocus && 
          query.isNotEmpty && 
          _orderSuggestions.isNotEmpty;
    });
  }

  void _selectOrderId(String orderId) {
    _orderIdController.text = orderId;
    _orderIdController.selection = TextSelection.fromPosition(
      TextPosition(offset: orderId.length),
    );
    setState(() {
      _showSuggestions = false;
    });
    _orderIdFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Card
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Title
                    const Text(
                      'Track Your Order',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Instruction
                    Text(
                      'Please enter your order ID to track your shipment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Order ID Input with Autocomplete
                    CompositedTransformTarget(
                      link: _layerLink,
                      child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _orderIdController,
                          focusNode: _orderIdFocusNode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter Order ID',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.normal,
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
                            suffixIcon: _isLoadingOrders
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    // Suggestions Dropdown
                    if (_showSuggestions && _orderSuggestions.isNotEmpty)
                      CompositedTransformFollower(
                        link: _layerLink,
                        showWhenUnlinked: false,
                        offset: const Offset(0, 60),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _orderSuggestions.length,
                              itemBuilder: (context, index) {
                                final orderId = _orderSuggestions[index];
                                return InkWell(
                                  onTap: () => _selectOrderId(orderId),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.search,
                                          size: 20,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            orderId,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
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
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Track Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final orderId = _orderIdController.text.trim();
                              if (orderId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter an Order ID'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => TrackingStatus(orderId: orderId),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: const Center(
                              child: Text(
                                'Track Order',
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
              ),
            ],
          ),
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
                  isActive: false,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PlaceManager()),
                    );
                  },
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
              isActive: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.store,
              label: 'Place Manager',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PlaceManager()),
                );
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
}

