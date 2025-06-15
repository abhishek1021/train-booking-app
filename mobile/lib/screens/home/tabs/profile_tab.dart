import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import '../../profile/profile_screen.dart';
import '../../saved_passengers_screen.dart';
import '../../payment_methods_screen.dart';
import '../../help_center_screen.dart';
import '../../privacy_policy_screen.dart';
import '../../about_tatkal_pro_screen.dart';
import '../../terms_of_service_screen.dart';
import '../../language_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_profile');
    if (userStr != null) {
      setState(() {
        userProfile = jsonDecode(userStr);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = userProfile?['OtherAttributes']?['FullName'] ??
        userProfile?['fullName'] ??
        userProfile?['name'] ??
        'User';
    final email = userProfile?['Email'] ?? userProfile?['email'] ?? '';
    final avatarUrl = userProfile?['avatarUrl'];
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // Modern purple gradient app bar with decorative elements
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -20,
                  right: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -15,
                  left: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                // Header content
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Icon(Icons.account_circle, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Account',
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              children: [
                // Modern profile header with card effect
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Profile avatar with border
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFFF3EEFF),
                          backgroundImage:
                              avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null
                              ? Text(
                                  _getInitials(fullName),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C3AED),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email,
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.normal,
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_2, color: Color(0xFF7C3AED)),
                          onPressed: () {},
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _sectionHeader('General'),
                _menuItem(Icons.person, 'Personal Info', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                }),
                _menuItem(Icons.groups, 'Passengers List', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedPassengersScreen(),
                    ),
                  );
                }),
                _menuItem(Icons.credit_card, 'Payment Methods', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsScreen(),
                    ),
                  );
                }),
                _menuItem(Icons.notifications, 'Notification', onTap: () {
                  Navigator.of(context).pushNamed('/notifications');
                }),
                _menuItem(Icons.language, 'Language',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EEFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('English (US)', style: _trailingStyle),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageScreen(),
                        ),
                      );
                    }),
                const SizedBox(height: 12),
                _sectionHeader('About'),
                _menuItem(Icons.help_outline, 'Help Center', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpCenterScreen(),
                    ),
                  );
                }),
                _menuItem(Icons.privacy_tip, 'Privacy Policy', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                }),
                _menuItem(Icons.gavel_rounded, 'Terms of Service', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
                  );
                }),
                _menuItem(Icons.info_outline, 'About TatkalPro', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutTatkalProScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear(); // Clear all preferences
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Logout',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'ProductSans')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'ProductSans',
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );

  Widget _menuItem(IconData icon, String label,
          {Widget? trailing, VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFFF3EEFF),
        highlightColor: const Color(0xFFF3EEFF).withOpacity(0.5),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EEFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chevron_right,
                      color: Color(0xFF7C3AED), size: 18),
                ),
            ],
          ),
        ),
      );

  TextStyle get _trailingStyle => const TextStyle(
        fontFamily: 'ProductSans',
        color: Color(0xFF7C3AED),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      );
      
  // Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }
    
    return '';
  }
}
