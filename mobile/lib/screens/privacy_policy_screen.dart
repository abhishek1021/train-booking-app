import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
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
              const Text(
                'Last Updated: June 10, 2025',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Introduction'),
              _buildParagraph(
                'TatkalPro ("we," "our," or "us") respects your privacy and is committed to protecting it through our compliance with this policy. This policy describes the types of information we may collect from you or that you may provide when you use our mobile application and services, and our practices for collecting, using, maintaining, protecting, and disclosing that information.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Information We Collect'),
              _buildParagraph(
                'We collect several types of information from and about users of our application, including:',
              ),
              _buildBulletPoint(
                'Personal information such as name, email address, phone number, and payment information.',
              ),
              _buildBulletPoint(
                'Travel preferences and history, including your past bookings and searches.',
              ),
              _buildBulletPoint(
                'Device information, including your mobile device ID, IP address, and operating system.',
              ),
              _buildBulletPoint(
                'Location data when you use our location-based services.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('How We Use Your Information'),
              _buildParagraph(
                'We use information that we collect about you or that you provide to us:',
              ),
              _buildBulletPoint(
                'To provide you with our application and its contents, and any other information, products, or services that you request from us.',
              ),
              _buildBulletPoint(
                'To process and complete your transactions, including train bookings and payments.',
              ),
              _buildBulletPoint(
                'To send you important information regarding our application, changes to our terms, conditions, and policies.',
              ),
              _buildBulletPoint(
                'To personalize your experience and to allow us to deliver the type of content and product offerings in which you are most interested.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Disclosure of Your Information'),
              _buildParagraph(
                'We may disclose personal information that we collect or you provide:',
              ),
              _buildBulletPoint(
                'To our subsidiaries and affiliates for the purpose of providing our services.',
              ),
              _buildBulletPoint(
                'To contractors, service providers, and other third parties we use to support our business.',
              ),
              _buildBulletPoint(
                'To fulfill the purpose for which you provide it, such as processing your train booking.',
              ),
              _buildBulletPoint(
                'For any other purpose disclosed by us when you provide the information.',
              ),
              _buildBulletPoint(
                'With your consent.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Data Security'),
              _buildParagraph(
                'We have implemented measures designed to secure your personal information from accidental loss and from unauthorized access, use, alteration, and disclosure. All information you provide to us is stored on secure servers behind firewalls. Any payment transactions will be encrypted using SSL technology.',
              ),
              _buildParagraph(
                'Unfortunately, the transmission of information via the internet and mobile platforms is not completely secure. Although we do our best to protect your personal information, we cannot guarantee the security of your personal information transmitted through our application. Any transmission of personal information is at your own risk.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Your Choices About Our Collection, Use, and Disclosure'),
              _buildParagraph(
                'You can set your browser or mobile device to refuse all or some cookies, or to alert you when cookies are being sent. If you disable or refuse cookies or block the use of other tracking technologies, some parts of the application may then be inaccessible or not function properly.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Contact Information'),
              _buildParagraph(
                'To ask questions or comment about this privacy policy and our privacy practices, contact us at:',
              ),
              _buildContactInfo('Email: privacy@tatkalpro.com'),
              _buildContactInfo('Phone: +91 1800-123-4567'),
              _buildContactInfo('Address: 123 Tech Park, Bengaluru, Karnataka, India - 560001'),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7C3AED),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[800],
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF7C3AED),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
