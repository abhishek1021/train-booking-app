import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NeumorphicBackground(
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Neumorphic(
              style: NeumorphicStyle(
                depth: 8,
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [
                    Center(
                      child: Neumorphic(
                        style: NeumorphicStyle(
                          depth: 8,
                          boxShape: NeumorphicBoxShape.circle(),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: NeumorphicText(
                        'John Doe',
                        style: const NeumorphicStyle(
                          depth: 4,
                          color: Color(0xFF222831),
                        ),
                        textStyle: NeumorphicTextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        NeumorphicButton(
                          onPressed: () {
                            // TODO: Implement IRCTC account linking
                          },
                          style: NeumorphicStyle(
                            depth: 4,
                            color: Colors.blue[100],
                            boxShape: NeumorphicBoxShape.stadium(),
                          ),
                          child: const Center(
                            child: Text('Link IRCTC Account', style: TextStyle(color: Colors.blue)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Preferences',
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Dark Mode'),
                            NeumorphicSwitch(
                              value: false,
                              style: const NeumorphicSwitchStyle(
                                activeTrackColor: Colors.blue,
                              ),
                              onChanged: (value) {
                                // TODO: Implement theme switching
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Notifications'),
                            NeumorphicSwitch(
                              value: true,
                              style: const NeumorphicSwitchStyle(
                                activeTrackColor: Colors.blue,
                              ),
                              onChanged: (value) {
                                // TODO: Implement notification toggle
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    NeumorphicButton(
                      onPressed: () {
                        // TODO: Implement logout
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: NeumorphicStyle(
                        depth: 4,
                        color: Colors.red[200],
                        boxShape: NeumorphicBoxShape.stadium(),
                      ),
                      child: const Center(
                        child: Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Neumorphic(
      margin: const EdgeInsets.symmetric(vertical: 8),
      style: NeumorphicStyle(
        depth: 4,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeumorphicText(
              title,
              style: const NeumorphicStyle(
                depth: 2,
                color: Color(0xFF222831),
              ),
              textStyle: NeumorphicTextStyle(
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
