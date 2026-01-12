import 'package:flutter/material.dart';
import '../../models/order_tracking_model.dart';
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
  OrderTrackingData? _trackingData;
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  Future<void> _loadTracking() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await UserService.getToken();
      
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('🔵 Fetching tracking for order: ${widget.orderId}');
      final response = await _authService.getOrderTracking(widget.orderId, token);

      if (mounted) {
        setState(() {
          _trackingData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading tracking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  String _getOrderStatus() {
    if (_trackingData == null || _trackingData!.tracking.isEmpty) {
      return 'pending';
    }
    
    // Find the last completed step
    final completedSteps = _trackingData!.tracking.where((step) => step.isCompleted).toList();
    if (completedSteps.isEmpty) {
      return 'pending';
    }
    
    final lastStep = completedSteps.last;
    final key = lastStep.key.toLowerCase();
    
    if (key == 'order_delivered') {
      return 'delivered';
    } else if (key == 'out_for_delivery') {
      return 'in_transit';
    } else if (key == 'order_picked') {
      return 'picked';
    } else if (key == 'out_for_pickup') {
      return 'out_for_pickup';
    } else if (key == 'driver_assigned') {
      return 'driver_assigned';
    } else if (key == 'order_accepted') {
      return 'accepted';
    } else {
      return 'pending';
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
          : _trackingData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Order tracking not found'),
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
                                'Order ID: ${_trackingData!.orderId}',
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
                                      color: _getOrderStatus().toLowerCase() == 'delivered'
                                          ? Colors.green
                                          : _getOrderStatus().toLowerCase() == 'pending'
                                              ? Colors.orange
                                              : Colors.blue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getOrderStatus().toUpperCase().replaceAll('_', ' '),
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
    if (_trackingData == null || _trackingData!.tracking.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No tracking information available'),
          ),
        ),
      ];
    }

    final List<Widget> widgets = [];
    final trackingSteps = _trackingData!.tracking;

    for (int i = 0; i < trackingSteps.length; i++) {
      final step = trackingSteps[i];
      final isCompleted = step.isCompleted;
      final isLast = i == trackingSteps.length - 1;

      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Icon
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
                if (!isLast)
                  Container(
                    width: 2,
                    height: step.meta?.text != null ? 80 : 60,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Step Text and Meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                      color: isCompleted ? Colors.green : Colors.grey[700],
                    ),
                  ),
                  if (step.meta?.text != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.meta!.text!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (!isLast) SizedBox(height: step.meta?.text != null ? 40 : 60),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return widgets;
  }
}

