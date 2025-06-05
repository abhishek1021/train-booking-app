import 'package:flutter/material.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Static offers data
    final List<Map<String, dynamic>> offers = [
      {
        'title': 'First Booking Discount',
        'code': 'FIRST50',
        'discount': '50% OFF',
        'description': 'Get 50% off on your first booking. Maximum discount ₹200.',
        'validTill': 'June 30, 2025',
        'image': 'assets/images/offer1.png',
        'color': const Color(0xFF7C3AED),
      },
      {
        'title': 'Weekend Special',
        'code': 'WEEKEND25',
        'discount': '25% OFF',
        'description': 'Get 25% off on all weekend bookings. Valid for Saturday and Sunday travel.',
        'validTill': 'July 15, 2025',
        'image': 'assets/images/offer2.png',
        'color': const Color(0xFF4C1D95),
      },
      {
        'title': 'Senior Citizen Offer',
        'code': 'SENIOR15',
        'discount': '15% OFF',
        'description': 'Additional 15% off for senior citizens. Can be combined with other offers.',
        'validTill': 'December 31, 2025',
        'image': 'assets/images/offer3.png',
        'color': const Color(0xFF5B21B6),
      },
      {
        'title': 'Family Package',
        'code': 'FAMILY20',
        'discount': '20% OFF',
        'description': 'Get 20% off when booking for 4 or more passengers in the same booking.',
        'validTill': 'August 31, 2025',
        'image': 'assets/images/offer4.png',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Monsoon Special',
        'code': 'MONSOON30',
        'discount': '30% OFF',
        'description': 'Get 30% off on all bookings during monsoon season. Valid for travel between July and September.',
        'validTill': 'September 30, 2025',
        'image': 'assets/images/offer5.png',
        'color': const Color(0xFF7C3AED),
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
          'Offers & Promotions',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 50), // Top padding as per design guidelines
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer,
                  color: Color(0xFF7C3AED),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Available Offers',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '5 Active',
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
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                return _buildOfferCard(context, offer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, Map<String, dynamic> offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offer header with gradient
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [offer['color'], offer['color'].withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      offer['discount'],
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer['title'],
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Valid till ${offer['validTill']}',
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Offer details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer['description'],
                  style: const TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.confirmation_number,
                              color: Color(0xFF7C3AED),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              offer['code'],
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Coupon code ${offer['code']} copied to clipboard!'),
                            backgroundColor: const Color(0xFF7C3AED),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
