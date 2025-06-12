import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Help Center',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildSectionTitle('Frequently Asked Questions'),
              const SizedBox(height: 16),
              _buildFAQItem(
                context,
                'How do I book a train ticket?',
                'To book a train ticket, go to the Home tab and search for trains by entering your origin, destination, and travel date. Select your preferred train and class, add passengers, and proceed to payment.',
              ),
              _buildFAQItem(
                context,
                'What is TatkalPro automation?',
                'TatkalPro automation is our premium feature that automatically books tickets for you during the Tatkal booking window. You can set up a job with your journey details and passenger information, and our system will attempt to secure tickets as soon as they become available.',
              ),
              _buildFAQItem(
                context,
                'How do I add money to my wallet?',
                'Go to the Wallet tab, tap on "Add Money", enter the amount you wish to add, and select your preferred payment method. Follow the instructions to complete the transaction.',
              ),
              _buildFAQItem(
                context,
                'What is the cancellation policy?',
                'Cancellation charges depend on the train and class you\'ve booked. Generally, cancellations made at least 48 hours before departure incur a 25% fee, while those made within 48 hours incur a 50% fee. No refunds are provided for cancellations after departure.',
              ),
              _buildFAQItem(
                context,
                'How do I add or remove passengers?',
                'You can manage your saved passengers by going to Profile > Saved Passengers. To add a new passenger, tap the "+" button and fill in their details. To remove a passenger, swipe left on their entry or tap the delete icon.',
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Contact Support'),
              const SizedBox(height: 16),
              _buildContactOption(
                Icons.email_outlined,
                'Email Us',
                'support@tatkalpro.com',
                () {},
              ),
              _buildContactOption(
                Icons.phone_outlined,
                'Call Support',
                '+91 1800-123-4567',
                () {},
              ),
              _buildContactOption(
                Icons.chat_bubble_outline,
                'Live Chat',
                'Available 24/7',
                () {},
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for help topics',
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF7C3AED),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
        iconColor: const Color(0xFF7C3AED),
        collapsedIconColor: const Color(0xFF7C3AED),
      ),
    );
  }

  Widget _buildContactOption(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF7C3AED),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF7C3AED),
      ),
    );
  }
}
