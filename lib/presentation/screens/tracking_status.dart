import 'package:flutter/material.dart';
import '../../models/orders_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../widgets/customer_sidebar.dart';

class TrackingStatus extends StatefulWidget {
  final String orderId;

  const TrackingStatus({super.key, required this.orderId});

  @override
  State<TrackingStatus> createState() => _TrackingStatusState();
}

class _TrackingStatusState extends State<TrackingStatus> {
  Order? _order;
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        throw Exception('Authentication token or customer ID not found.');
      }

      print('🔵 Fetching orders for tracking: ${customer.id}');
      final response = await _authService.getCustomerOrders(customer.id, token);

      // Find the order by order ID
      final foundOrder = response.data.firstWhere(
        (order) => order.orderId.toUpperCase() == widget.orderId.toUpperCase(),
        orElse: () => throw Exception('Order not found'),
      );

      if (mounted) {
        setState(() {
          _order = foundOrder;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading order: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  int _getCurrentStepIndex(String status) {
    final statusLower = status.toLowerCase();
    
    if (statusLower == 'delivered') {
      return 6; // All steps completed
    } else if (statusLower == 'in_transit' || statusLower == 'in transit') {
      return 5; // In Transit
    } else if (statusLower == 'picked' || statusLower == 'order_picked') {
      return 4; // Order Picked
    } else if (statusLower == 'out_for_pickup' || statusLower == 'out for pickup') {
      return 3; // Out for Pickup
    } else if (statusLower == 'driver_assigned' || statusLower == 'driver assigned') {
      return 2; // Driver Assigned
    } else if (statusLower == 'accepted' || statusLower == 'order_accepted') {
      return 1; // Order Accepted
    } else if (statusLower == 'cancelled' || statusLower == 'canceled') {
      // For cancelled orders, both Order Generated and Order Accepted are completed
      return 1; // Order Accepted (both steps 0 and 1 are completed)
    } else {
      // For pending or any other status, at least Order Generated is completed
      // If order exists, it must have been generated, so return 0 (Order Generated completed)
      return 0; // Order Generated (completed)
    }
  }

  List<String> _getProgressSteps() {
    return [
      'Order Generated',
      'Order Accepted',
      'Driver Assigned',
      'Out for Pickup',
      'Order Picked',
      'In Transit',
      'Delivered',
    ];
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'N/A';
    return status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
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
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to track order page
              },
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () => Scaffold.of(context).openDrawer(),
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
      ),
      drawer: const CustomerSidebar(currentScreen: 'track_order'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
            )
          : _order == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Order not found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title and Track Another Order link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Order Tracking',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Track Another Order',
                                style: TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Order Information Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order ID: ${_order!.orderId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Status: ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _order!.orderStatus.toLowerCase() == 'delivered'
                                          ? Colors.green
                                          : _order!.orderStatus.toLowerCase() == 'pending'
                                              ? Colors.orange
                                              : _order!.orderStatus.toLowerCase() == 'cancelled' || _order!.orderStatus.toLowerCase() == 'canceled'
                                                  ? Colors.grey
                                                  : Colors.blue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _formatStatus(_order!.orderStatus),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Delivery Progress Section
                        const Text(
                          'Delivery Progress',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Progress Steps
                        ..._buildProgressSteps(),
                      ],
                    ),
                  ),
                ),
    );
  }

  List<Widget> _buildProgressSteps() {
    final steps = _getProgressSteps();
    final currentStepIndex = _getCurrentStepIndex(_order!.orderStatus);
    final statusLower = _order!.orderStatus.toLowerCase();
    final isCancelled = statusLower == 'cancelled' || statusLower == 'canceled';
    final List<Widget> widgets = [];

    // For cancelled orders, show only Order Generated with red X icon
    if (isCancelled) {
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Icon with Red X
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    border: Border.all(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                // Red Vertical Line extending down
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.red,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Step Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[0], // Order Generated
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order cancelled',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      );
      return widgets;
    }

    // For non-cancelled orders, show normal progress
    for (int i = 0; i < steps.length; i++) {
      final isCompleted = i <= currentStepIndex;
      final isCurrent = i == currentStepIndex;

      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Icon/Number
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    border: Border.all(
                      color: isCompleted ? Colors.green : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // Vertical Line
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 60,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Step Text
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: i < steps.length - 1 ? 0 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? Colors.green : Colors.grey[700],
                      ),
                    ),
                    if (i < steps.length - 1) const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return widgets;
  }
}

