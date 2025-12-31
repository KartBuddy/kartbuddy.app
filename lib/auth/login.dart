import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup.dart';
import '../presentation/screens/customer_home.dart';
import '../presentation/screens/driver_home.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  String _selectedRole = 'Customer';
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _inputType = 'text'; // 'email', 'phone', or 'text'
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  
  // Helper function to check if input is email or phone
  bool _isEmail(String input) {
    return input.contains('@') && input.contains('.');
  }
  
  // Helper function to check if input is phone (only digits)
  bool _isPhone(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return cleaned.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(cleaned);
  }
  
  // Update input type based on current text
  void _updateInputType(String value) {
    String newType = 'text';
    if (_isEmail(value)) {
      newType = 'email';
    } else if (_isPhone(value)) {
      newType = 'phone';
    }
    if (_inputType != newType) {
      setState(() {
        _inputType = newType;
      });
    }
  }

  // Handle login
  Future<void> _handleLogin() async {
    print('🔵 Login button tapped');
    print('🔵 Selected Role: $_selectedRole');
    
    if (_selectedRole == 'Customer') {
      final emailOrPhone = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('🔵 Email/Phone: $emailOrPhone');
      print('🔵 Password: ${password.isNotEmpty ? "***" : "empty"}');

      if (emailOrPhone.isEmpty) {
        print('❌ Email/Phone is empty');
        _showErrorDialog('Please enter your email or phone number');
        return;
      }

      if (password.isEmpty) {
        print('❌ Password is empty');
        _showErrorDialog('Please enter your password');
        return;
      }

      // Determine if input is phone or email
      final bool isPhoneLogin = _isPhone(emailOrPhone);
      final bool isEmailLogin = _isEmail(emailOrPhone);
      
      if (!isPhoneLogin && !isEmailLogin) {
        print('❌ Invalid input: neither email nor phone');
        _showErrorDialog('Please enter a valid email or phone number');
        return;
      }

      print('🔵 Starting login API call...');
      print('🔵 Login Type: ${isPhoneLogin ? "Phone" : "Email"}');
      setState(() {
        _isLoading = true;
      });

      try {
        print('🔵 Calling _authService.customerLogin...');
        final response = await _authService.customerLogin(
          emailOrPhone, 
          password,
          isPhone: isPhoneLogin,
        );
        
        print('✅ Login API call successful');
        print('✅ Customer ID: ${response.data.customer.id}');
        print('✅ Customer Name: ${response.data.customer.fullName}');
        print('✅ Token received: ${response.data.token.substring(0, 20)}...');
        
        // Store user data and token
        await UserService.saveUserData(response.data.customer, response.data.token);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          print('🔵 Navigating to CustomerHome...');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CustomerHome(),
            ),
          );
        }
      } catch (e) {
        print('❌ Login error: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
        }
      }
    } else if (_selectedRole == 'Driver') {
      final emailOrPhone = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('🔵 Email/Phone: $emailOrPhone');
      print('🔵 Password: ${password.isNotEmpty ? "***" : "empty"}');

      if (emailOrPhone.isEmpty) {
        print('❌ Email/Phone is empty');
        _showErrorDialog('Please enter your email or phone number');
        return;
      }

      if (password.isEmpty) {
        print('❌ Password is empty');
        _showErrorDialog('Please enter your password');
        return;
      }

      // Determine if input is phone or email
      final bool isPhoneLogin = _isPhone(emailOrPhone);
      final bool isEmailLogin = _isEmail(emailOrPhone);
      
      if (!isPhoneLogin && !isEmailLogin) {
        print('❌ Invalid input: neither email nor phone');
        _showErrorDialog('Please enter a valid email or phone number');
        return;
      }

      print('🔵 Starting driver login API call...');
      print('🔵 Login Type: ${isPhoneLogin ? "Phone" : "Email"}');
      setState(() {
        _isLoading = true;
      });

      try {
        print('🔵 Calling _authService.driverLogin...');
        final response = await _authService.driverLogin(
          emailOrPhone, 
          password,
          isPhone: isPhoneLogin,
        );
        
        print('✅ Driver login API call successful');
        print('✅ Driver ID: ${response.data.driver.id}');
        print('✅ Driver Name: ${response.data.driver.fullName}');
        print('✅ Token received: ${response.data.token.substring(0, 20)}...');
        
        // Store driver data and token
        await UserService.saveDriverData(response.data.driver, response.data.token);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          print('🔵 Navigating to DriverHome...');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const DriverHome(),
            ),
          );
        }
      } catch (e) {
        print('❌ Driver login error: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
        }
      }
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _emailFocusNode.addListener(() {
      setState(() {
        // Trigger rebuild when focus changes
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            // Watermark background
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Center(
                  child: Image.asset(
                    'assets/3d Logo.png',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width * 1.2,
                    height: MediaQuery.of(context).size.height * 1.0,
                  ),
                ),
              ),
            ),
            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Login to\nKartBuddy',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3A8A),
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/Kartbuddy logo v.2.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // User Role Selection
                  _buildSegmentedControl(
                    options: const ['Customer', 'Driver'],
                    selected: _selectedRole,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Email/Phone Field (works for both)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: _inputType == 'email'
                          ? TextInputType.emailAddress
                          : (_inputType == 'phone'
                              ? TextInputType.number
                              : TextInputType.text),
                      maxLength: _inputType == 'phone' ? 10 : null,
                      inputFormatters: _inputType == 'phone'
                          ? [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ]
                          : null,
                      onChanged: (value) {
                        _updateInputType(value);
                      },
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email or Phone',
                        hintText: _emailFocusNode.hasFocus ? null : 'Enter email or phone number',
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
                        prefixIcon: Icon(
                          _inputType == 'email'
                              ? Icons.email_outlined
                              : (_inputType == 'phone'
                                  ? Icons.phone_outlined
                                  : Icons.alternate_email),
                          color: Colors.grey[600],
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
                        counterText: '', // Hide character counter
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
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
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        suffixIcon: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                _obscurePassword ? 'Show' : 'Hide',
                                style: TextStyle(
                                  color: const Color(0xFF1E3A8A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
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
                  const SizedBox(height: 16),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Handle forgot password
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: const Color(0xFF1E3A8A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E3A8A),
                          Color(0xFF3B82F6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                        onTap: _isLoading ? null : _handleLogin,
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Sign Up Link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SignupPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  color: const Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                ),
                              ),
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
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = option == selected;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: EdgeInsets.all(isSelected ? 4 : 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF1E3A8A),
                          Color(0xFF3B82F6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged(option),
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

