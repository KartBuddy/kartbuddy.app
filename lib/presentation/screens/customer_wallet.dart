import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'customer_home.dart';
import 'place_order.dart';
import 'my_orders.dart';
import 'track_order.dart';
import 'place_manager.dart';
import 'support.dart';
import 'user_profile.dart';
import 'wallet_history.dart';
import 'manual_recharge.dart';
import '../../auth/login.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/tour_guide_service.dart';
import '../../models/wallet_transaction_model.dart';

class CustomerWallet extends StatefulWidget {
  const CustomerWallet({super.key});

  @override
  State<CustomerWallet> createState() => _CustomerWalletState();
}

class _CustomerWalletState extends State<CustomerWallet> {
  final TextEditingController _amountController = TextEditingController();
  String _userName = 'User';
  String _userInitial = 'U';
  String _userFullName = 'User';
  String _userEmail = '';
  String _walletBalance = '0.00';
  List<WalletTransaction> _transactions = [];
  bool _isLoadingTransactions = false;
  final AuthService _authService = AuthService();
  late Razorpay _razorpay;
  bool _isProcessingPayment = false;
  String? _currentOrderId;
  int? _currentAmount;

  // Tour guide keys
  final GlobalKey _balanceKey = GlobalKey();
  final GlobalKey _rechargeKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();
  final GlobalKey _transactionsKey = GlobalKey();
  
