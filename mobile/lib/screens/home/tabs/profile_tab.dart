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
    final username = userProfile?['Username'] ?? userProfile?['username'] ?? '';
    final phone = userProfile?['phone'] ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, size: 50, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222831),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                title: 'Personal Information',
                children: [
                  _buildListTile('Email', email),
                  if (phone.isNotEmpty) _buildListTile('Phone', phone),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'IRCTC Account',
                children: [
                  _buildListTile('Username', username),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement IRCTC account linking
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue,
                      shape: StadiumBorder(),
                    ),
                    child: const Text('Link IRCTC Account'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Preferences',
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: false,
                    onChanged: (value) {
                      // TODO: Implement theme switching
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    value: true,
                    onChanged: (value) {
                      // TODO: Implement notification toggle
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('user_profile');
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[200],
                  foregroundColor: Colors.red[900],
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222831),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
