import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF7C3AED),
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF3EEFF),
              Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header with icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EEFF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    size: 40,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Center(
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Last updated date
              Center(
                child: Text(
                  'Last Updated: June 12, 2025',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Introduction
              _buildSectionTitle('1. Introduction'),
              _buildParagraph(
                'Welcome to TatkalPro! These Terms of Service ("Terms") govern your use of the TatkalPro mobile application and website (collectively, the "Service") operated by TatkalPro Inc. ("we," "us," or "our").',
              ),
              _buildParagraph(
                'By accessing or using the Service, you agree to be bound by these Terms. If you disagree with any part of the Terms, you may not access the Service.',
              ),
              const SizedBox(height: 24),
              // User Accounts
              _buildSectionTitle('2. User Accounts'),
              _buildParagraph(
                'When you create an account with us, you must provide accurate, complete, and current information. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of your account on our Service.',
              ),
              _buildParagraph(
                'You are responsible for safeguarding the password that you use to access the Service and for any activities or actions under your password.',
              ),
              _buildParagraph(
                'You agree not to disclose your password to any third party. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.',
              ),
              const SizedBox(height: 24),
              // Booking and Payments
              _buildSectionTitle('3. Booking and Payments'),
              _buildParagraph(
                'TatkalPro facilitates train ticket bookings through official railway partners. We do not own or operate any trains or transportation services.',
              ),
              _buildParagraph(
                'All payments made through the Service are processed by secure third-party payment processors. By making a payment, you agree to the terms and conditions of these payment processors.',
              ),
              _buildParagraph(
                'Cancellations and refunds are subject to the policies of the railway service providers. TatkalPro will assist in processing refund requests but cannot guarantee approval.',
              ),
              const SizedBox(height: 24),
              // Intellectual Property
              _buildSectionTitle('4. Intellectual Property'),
              _buildParagraph(
                'The Service and its original content, features, and functionality are and will remain the exclusive property of TatkalPro Inc. and its licensors.',
              ),
              _buildParagraph(
                'The Service is protected by copyright, trademark, and other laws of both the India and foreign countries. Our trademarks and trade dress may not be used in connection with any product or service without the prior written consent of TatkalPro Inc.',
              ),
              const SizedBox(height: 24),
              // Limitation of Liability
              _buildSectionTitle('5. Limitation of Liability'),
              _buildParagraph(
                'In no event shall TatkalPro Inc., nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from:',
              ),
              _buildListItem('Your access to or use of or inability to access or use the Service;'),
              _buildListItem('Any conduct or content of any third party on the Service;'),
              _buildListItem('Any content obtained from the Service; and'),
              _buildListItem('Unauthorized access, use or alteration of your transmissions or content.'),
              const SizedBox(height: 24),
              // Termination
              _buildSectionTitle('6. Termination'),
              _buildParagraph(
                'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.',
              ),
              _buildParagraph(
                'Upon termination, your right to use the Service will immediately cease. If you wish to terminate your account, you may simply discontinue using the Service.',
              ),
              const SizedBox(height: 24),
              // Governing Law
              _buildSectionTitle('7. Governing Law'),
              _buildParagraph(
                'These Terms shall be governed and construed in accordance with the laws of India, without regard to its conflict of law provisions.',
              ),
              _buildParagraph(
                'Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights. If any provision of these Terms is held to be invalid or unenforceable by a court, the remaining provisions of these Terms will remain in effect.',
              ),
              const SizedBox(height: 24),
              // Changes to Terms
              _buildSectionTitle('8. Changes to Terms'),
              _buildParagraph(
                'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material we will try to provide at least 30 days notice prior to any new terms taking effect.',
              ),
              _buildParagraph(
                'By continuing to access or use our Service after those revisions become effective, you agree to be bound by the revised terms. If you do not agree to the new terms, please stop using the Service.',
              ),
              const SizedBox(height: 24),
              // Contact Us
              _buildSectionTitle('9. Contact Us'),
              _buildParagraph(
                'If you have any questions about these Terms, please contact us at:',
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email_outlined, color: Color(0xFF7C3AED), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Email:',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'support@tatkalpro.in',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, color: Color(0xFF7C3AED), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Phone:',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '+91 9326808458',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, color: Color(0xFF7C3AED), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Address:',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Tatkal Pro Services. Green Life Pune Maharashtra 411057',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
          fontFamily: 'ProductSans',
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
        style: const TextStyle(
          fontFamily: 'ProductSans',
          fontSize: 15,
          height: 1.5,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'ProductSans',
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