  TutorialCoachMark? _tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadUserData();
    _loadWalletHistory();
    _checkAndShowTour();
  }

  Future<void> _checkAndShowTour() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final shouldShow = await TourGuideService.shouldShowPageTour(TourGuideService.walletTour);
    if (shouldShow && mounted) {
      _showTutorial();
    }
  }

  void _showTutorial() {
    final targets = [
      TargetFocus(
        identify: "balance",
        keyTarget: _balanceKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                context,
                controller,
                "Wallet Balance",
                "This shows your current wallet balance. Use your wallet to pay for orders quickly!",
                isFirst: true,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "recharge",
        keyTarget: _rechargeKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTourContent(
                context,
                controller,
                "Add Money",
                "Enter an amount and tap 'Add Money' to recharge your wallet using Razorpay. You can also use gift codes!",
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "history",
        keyTarget: _historyKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                context,
                controller,
                "Full History",
                "Click here to view your complete wallet transaction history.",
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "transactions",
        keyTarget: _transactionsKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTourContent(
                context,
                controller,
                "Recent Transactions",
                "Here you can see your latest wallet transactions including recharges and payments.",
                isLast: true,
              );
            },
          ),
        ],
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      paddingFocus: 10,
      opacityShadow: 0.8,
      hideSkip: true, // Hide the external skip button
      onFinish: () {
        TourGuideService.completePageTour(TourGuideService.walletTour);
      },
      onSkip: () {
        TourGuideService.completePageTour(TourGuideService.walletTour);
        return true;
      },
    );
    _tutorialCoachMark?.show(context: context);
  }

  Widget _buildTourContent(
    BuildContext context,
    TutorialCoachMarkController controller,
    String title,
    String description, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 40,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Color(0xFF1E3A8A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isLast)
                  TextButton(
                    onPressed: () => controller.skip(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text(
                      "Skip Tour",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (!isLast) const Spacer(),
                ElevatedButton(
                  onPressed: () => isLast ? controller.next() : controller.next(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isLast ? "Got it!" : "Next",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _loadUserData() async {
    final displayName = await UserService.getUserDisplayName();
    final fullName = await UserService.getUserFullName();
    final email = await UserService.getUserEmail();
    final initial = await UserService.getUserInitial();
    
    // Load wallet balance from customer details
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
    
    if (mounted) {
      setState(() {
        _userName = displayName;
        _userFullName = fullName;
        _userEmail = email;
        _userInitial = initial;
      });
    }
  }

  Future<void> _loadWalletHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        throw Exception('Authentication token or customer ID not found.');
      }

      print('🔵 Fetching wallet history for customer: ${customer.id}');
      final response = await _authService.getWalletHistory(customer.id, token);

      if (mounted) {
        setState(() {
          _transactions = response.data;
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      print('❌ Error loading wallet history: $e');
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  Future<void> _handleRecharge() async {
    final amount = _amountController.text.trim();
    
    if (amount.isEmpty) {
      _showErrorDialog('Please enter an amount');
      return;
    }

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue < 1) {
      _showErrorDialog('Amount must be at least ₹1');
      return;
    }

    try {
      final token = await UserService.getToken();
      final customer = await UserService.getCustomer();
      
      if (token == null || customer == null) {
        throw Exception('Authentication token or customer ID not found.');
      }

      // API expects amount in rupees as a number (it converts to paise internally)
      final amountInRupees = amountValue.toInt();

      print('🔵 Creating Razorpay order for amount: ₹$amount');
      final response = await _authService.createRazorpayOrder(
        amountInRupees,
        customer.id,
        token,
      );

      print('✅ Razorpay order created: ${response.orderId}');
      print('✅ Amount: ₹${response.amount / 100}');
      print('✅ Key ID: ${response.keyId}');

      // Store order details for verification
      _currentOrderId = response.orderId;
      _currentAmount = response.amount;

      // Open Razorpay checkout
      if (mounted) {
        setState(() {
          _isProcessingPayment = true;
        });

        final options = {
          'key': response.keyId,
          'amount': response.amount, // Amount in paise
          'name': 'KartBuddy',
          'description': 'Wallet Recharge',
          'order_id': response.orderId,
          'prefill': {
            'contact': customer.mobileNumber ?? '',
            'email': customer.email ?? _userEmail,
          },
          'external': {
            'wallets': ['paytm']
          }
        };

        try {
          _razorpay.open(options);
        } catch (e) {
          print('❌ Error opening Razorpay: $e');
          if (mounted) {
            setState(() {
              _isProcessingPayment = false;
            });
            _showErrorDialog('Failed to open payment gateway: ${e.toString()}');
          }
        }
      }
    } catch (e) {
      print('❌ Error creating Razorpay order: $e');
      if (mounted) {
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
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
  void dispose() {
    _tutorialCoachMark?.finish();
    _razorpay.clear(); // Removes all listeners
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('✅ Payment Success: ${response.paymentId}');
    print('✅ Order ID: ${response.orderId}');
    print('✅ Signature: ${response.signature}');
    
    if (mounted) {
      setState(() {
        _isProcessingPayment = true; // Keep loading while verifying
      });

      try {
        final token = await UserService.getToken();
        final customer = await UserService.getCustomer();
        
        if (token == null || customer == null) {
          throw Exception('Authentication token or customer ID not found.');
        }

        if (_currentOrderId == null || _currentAmount == null) {
          throw Exception('Order details not found. Please try again.');
        }

        print('🔵 Verifying payment...');
        final verifyResponse = await _authService.verifyRazorpayPayment(
          razorpayOrderId: response.orderId ?? _currentOrderId!,
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
          amount: _currentAmount! ~/ 100, // Convert paise to rupees
          customerId: customer.id,
          token: token,
        );

        print('✅ Payment verified successfully');
        print('✅ New wallet balance: ₹${verifyResponse.walletBalance}');

        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
            _walletBalance = verifyResponse.walletBalance;
            _currentOrderId = null;
            _currentAmount = null;
          });
          
          _showSuccessDialog(
            'Payment successful!\n\nPayment ID: ${response.paymentId}\nOrder ID: ${response.orderId}\n\nNew Wallet Balance: ₹${verifyResponse.walletBalance}',
          );
          _amountController.clear();
          // Reload wallet balance and history
          _loadUserData();
          _loadWalletHistory();
        }
      } catch (e) {
        print('❌ Error verifying payment: $e');
        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
          });
          _showErrorDialog(
            'Payment was successful but verification failed.\n\nPlease contact support with:\nPayment ID: ${response.paymentId}\nOrder ID: ${response.orderId}\n\nError: ${e.toString().replaceAll('Exception: ', '')}',
          );
          // Still reload wallet balance in case it was updated
          _loadUserData();
          _loadWalletHistory();
        }
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Error: ${response.code} - ${response.message}');
    
    if (mounted) {
      setState(() {
        _isProcessingPayment = false;
      });
      
      _showErrorDialog(
        'Payment failed: ${response.message ?? 'Unknown error'}\nError Code: ${response.code}',
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('🔵 External Wallet: ${response.walletName}');
    
    if (mounted) {
      _showSuccessDialog('External wallet selected: ${response.walletName}');
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            const Center(
              child: Text(
                'Wallet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Center(
              child: Text(
                'Manage your digital transactions for delivery orders with KartBuddy\'s Wallet. Payments are automatically deducted from your balance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Wallet Balance and Recharge Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  // Wallet Balance
                  Container(
                    key: _balanceKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹$_walletBalance',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Amount Input
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Enter Amount (Min: ₹1)',
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
                      prefixIcon: const Icon(
                        Icons.currency_rupee,
                        color: Color(0xFF1E3A8A),
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
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recharge Buttons
                  Row(
                    key: _rechargeKey,
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                            child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isProcessingPayment ? null : () {
                                _handleRecharge();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: _isProcessingPayment
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Recharge',
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
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E3A8A).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const ManualRecharge()),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Center(
                                child: Text(
                                  'Recharge Manually',
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
                  const SizedBox(height: 20),

                  // Redeem Gift Code
                  Center(
                    child: TextButton(
                      onPressed: () {
                        _showRedeemGiftCodeDialog();
                      },
                      child: const Text(
                        'Redeem Gift Code',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Transactions Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        key: _transactionsKey,
                        child: const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      TextButton(
                        key: _historyKey,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const WalletHistory()),
                          );
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Transaction List
                  if (_isLoadingTransactions)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._transactions.take(5).map((transaction) {
                      return Column(
                        children: [
                          _buildTransactionItem(transaction),
                          if (transaction != _transactions.take(5).last)
                            const Divider(),
                        ],
                      );
                    }),
                  const SizedBox(height: 20),

                  // View Wallet History Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                        child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const WalletHistory()),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Text(
                            'View Wallet History',
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
                ],
              ),
            ),
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
                  isActive: true,
                  onTap: () {},
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

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final isCredit = transaction.creditDebit.toLowerCase() == 'credit';
    final iconColor = isCredit ? Colors.green : Colors.red;
    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;
    final amountPrefix = isCredit ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.transactionType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.formatDateTime(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix₹${transaction.amount}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: iconColor,
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
              isActive: true,
              onTap: () {
                Navigator.pop(context);
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

  void _showRedeemGiftCodeDialog() {
    final TextEditingController giftCodeController = TextEditingController();
    bool _isSubmitting = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Redeem Gift Code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Input Field
                    TextField(
                      controller: giftCodeController,
                      enabled: !_isSubmitting,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter gift code',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.normal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
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
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  Navigator.of(dialogContext).pop();
                                  giftCodeController.dispose();
                                },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final giftCode = giftCodeController.text.trim().toUpperCase();
                                  if (giftCode.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter a gift code'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    _isSubmitting = true;
                                  });

                                  try {
                                    final token = await UserService.getToken();
                                    final customer = await UserService.getCustomer();

                                    if (token == null || customer == null) {
                                      throw Exception('Authentication token or customer ID not found.');
                                    }

                                    // First, validate the gift code
                                    print('🔵 Validating gift code: $giftCode');
                                    final giftCodesResponse = await _authService.getGiftCodes(token);
                                    
                                    final matchingCode = giftCodesResponse.data.firstWhere(
                                      (code) => code.giftCode.toUpperCase() == giftCode,
                                      orElse: () => throw Exception('Invalid gift code'),
                                    );

                                    // Check if code is active
                                    if (!matchingCode.isActive) {
                                      throw Exception('This gift code is not active');
                                    }

                                    // Check if code is expired
                                    if (matchingCode.isExpired) {
                                      throw Exception('This gift code has expired');
                                    }

                                    // Check if code is fully used
                                    if (matchingCode.isFullyUsed) {
                                      throw Exception('This gift code has reached its usage limit');
                                    }

                                    // Code is valid, proceed with redemption
                                    print('🔵 Gift code is valid. Redeeming...');
                                    final response = await _authService.redeemGiftCode(
                                      customer.id,
                                      giftCode,
                                      token,
                                    );

                                    print('✅ Gift code redeemed successfully');
                                    print('✅ Gift value: ₹${response.data.giftValue}');

                                    if (dialogContext.mounted) {
                                      Navigator.of(dialogContext).pop();
                                      giftCodeController.dispose();

                                      // Reload wallet balance
                                      _loadUserData();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gift code redeemed successfully! ₹${response.data.giftValue} added to your wallet.',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print('❌ Error redeeming gift code: $e');
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        _isSubmitting = false;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceAll('Exception: ', ''),
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Submit Code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
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

