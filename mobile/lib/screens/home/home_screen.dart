import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:train_booking_app/screens/home/tabs/search_tab.dart';
import 'package:train_booking_app/screens/home/tabs/my_bookings_screen.dart';
import 'package:train_booking_app/screens/home/tabs/profile_tab.dart';
import 'package:train_booking_app/screens/wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String userId = ''; // Will be loaded from SharedPreferences

  // Pages list
  List<Widget> get _pages => [
        SearchTab(),
        MyBookingsScreen(),
        WalletScreen(),
        ProfileTab(),
      ];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Load user ID from SharedPreferences
  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String loadedUserId = '';

      // Try to get user ID from user profile
      final userProfileStr = prefs.getString('user_profile');
      if (userProfileStr != null) {
        try {
          final userProfile = jsonDecode(userProfileStr);
          loadedUserId = userProfile['UserID'] ??
              userProfile['userId'] ??
              userProfile['user_id'] ??
              userProfile['id'] ??
              '';
        } catch (e) {
          print('Error parsing user profile: $e');
        }
      }

      // If not found in profile, try other keys
      loadedUserId = loadedUserId.isNotEmpty
          ? loadedUserId
          : prefs.getString('UserID') ??
              prefs.getString('userId') ??
              prefs.getString('user_id') ??
              ''; // No default fallback

      // Update state if user ID was found
      if (loadedUserId != userId) {
        setState(() {
          userId = loadedUserId;
        });
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF7C3AED),
          unselectedItemColor: Colors.black45,
          selectedLabelStyle:
              const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Lato'),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              label: 'My Ticket',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'My Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
