import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List of app USPs
    final List<Map<String, dynamic>> features = [
      {
        'title': 'Lightning Fast Bookings',
        'description': 'Book train tickets in under 10 seconds with our optimized booking process and Tatkal mode.',
        'icon': Icons.flash_on,
      },
      {
        'title': 'Smart Tatkal Assistant',
        'description': 'Our AI-powered assistant automatically fills forms and submits at the exact opening time for maximum success rate.',
        'icon': Icons.smart_toy,
      },
      {
        'title': 'Instant Confirmations',
        'description': 'Get instant booking confirmations and e-tickets directly to your email and SMS.',
        'icon': Icons.check_circle,
      },
      {
        'title': 'Secure Payments',
        'description': 'Multiple payment options with bank-grade security and instant refunds to wallet.',
        'icon': Icons.security,
      },
      {
        'title': 'Smart Predictions',
        'description': 'AI-powered seat availability predictions to help you book with confidence.',
        'icon': Icons.analytics,
      },
      {
        'title': 'Offline Access',
        'description': 'Access your tickets and boarding passes even without internet connection.',
        'icon': Icons.offline_bolt,
      },
      {
        'title': 'Zero Booking Fees',
        'description': 'No hidden charges or convenience fees. Pay only for your tickets.',
        'icon': Icons.money_off,
      },
      {
        'title': 'PNR Tracking',
        'description': 'Real-time PNR status updates and journey tracking with live train status.',
        'icon': Icons.track_changes,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        title: const Text(
          'About Tatkal Pro',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50), // Top padding as per design guidelines
            _buildAppHeader(context),
            const SizedBox(height: 24),
            _buildFeatureSection(features),
            const SizedBox(height: 24),
            _buildAppStats(),
            const SizedBox(height: 24),
            _buildAboutSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // App Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.train,
                size: 60,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // App Name
          const Text(
            'Tatkal Pro',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 8),
          // App Tagline
          const Text(
            'India\'s Fastest Train Ticket Booking App',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          // App Version
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Version 2.5.0',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(List<Map<String, dynamic>> features) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Why Choose Tatkal Pro?',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        feature['icon'],
                        size: 48,
                        color: const Color(0xFF7C3AED),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        feature['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feature['description'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppStats() {
    final List<Map<String, dynamic>> stats = [
      {
        'value': '5M+',
        'label': 'Downloads',
        'icon': Icons.download,
      },
      {
        'value': '4.8',
        'label': 'App Rating',
        'icon': Icons.star,
      },
      {
        'value': '10M+',
        'label': 'Tickets Booked',
        'icon': Icons.confirmation_number,
      },
      {
        'value': '99.8%',
        'label': 'Success Rate',
        'icon': Icons.verified,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: Color(0xFF7C3AED),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'App Statistics',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: stats.map((stat) {
                  return Column(
                    children: [
                      Icon(
                        stat['icon'],
                        color: const Color(0xFF7C3AED),
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stat['value'],
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stat['label'],
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF7C3AED),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'About Us',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Tatkal Pro is India\'s leading train ticket booking platform, designed to make the booking process faster, simpler, and more reliable. Our mission is to revolutionize the way Indians book train tickets by leveraging cutting-edge technology.',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Founded in 2020, we have quickly grown to become the preferred choice for millions of travelers across India. Our team of passionate engineers and travel enthusiasts work tirelessly to improve your booking experience.',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildContactButton(
                    icon: Icons.language,
                    label: 'Website',
                  ),
                  _buildContactButton(
                    icon: Icons.mail,
                    label: 'Email Us',
                  ),
                  _buildContactButton(
                    icon: Icons.privacy_tip,
                    label: 'Privacy',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF7C3AED),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
