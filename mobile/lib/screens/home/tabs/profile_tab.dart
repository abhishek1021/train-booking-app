import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    final fullName = userProfile?['OtherAttributes']?['FullName'] ?? userProfile?['fullName'] ?? userProfile?['name'] ?? 'User';
    final email = userProfile?['Email'] ?? userProfile?['email'] ?? '';
    final avatarUrl = userProfile?['avatarUrl'];
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Purple gradient app bar
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle, color: Colors.white, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'Account',
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              children: [
                // Profile header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null ? Icon(Icons.person, size: 38, color: Colors.grey[700]) : null,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.normal,
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_2, color: Colors.black54),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, indent: 24, endIndent: 24),
                const SizedBox(height: 12),
                _sectionHeader('General'),
                _menuItem(Icons.person, 'Personal Info', onTap: () {}),
                _menuItem(Icons.groups, 'Passengers List', onTap: () {}),
                _menuItem(Icons.credit_card, 'Payment Methods', onTap: () {}),
                _menuItem(Icons.notifications, 'Notification', onTap: () {}),
                _menuItem(Icons.security, 'Security', onTap: () {}),
                _menuItem(Icons.language, 'Language', trailing: Text('English (US)', style: _trailingStyle)),
                _menuItem(Icons.remove_red_eye, 'Dark Mode', trailing: Switch(value: false, onChanged: (_) {})),
                const SizedBox(height: 12),
                _sectionHeader('About'),
                _menuItem(Icons.help_outline, 'Help Center', onTap: () {}),
                _menuItem(Icons.privacy_tip, 'Privacy Policy', onTap: () {}),
                _menuItem(Icons.info_outline, 'About TatkalPro', onTap: () {}),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('user_profile');
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Lato',
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
      );

  Widget _menuItem(IconData icon, String label, {Widget? trailing, VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.black87, size: 22),
              const SizedBox(width: 22),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null)
                const Icon(Icons.chevron_right, color: Colors.black26, size: 22),
            ],
          ),
        ),
      );

  TextStyle get _trailingStyle => const TextStyle(
        fontFamily: 'Lato',
        color: Colors.black54,
        fontWeight: FontWeight.normal,
        fontSize: 15,
      );
}
