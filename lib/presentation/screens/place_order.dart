import 'package:flutter/material.dart';
import 'book_partload.dart';
import 'customer_home.dart';
import 'customer_wallet.dart';
import 'my_orders.dart';
import 'track_order.dart';
import 'place_manager.dart';
import 'support.dart';
import 'user_profile.dart';
import '../../auth/login.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class PlaceOrder extends StatefulWidget {
  const PlaceOrder({super.key});

  @override
  State<PlaceOrder> createState() => _PlaceOrderState();
}

class _PlaceOrderState extends State<PlaceOrder> {
  String _userName = 'User';
  String _userInitial = 'U';
  String _userFullName = 'User';
  String _userEmail = '';
  String _walletBalance = '0.00';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWalletBalance();
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

  Future<void> _loadWalletBalance() async {
    try {
      final token = await UserService.getToken();
      if (token != null) {
        print('🔵 Fetching wallet balance for Place Order page...');
        final customerDetails = await _authService.getCustomerDetails(token);
        if (mounted) {
          setState(() {
            _walletBalance = customerDetails.data.walletBalance ?? '0.00';
          });
        }
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

  Future<void> _handleBookPartload() async {
    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        _showErrorDialog('Authentication token or customer ID not found.');
        return;
      }

      print('🔵 Checking fixed price access for customer: ${customer.id}');
      final response = await _authService.getFixedPriceDimensions(customer.id, token);

      print('✅ Fixed price access check completed');
      print('✅ Has fixed price access: ${response.data.isNotEmpty}');
      print('✅ Dimensions count: ${response.data.length}');

      if (mounted) {
        // Navigate to BookPartload page with fixed price access info
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookPartload(
              hasFixedPriceAccess: response.data.isNotEmpty,
              fixedPriceDimensions: response.data,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error checking fixed price access: $e');
      if (mounted) {
        // If API fails, default to showing only Dynamic Price
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const BookPartload(
              hasFixedPriceAccess: false,
            ),
          ),
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
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
      drawer: _buildDrawer(context),
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Wallet Balance at top right
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Large Package Icon
                    Icon(
                      Icons.inventory_2,
                      size: 120,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(height: 32),

                    // Place Your Order Text
                    const Text(
                      'Place Your Order',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Book Partload Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await _handleBookPartload();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: const Center(
                            child: Text(
                              'Book Partload',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
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

  Widget _buildDrawer(BuildContext context) {
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
              isActive: true,
              onTap: () {
                Navigator.pop(context);
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

