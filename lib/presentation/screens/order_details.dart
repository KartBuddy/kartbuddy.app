import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../models/orders_model.dart';
import '../../models/order_history_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../auth/login.dart';
import 'customer_home.dart';
import 'customer_wallet.dart';
import 'place_order.dart';
import 'my_orders.dart';
import 'track_order.dart';
import 'place_manager.dart';
import 'support.dart';
import 'user_profile.dart';

class OrderDetails extends StatefulWidget {
  final Order order;

  const OrderDetails({super.key, required this.order});

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  String _userName = 'User';
  String _userInitial = 'U';
  String _userFullName = 'User';
  String _userEmail = '';
  List<OrderHistoryEvent> _orderHistory = [];
  bool _isLoadingHistory = false;
  Order? _fullOrder; // Store the full order with complete details
  bool _isLoadingOrder = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrderHistory();
    _loadFullOrderDetails(); // Fetch full order details with dimensions
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

  Future<void> _loadOrderHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final token = await UserService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Fetching order history for order: ${widget.order.orderId}');
      final response = await _authService.getOrderHistory(widget.order.orderId, token);

      if (mounted) {
        setState(() {
          _orderHistory = response.data;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('❌ Error loading order history: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _loadFullOrderDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingOrder = true;
    });

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        print('⚠️ Token or customer not found, using passed order data');
        setState(() {
          _isLoadingOrder = false;
        });
        return;
      }

      print('🔵 Fetching full order details for: ${widget.order.orderId}');
      // Fetch all orders and find the matching one to get full details
      final response = await _authService.getCustomerOrders(customer.id, token);
      
      final foundOrder = response.data.firstWhere(
        (order) => order.orderId == widget.order.orderId || order.id == widget.order.id,
        orElse: () => widget.order, // Fallback to passed order if not found
      );

      print('🔵 Found order with ${foundOrder.dimensions.length} dimensions');
      print('🔵 Order total_units: ${foundOrder.totalUnits}');
      print('🔵 Order total_gross_weight: ${foundOrder.totalGrossWeight}');

      if (mounted) {
        setState(() {
          _fullOrder = foundOrder;
          _isLoadingOrder = false;
        });
      }
    } catch (e) {
      print('❌ Error loading full order details: $e');
      if (mounted) {
        setState(() {
          _isLoadingOrder = false;
        });
      }
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = date.hour >= 12 ? 'pm' : 'am';
      return '${date.day}/${date.month}/${date.year}, $hour:$minute $amPm';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStatusBadge(String status) {
    final statusLower = status.toLowerCase();
    Color backgroundColor;
    
    if (statusLower == 'delivered') {
      backgroundColor = Colors.green;
    } else if (statusLower == 'pending') {
      backgroundColor = Colors.orange;
    } else {
      backgroundColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color iconColor) {
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

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use full order details if available, otherwise use passed order
    final order = _fullOrder ?? widget.order;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber, width: 2),
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
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    'Hi, $_userName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
            // Order Header
            Container(
              padding: const EdgeInsets.all(20),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Order #${order.orderId}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(order.orderStatus),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Coming Soon'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Flexible(
                            child: Text(
                              'Download Invoice',
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Placed on: ${_formatDateTime(order.orderCreationDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Order Information
            _buildSectionTitle('1. Order Information', Icons.info_outline, Colors.blue),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildInfoCard('Order ID', order.orderId)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Order Status', order.formattedStatus)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Order Date', _formatDateTime(order.orderCreationDate))),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoCard('Last Updated', _formatDateTime(order.updatedAt)),
            const SizedBox(height: 32),

            // 2. Shipper Details
            _buildSectionTitle('2. Shipper Details', Icons.location_on, Colors.red),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildInfoCard('Place ID', order.pickupPlaceId)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Company Name', order.pickupSnapshot.companyName)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Contact Person', order.pickupSnapshot.contactPerson)),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoCard('Address', order.pickupSnapshot.address),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoCard('Contact Mobile', order.pickupSnapshot.contactMobile.toString())),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Latitude', order.pickupLatitude)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Longitude', order.pickupLongitude)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoCard('Pickup Time', order.preferredPickupTime)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Pickup Note', order.pickupNote)),
              ],
            ),
            const SizedBox(height: 32),

            // 3. Customer Challan
            _buildSectionTitle('3. Customer Challan', Icons.description, Colors.orange),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Challan Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.challanFiles.isEmpty ? 'No challan details available' : 'Challan files available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Challan Documents',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (order.challanFiles.isEmpty)
                    Text(
                      'No challan documents available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: order.challanFiles.map((file) => _buildImageThumbnail(file)).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 4. Proof of Pickup
            _buildSectionTitle('4. Proof of Pickup', Icons.local_shipping, Colors.green),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Proof',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (order.proofOfPickup.isEmpty)
                    Text(
                      'No proof of pickup files available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: order.proofOfPickup.map((file) => _buildImageThumbnail(file)).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 5. Consignee Details
            _buildSectionTitle('5. Consignee Details', Icons.local_shipping, Colors.green),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildInfoCard('Place ID', order.dropPlaceId)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Company Name', order.dropSnapshot.companyName)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Contact Person', order.dropSnapshot.contactPerson)),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoCard('Address', order.dropSnapshot.address),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoCard('Contact Mobile', order.dropSnapshot.contactMobile.toString())),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Latitude', order.dropLatitude)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Longitude', order.dropLongitude)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInfoCard('Closing Time', order.consigneeClosingTime)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Drop Note', order.dropNote)),
              ],
            ),
            const SizedBox(height: 32),

            // 6. Proof of Delivery
            _buildSectionTitle('6. Proof of Delivery', Icons.local_shipping, Colors.green),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Proof',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (order.proofOfDelivery.isEmpty)
                    Text(
                      'No proof of delivery files available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: order.proofOfDelivery.map((file) => _buildImageThumbnail(file)).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 7. POD Challan
            _buildSectionTitle('7. POD Challan', Icons.description, Colors.orange),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'POD Challan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (order.podChallan.isEmpty)
                    Text(
                      'No POD challan files available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: order.podChallan.map((file) => _buildImageThumbnail(file)).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 8. Dimensions
            _buildSectionTitle('8. Dimensions', Icons.straighten, Colors.green),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: _buildTableHeader('#'),
                          ),
                          SizedBox(
                            width: 100,
                            child: _buildTableHeader('LENGTH (CM)'),
                          ),
                          SizedBox(
                            width: 100,
                            child: _buildTableHeader('BREADTH (CM)'),
                          ),
                          SizedBox(
                            width: 100,
                            child: _buildTableHeader('HEIGHT (CM)'),
                          ),
                          SizedBox(
                            width: 80,
                            child: _buildTableHeader('UNITS'),
                          ),
                          SizedBox(
                            width: 120,
                            child: _buildTableHeader('PER UNIT WT (KG)'),
                          ),
                          SizedBox(
                            width: 120,
                            child: _buildTableHeader('TOTAL WT (KG)'),
                          ),
                          SizedBox(
                            width: 140,
                            child: _buildTableHeader('TOTAL VOLUME (CM³)'),
                          ),
                          SizedBox(
                            width: 100,
                            child: _buildTableHeader('CHARGE/UNIT'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Table Rows
                  ...order.dimensions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dim = entry.value;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text('${index + 1}'),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text('${dim.length}'),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text('${dim.breadth}'),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text('${dim.height}'),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text('${dim.units}'),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text('${dim.perUnitWeight.toStringAsFixed(2)}'),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text('${dim.totalWeight.toStringAsFixed(2)}'),
                            ),
                            SizedBox(
                              width: 140,
                              child: Text('${dim.totalVolume.toString()}'),
                            ),
                            SizedBox(
                              width: 100,
                              child: const Text('N/A'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 9. Shipment Summary
            _buildSectionTitle('9. Shipment Summary', Icons.inventory_2, Colors.pink),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Commodity', order.commodity.isEmpty ? '[]' : order.commodity),
                  _buildSummaryRow('Total Units', '${order.totalUnits} Units'),
                  _buildSummaryRow('Total Gross Weight', '${order.totalGrossWeight} KG'),
                  _buildSummaryRow('Total Volumetric Weight', '${order.totalVolWeight} KG'),
                  _buildSummaryRow('Total Volume', '${order.totalVolume} cm³'),
                  _buildSummaryRow('Chargeable Weight', '${order.chargeableWeight} KG'),
                  _buildSummaryRow('Transport Charges', '₹${order.transportationCharges}'),
                  if (order.expressDelivery)
                    _buildSummaryRow('Express Delivery', '₹${order.expressCharges}'),
                  if (order.challanReturn)
                    _buildSummaryRow('Challan Return', '₹${order.challanCharges}'),
                  if (order.codCollection)
                    _buildSummaryRow('COD Charges', '₹${order.codCharges}'),
                  _buildSummaryRow('Applied Coupon', order.appliedCoupon ?? 'N/A'),
                  _buildSummaryRow('Coupon Discount', '-₹${order.couponDiscount}'),
                  _buildSummaryRow('Pre-Tax Amount', '₹${order.preTaxAmount}'),
                  _buildSummaryRow('GST (${order.gstPercentage}%)', '₹${order.gstAmount}'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Final Payable',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '₹${order.finalPayable}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 10. Order Footprints
            _buildSectionTitle('10. Order Footprints', Icons.history, Colors.blue),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _buildTableHeader('TIMESTAMP')),
                        Expanded(flex: 2, child: _buildTableHeader('EVENT')),
                        Expanded(flex: 2, child: _buildTableHeader('REMARKS')),
                        Expanded(flex: 2, child: _buildTableHeader('ACTIVITY BY')),
                        Expanded(flex: 1, child: _buildTableHeader('DETAILS')),
                      ],
                    ),
                  ),
                  // Order History Rows
                  if (_isLoadingHistory)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_orderHistory.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: const Center(
                        child: Text(
                          'No order history available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._orderHistory.map((event) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              event.formatTimestamp(event.timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              event.formattedEventType,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              event.remarks,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              event.activityBy,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: TextButton(
                              onPressed: () {
                                _showEventDetails(event);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Color(0xFF1E3A8A)),
                                  SizedBox(width: 4),
                                  Text(
                                    'View',
                                    style: TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(OrderHistoryEvent event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(event.formattedEventType),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Timestamp', event.formatTimestamp(event.timestamp)),
                _buildDetailRow('Event Type', event.formattedEventType),
                _buildDetailRow('Remarks', event.remarks),
                _buildDetailRow('Activity By', event.activityBy),
                if (event.eventDetails.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Event Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...event.eventDetails.entries.map((entry) => 
                    _buildDetailRow(entry.key.replaceAll('_', ' ').toUpperCase(), entry.value.toString())
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey[800],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String filePath) {
    // Construct proper URL - try multiple patterns
    String imageUrl;
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      // Already a full URL
      imageUrl = filePath;
    } else if (filePath.startsWith('/')) {
      // Path starts with /, try without /api/ first (like profile pictures)
      imageUrl = 'https://api.kartbuddy.in${filePath}';
    } else {
      // Relative path, try without /api/ first (like profile pictures)
      imageUrl = 'https://api.kartbuddy.in/$filePath';
    }
    
    print('🔵 Loading image: $imageUrl');
    
    return GestureDetector(
      onTap: () {
        _showImageDialog(imageUrl);
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<Uint8List?>(
            future: _loadImageWithAuth(imageUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              
              if (snapshot.hasError || snapshot.data == null) {
                print('❌ Error loading image: $imageUrl - ${snapshot.error}');
                return Container(
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Failed to load',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _loadImageWithAuth(String imageUrl) async {
    try {
      final token = await UserService.getToken();
      if (token == null) {
        print('❌ No authentication token available');
        return null;
      }

      // Try the original URL first
      print('🔵 Fetching image with auth: $imageUrl');
      var response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'image/*',
        },
      ).timeout(const Duration(seconds: 10));

      // If 404, try alternative URL patterns
      if (response.statusCode == 404) {
        // Try with /api/ prefix
        String altUrl = imageUrl.replaceFirst('https://api.kartbuddy.in/', 'https://api.kartbuddy.in/api/');
        if (altUrl != imageUrl && !imageUrl.contains('/api/')) {
          print('🔵 Trying alternative URL 1 (with /api/): $altUrl');
          response = await http.get(
            Uri.parse(altUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'image/*',
            },
          ).timeout(const Duration(seconds: 10));
        }
        
        // If still 404, try with /uploads/ prefix
        if (response.statusCode == 404) {
          String altUrl2 = imageUrl.replaceFirst('https://api.kartbuddy.in/', 'https://api.kartbuddy.in/uploads/');
          if (altUrl2 != imageUrl && !imageUrl.contains('/uploads/')) {
            print('🔵 Trying alternative URL 2 (with /uploads/): $altUrl2');
            response = await http.get(
              Uri.parse(altUrl2),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'image/*',
              },
            ).timeout(const Duration(seconds: 10));
          }
        }
        
        // If still 404, try /api/uploads/ prefix
        if (response.statusCode == 404) {
          String altUrl3 = imageUrl.replaceFirst('https://api.kartbuddy.in/', 'https://api.kartbuddy.in/api/uploads/');
          if (altUrl3 != imageUrl && !imageUrl.contains('/api/uploads/')) {
            print('🔵 Trying alternative URL 3 (with /api/uploads/): $altUrl3');
            response = await http.get(
              Uri.parse(altUrl3),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'image/*',
              },
            ).timeout(const Duration(seconds: 10));
          }
        }
      }

      if (response.statusCode == 200) {
        print('✅ Image loaded successfully');
        return response.bodyBytes;
      } else {
        print('❌ Failed to load image: Status ${response.statusCode}');
        print('❌ Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching image: $e');
      return null;
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: FutureBuilder<Uint8List?>(
                  future: _loadImageWithAuth(imageUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    if (snapshot.hasError || snapshot.data == null) {
                      print('❌ Error loading image in dialog: $imageUrl - ${snapshot.error}');
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Failed to load image',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                imageUrl,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E3A8A),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
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
              isActive: true,
              onTap: () {
                Navigator.pop(context);
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
        leading: Icon(icon, color: Colors.white, size: 24),
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
}

