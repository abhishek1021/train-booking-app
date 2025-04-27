import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement logout
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          const Text(
            'John Doe',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'Personal Information',
            children: [
              _buildListTile('Email', 'john@example.com'),
              _buildListTile('Phone', '+91 9876543210'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'IRCTC Account',
            children: [
              _buildListTile('Username', 'john123'),
              ListTile(
                title: const Text('Link IRCTC Account'),
                trailing: const Icon(Icons.add),
                onTap: () {
                  // TODO: Implement IRCTC account linking
                },
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
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
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
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
