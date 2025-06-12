import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTatkalProScreen extends StatelessWidget {
  const AboutTatkalProScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'About TatkalPro',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.train,
                        size: 60,
                        color: const Color(0xFF7C3AED),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'TatkalPro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoSection(
                'About Us',
                'TatkalPro is a revolutionary train booking application designed to simplify the process of booking train tickets in India. Our mission is to make train travel booking hassle-free and accessible to everyone.',
              ),
              _buildInfoSection(
                'Our Mission',
                'To transform the train booking experience by leveraging cutting-edge technology and automation, ensuring that our users can secure their preferred seats with minimal effort and maximum convenience.',
              ),
              _buildInfoSection(
                'Key Features',
                '• Automated Tatkal booking\n• Real-time train availability\n• Secure payment options\n• Digital ticket management\n• Passenger profile saving\n• Smart notifications\n• Wallet system for quick payments',
              ),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildTeamSection(),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildSocialLinks(),
              const SizedBox(height: 32),
              _buildCopyrightSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Our Team',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTeamMember('Abhishek Raj Tripathi', 'Founder & CEO'),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamMember(String name, String role) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEFF),
            borderRadius: BorderRadius.circular(35),
          ),
          child: Center(
            child: Icon(
              Icons.person,
              size: 40,
              color: const Color(0xFF7C3AED),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          role,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect With Us',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(Icons.language, 'Website', 'https://www.tatkalpro.com'),
            const SizedBox(width: 24),
            _buildSocialIcon(Icons.facebook, 'Facebook', 'https://www.facebook.com/tatkalpro'),
            const SizedBox(width: 24),
            _buildSocialIcon(Icons.camera_alt, 'Instagram', 'https://www.instagram.com/tatkalpro'),
            const SizedBox(width: 24),
            _buildSocialIcon(Icons.email, 'Email', 'mailto:contact@tatkalpro.com'),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String label, String url) {
    return InkWell(
      onTap: () async {
        if (await canLaunch(url)) {
          await launch(url);
        }
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildCopyrightSection() {
    return Column(
      children: [
        Text(
          '© 2025 TatkalPro. All rights reserved.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Made with ♥ in India',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
