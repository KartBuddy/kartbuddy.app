import 'package:flutter/material.dart';
import '../screens/customer_home.dart';
import '../screens/customer_wallet.dart';
import '../screens/place_order.dart';
import '../screens/my_orders.dart';
import '../screens/track_order.dart';
import '../screens/place_manager.dart';
import '../screens/support.dart';
import '../screens/user_profile.dart';
import '../../auth/login.dart';
import '../../services/user_service.dart';

class CustomerSidebar extends StatelessWidget {
  final String? currentScreen;
  
  const CustomerSidebar({
    super.key,
    this.currentScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E3A8A),
      child: SafeArea(
        child: Column(
          children: [
            // Collapse button
            Container(
              margin: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
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
            ),
            const SizedBox(height: 8),

            // Navigation Items
            _buildDrawerItem(
              context: context,
              icon: Icons.dashboard,
              label: 'Dashboard',
              isActive: currentScreen == 'dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const CustomerHome()),
                  (route) => false,
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.account_balance_wallet,
              label: 'Wallet',
              isActive: currentScreen == 'wallet',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomerWallet(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.add_circle_outline,
              label: 'Place Order',
              isActive: currentScreen == 'place_order',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PlaceOrder(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.refresh,
              label: 'My Orders',
              isActive: currentScreen == 'my_orders',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyOrders(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.location_on,
              label: 'Track Order',
              isActive: currentScreen == 'track_order',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TrackOrder(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.store,
              label: 'Place Manager',
              isActive: currentScreen == 'place_manager',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PlaceManager(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.support_agent,
              label: 'Support',
              isActive: currentScreen == 'support',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Support(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.person,
              label: 'My Profile',
              isActive: currentScreen == 'profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UserProfile(),
                  ),
                );
              },
            ),

            const Spacer(),

            // Sign Out Button
            _buildDrawerItem(
              context: context,
              icon: Icons.exit_to_app,
              label: 'Sign Out',
              isActive: false,
              onTap: () async {
                Navigator.pop(context);
                await UserService.clearUserData();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
            ),

            const SizedBox(height: 8),

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
    required BuildContext context,
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
}

