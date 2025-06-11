import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List of app USPs
    final List<Map<String, dynamic>> features = [
      {
        'title': 'Lightning Fast Bookings',
        'description':
            'Book train tickets in under 10 seconds with our optimized booking process and Tatkal mode.',
        'icon': Icons.flash_on,
      },
      {
        'title': 'Smart Tatkal Assistant',
        'description':
            'Our AI-powered assistant automatically fills forms and submits at the exact opening time for maximum success rate.',
        'icon': Icons.smart_toy,
      },
      {
        'title': 'Instant Confirmations',
        'description':
            'Get instant booking confirmations and e-tickets directly to your email and SMS.',
        'icon': Icons.check_circle,
      },
      {
        'title': 'Secure Payments',
        'description':
            'Multiple payment options with bank-grade security and instant refunds to wallet.',
        'icon': Icons.security,
      },
      {
        'title': 'Smart Predictions',
        'description':
            'AI-powered seat availability predictions to help you book with confidence.',
        'icon': Icons.analytics,
      },
      {
        'title': 'Offline Access',
        'description':
            'Access your tickets and boarding passes even without internet connection.',
        'icon': Icons.offline_bolt,
      },
      {
        'title': 'Zero Booking Fees',
        'description':
            'No hidden charges or convenience fees. Pay only for your tickets.',
        'icon': Icons.money_off,
      },
      {
        'title': 'PNR Tracking',
        'description':
            'Real-time PNR status updates and journey tracking with live train status.',
        'icon': Icons.track_changes,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF7C3AED),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'About Tatkal Pro',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50), // Top padding as per design guidelines
            _buildAppHeader(context),
            const SizedBox(height: 32),
            _buildFeatureSection(features),
            const SizedBox(height: 32),
            _buildAppStats(),
            const SizedBox(height: 32),
            _buildAboutSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // App Logo
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.train_rounded,
                    size: 42,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // App Name
          const Text(
            'Tatkal Pro',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: Color(0xFF7C3AED),
              letterSpacing: -0.5,
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
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          // App Version
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.w600,
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
            padding: EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Why Choose Tatkal Pro?',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(
                            feature['icon'],
                            size: 28,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        feature['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          feature['description'],
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 11,
                            height: 1.2,
                            color: Colors.black54,
                          ),
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
        'icon': Icons.download_rounded,
      },
      {
        'value': '4.8',
        'label': 'App Rating',
        'icon': Icons.star_rounded,
      },
      {
        'value': '10M+',
        'label': 'Tickets Booked',
        'icon': Icons.confirmation_number_rounded,
      },
      {
        'value': '99.8%',
        'label': 'Success Rate',
        'icon': Icons.verified_rounded,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF7C3AED),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'App Statistics',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: stats.map((stat) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            stat['icon'],
                            color: const Color(0xFF7C3AED),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        stat['value'],
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF333333),
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
                    ),
                    );
                  }).toList(),
                ),
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF7C3AED),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'About Us',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Tatkal Pro is India\'s leading train ticket booking platform, designed to make the booking process faster, simpler, and more reliable. Our mission is to revolutionize the way Indians book train tickets by leveraging cutting-edge technology.',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Founded in 2020, we have quickly grown to become the preferred choice for millions of travelers across India. Our team of passionate engineers and travel enthusiasts work tirelessly to improve your booking experience.',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildSocialButton(Icons.language_rounded, 'Website'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildSocialButton(Icons.email_rounded, 'Email'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildSocialButton(Icons.facebook_rounded, 'Facebook'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildSocialButton(Icons.chat_rounded, 'Twitter'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF7C3AED),
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
