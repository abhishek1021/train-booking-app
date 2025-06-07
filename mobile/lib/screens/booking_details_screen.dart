import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  _BookingDetailsScreenState createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  Map<String, dynamic> _bookingDetails = {};
  List<dynamic> _passengers = [];

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookingData =
          await _bookingService.getBookingById(widget.bookingId);

      // Debug: Print the full booking data to see what fields are available
      print('Booking Data: $bookingData');
      print('Email: ${bookingData['booking_email']}');
      print('Phone: ${bookingData['booking_phone']}');

      setState(() {
        _bookingDetails = bookingData;
        _passengers = bookingData['passengers'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching booking details: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load booking details: $e')),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String timeString) {
    try {
      final time = TimeOfDay(
        hour: int.parse(timeString.split(':')[0]),
        minute: int.parse(timeString.split(':')[1]),
      );

      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return timeString;
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return '#059669'; // Green
      case 'pending':
        return '#D97706'; // Amber
      case 'cancelled':
        return '#B91C1C'; // Red
      default:
        return '#6B7280'; // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchBookingDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 20),

                  // Journey Details
                  _buildJourneyDetails(),
                  const SizedBox(height: 20),

                  // Passenger Details
                  _buildPassengerDetails(),
                  const SizedBox(height: 20),

                  // Contact Details
                  _buildContactDetails(),
                  const SizedBox(height: 20),

                  // Payment Details
                  _buildPaymentDetails(),
                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final status = _bookingDetails['booking_status'] ?? 'Unknown';
    final pnr = _bookingDetails['pnr'] ?? 'N/A';
    final bookingId = _bookingDetails['booking_id'] ?? 'N/A';
    final createdAt = _bookingDetails['created_at'] != null
        ? _formatDate(_bookingDetails['created_at'])
        : 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.confirmation_number_outlined,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'PNR Number',
            style: TextStyle(
              fontFamily: 'ProductSans',
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                pnr,
                style: const TextStyle(
                  fontFamily: 'ProductSans',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // Copy to clipboard logic
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking ID',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bookingId.substring(0, 8) + '...',
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Booking Date',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    createdAt,
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyDetails() {
    final trainId = _bookingDetails['train_id'] ?? 'N/A';
    final journeyDate = _bookingDetails['journey_date'] != null
        ? _formatDate(_bookingDetails['journey_date'])
        : 'N/A';
    final originStation = _bookingDetails['origin_station_code'] ?? 'N/A';
    final destinationStation =
        _bookingDetails['destination_station_code'] ?? 'N/A';
    final travelClass = _bookingDetails['travel_class'] ?? 
                       _bookingDetails['class'] ?? 'N/A';

    return _buildSectionCard(
      title: 'Journey Details',
      icon: Icons.train,
      children: [
        _buildInfoRow('Train Number', trainId.toString()),
        _buildInfoRow('Journey Date', journeyDate),
        _buildInfoRow('From', originStation.toString().toUpperCase()),
        _buildInfoRow('To', destinationStation.toString().toUpperCase()),
        _buildInfoRow('Class', _formatTravelClass(travelClass)),
      ],
    );
  }

  String _formatTravelClass(String travelClass) {
    if (travelClass == '1A') return 'First AC';
    if (travelClass == '2A') return 'Second AC';
    if (travelClass == '3A') return 'Third AC';
    if (travelClass == 'SL') return 'Sleeper Class';
    if (travelClass == 'CC') return 'Chair Car';
    if (travelClass == '2S') return 'Second Seater';
    return travelClass;
  }

  Widget _buildPassengerDetails() {
    return _buildSectionCard(
      title: 'Passenger Details',
      icon: Icons.people_alt_outlined,
      children: [
        for (int i = 0; i < _passengers.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person,
                        color: Color(0xFF7C3AED), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Passenger ${i + 1}',
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Name', _passengers[i]['name'] ?? 'N/A'),
                _buildInfoRow(
                    'Age', (_passengers[i]['age'] ?? 'N/A').toString()),
                _buildInfoRow('Gender', _passengers[i]['gender'] ?? 'N/A'),
                _buildInfoRow('Seat', _passengers[i]['seat'] ?? 'N/A'),
                _buildInfoRow('Status', _passengers[i]['status'] ?? 'N/A'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContactDetails() {
    // Try different field names that might be in the response
    final email = _bookingDetails['booking_email'] ??
        _bookingDetails['email'] ??
        _bookingDetails['user_email'] ??
        'N/A';
    final phone = _bookingDetails['booking_phone'] ??
        _bookingDetails['phone'] ??
        _bookingDetails['user_phone'] ??
        'N/A';

    // Print debug info
    print('Contact Details - Email: $email, Phone: $phone');
    print('All booking keys: ${_bookingDetails.keys.toList()}');

    return _buildSectionCard(
      title: 'Contact Details',
      icon: Icons.contact_mail_outlined,
      children: [
        _buildInfoRow('Email', email),
        _buildInfoRow('Phone', phone),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    final priceDetails = _bookingDetails['price_details'] is Map 
        ? Map<String, dynamic>.from(_bookingDetails['price_details'])
        : <String, dynamic>{};
    
    final paymentId = _bookingDetails['payment_id'] ?? 'N/A';
    final paymentMethod = _bookingDetails['payment_method']?.toString().toUpperCase() ?? 'N/A';
    final paymentStatus = _bookingDetails['payment_status']?.toString().toUpperCase() ?? 'N/A';

    return _buildSectionCard(
      title: 'Payment Details',
      icon: Icons.payment_outlined,
      children: [
        // Price Breakdown
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Price Breakdown',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
              fontSize: 15,
            ),
          ),
        ),
        if (priceDetails['adult_count'] != null && (priceDetails['adult_count'] as int) > 0)
          _buildPriceRow(
            '${priceDetails['adult_count']} Adult${(priceDetails['adult_count'] as int) > 1 ? 's' : ''}',
            '₹${(double.tryParse(priceDetails['base_fare_per_adult']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
          ),
        if (priceDetails['senior_count'] != null && (priceDetails['senior_count'] as int) > 0)
          _buildPriceRow(
            '${priceDetails['senior_count']} Senior${(priceDetails['senior_count'] as int) > 1 ? 's' : ''} (40% off)',
            '₹${(double.tryParse(priceDetails['base_fare_per_senior']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
          ),
        if (priceDetails['discount_applied'] != null)
          _buildPriceRow(
            'Discount',
            '-₹${(double.tryParse(priceDetails['discount_amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
            isDiscount: true,
          ),
        if (priceDetails['tax'] != null && (double.tryParse(priceDetails['tax'].toString()) ?? 0) > 0)
          _buildPriceRow(
            'Taxes & Fees',
            '₹${(double.tryParse(priceDetails['tax'].toString()) ?? 0).toStringAsFixed(2)}',
          ),
        const Divider(height: 24, thickness: 1),
        _buildPriceRow(
          'Total Amount',
          '₹${(double.tryParse(priceDetails['total']?.toString() ?? _bookingDetails['total_amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
          isTotal: true,
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Payment Method', paymentMethod),
        _buildInfoRow('Payment Status', paymentStatus),
        _buildInfoRow('Transaction ID', paymentId),
      ],
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ProductSans',
              color: isDiscount ? Colors.green : Colors.black87,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 15 : 14,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontFamily: 'ProductSans',
              color: isDiscount ? Colors.green : (isTotal ? const Color(0xFF7C3AED) : Colors.black87),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          'Download E-Ticket',
          Icons.download_outlined,
          onPressed: () {
            // Download ticket logic
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Cancel Booking',
          Icons.cancel_outlined,
          onPressed: () {
            // Cancel booking logic
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'ProductSans',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C3AED),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon, {
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDestructive ? const Color(0xFFFEE2E2) : const Color(0xFF7C3AED),
          foregroundColor:
              isDestructive ? const Color(0xFFB91C1C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
