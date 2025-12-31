import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth/login.dart';
import 'presentation/screens/customer_home.dart';
import 'presentation/screens/driver_home.dart';
import 'services/user_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _initialScreen = const LoginPage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
}

  Future<void> _checkLoginStatus() async {
    final token = await UserService.getToken();
    if (token != null && token.isNotEmpty) {
      // User is logged in, check user type and navigate to appropriate home
      final userType = await UserService.getUserType();
      setState(() {
        if (userType == 'driver') {
          _initialScreen = const DriverHome();
        } else {
          _initialScreen = const CustomerHome();
        }
        _isLoading = false;
      });
    } else {
      // User is not logged in, show login page
      setState(() {
        _initialScreen = const LoginPage();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800), // Base design size (mobile)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Kartbuddy',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: _isLoading
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : _initialScreen,
        );
      },
      child: const SizedBox.shrink(), // Required for builder with context
    );
  }
}
