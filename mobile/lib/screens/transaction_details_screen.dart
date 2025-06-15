import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:convert';
import '../models/passenger.dart';
import '../services/booking_service.dart';
import '../widgets/success_animation_dialog.dart';
import '../widgets/failure_animation_dialog.dart';

class TransactionDetailsScreen extends StatefulWidget {
  // ... fields as before ...

  // Helper to build the QR data as JSON
  String _buildQrData() {
    // Use a compact, flat string for QR code reliability
    final passengerNames = passengers
        .map((p) => p.fullName.isNotEmpty ? p.fullName : 'Passenger')
        .join('|');
    final passengerSeats =
        passengers.map((p) => p.seat.isNotEmpty ? p.seat : 'B2-34').join('|');
    // Compose a compact string (pipe-separated)
    return [
      bookingId,
      trainName,
      trainClass,
      departureStation,
      arrivalStation,
      departureDate,
      passengerNames,
      passengerSeats
    ].join(';');
  }

  final String bookingId;
  final String barcodeData;
  final String trainName;
  final String trainClass;
  final String departureStation;
  final String arrivalStation;
  final String departureTime;
  final String arrivalTime;
  final String departureDate;
  final String arrivalDate;
  final String duration;
  final double price;
  final double tax;
  final double totalPrice;
  final String status;
  final String transactionId;
  final String merchantId;
  final String paymentMethod;
  final List<Passenger> passengers;

  const TransactionDetailsScreen({
    Key? key,
    required this.bookingId,
    required this.barcodeData,
    required this.trainName,
    required this.trainClass,
    required this.departureStation,
    required this.arrivalStation,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureDate,
    required this.arrivalDate,
    required this.duration,
    required this.price,
    required this.tax,
    required this.totalPrice,
    required this.status,
    required this.transactionId,
    required this.merchantId,
    required this.paymentMethod,
    required this.passengers,
  }) : super(key: key);
  
  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();

}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = false;
  bool _isCancelled = false;
  
  @override
  void initState() {
    super.initState();
    // Check if the booking is already cancelled
    _isCancelled = widget.status.toLowerCase() == 'cancelled';
  }
  
  // Helper to build the QR data for visual ticket display
  String _buildQrData() {
    // Create a comprehensive JSON object with all booking details
    final Map<String, dynamic> bookingData = {
      'booking_id': widget.bookingId,
      'pnr': widget.barcodeData,
      'status': widget.status,
      'train': {
        'name': widget.trainName,
        'class': widget.trainClass,
      },
      'journey': {
        'from': widget.departureStation,
        'to': widget.arrivalStation,
        'departure_date': widget.departureDate,
        'departure_time': widget.departureTime,
        'arrival_date': widget.arrivalDate,
        'arrival_time': widget.arrivalTime,
        'duration': widget.duration,
      },
      'payment': {
        'transaction_id': widget.transactionId,
        'merchant_id': widget.merchantId,
        'method': widget.paymentMethod,
        'base_fare': widget.price,
        'tax': widget.tax,
        'total': widget.totalPrice,
      },
      'passengers': widget.passengers.map((p) => {
        'name': p.fullName,
        'age': p.age,
        'gender': p.gender,
        'seat': p.seat,
        'type': p.passengerType,
      }).toList(),
    };
    
    // Convert to base64 encoded JSON
    final jsonString = jsonEncode(bookingData);
    final base64Data = base64Encode(utf8.encode(jsonString));
    
    // Create a URL that will display the ticket visually when scanned
    // This URL points to a hypothetical ticket viewer service
    // Replace with your actual ticket viewer URL in production
    return 'https://s3.us-east-1.amazonaws.com/www.tatkalpro.in/ticket-viewer.html?data=$base64Data';
    
    // Note: You'll need to implement a web page at this URL that can:
    // 1. Parse the base64 data from the URL parameter
    // 2. Decode it back to JSON
    // 3. Render a visual ticket with the booking information
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
          onPressed: () {
            // Always navigate to home screen
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
        title: const Text(
          'Transaction Details',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Booking ID:',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.bookingId,
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy,
                      size: 18, color: Color(0xFF7C3AED)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Copy to clipboard logic
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SizedBox(
                  height: 90,
                  child: BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: _buildQrData(),
                    width: 120,
                    height: 90,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You are obligated to present your e-boarding pass when boarding a train trip or during inspecting from passengers.',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Trip Details'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12, top: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.train,
                          color: Color(0xFF7C3AED), size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.trainName,
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Class: ${widget.trainClass}',
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.departureStation,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.departureTime,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          Text(
                            widget.departureDate,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.train, color: Color(0xFF7C3AED)),
                          Text(
                            widget.duration,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.arrivalStation,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.arrivalTime,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          Text(
                            widget.arrivalDate,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Payment Details'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12, top: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _paymentRow('Price (Adult x 1)', widget.price),
                  _paymentRow('Tax', widget.tax),
                  const Divider(),
                  _paymentRow('Total Price', widget.totalPrice, bold: true),
                  const SizedBox(height: 12),
                  _statusRow(widget.status),
                  _infoRow('Payment Method', widget.paymentMethod),
                ],
              ),
            ),
            _sectionTitle('Passenger(s)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12, top: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < widget.passengers.length; i++) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person,
                                  color: Color(0xFF7C3AED)),
                              const SizedBox(width: 8),
                              Text(
                                'Passenger ${i + 1}',
                                style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _infoRow(
                              'Full Name',
                              (widget.passengers[i].fullName.isNotEmpty
                                  ? widget.passengers[i].fullName
                                  : 'Passenger ${i + 1}')),
                          _infoRow('ID Type', widget.passengers[i].idType),
                          _infoRow('ID Number', widget.passengers[i].idNumber),
                          _infoRow(
                              'Passenger Type',
                              (widget.passengers[i].passengerType.isNotEmpty
                                  ? widget.passengers[i].passengerType
                                  : 'Adult')),
                          _infoRow(
                              'Seat',
                              (widget.passengers[i].seat.isNotEmpty
                                  ? widget.passengers[i].seat
                                  : 'B2-${34 + i}')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Only showing the cancel button

            // Only show cancel button if the journey date hasn't passed and booking isn't already cancelled
            _actionButton(
              context, 
              'Cancel Ticket', 
              Icons.cancel, 
              isDestructive: true,
              isDisabled: _isJourneyDatePassed() || _isCancelled,
              onPressed: _isJourneyDatePassed() || _isCancelled ? null : () {
                _showCancelConfirmationDialog();
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'ProductSans',
          fontWeight: FontWeight.bold,
          color: Color(0xFF7C3AED),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _paymentRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          Text(
            '\u20B9${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? Color(0xFF7C3AED) : Colors.black87,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String status) {
    return Row(
      children: [
        const Text(
          'Status:',
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: status == 'Paid' ? Color(0xFF059669) : Color(0xFFB91C1C),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  bool _isJourneyDatePassed() {
    try {
      final journeyDate = DateTime.parse(widget.departureDate);
      final now = DateTime.now();
      return journeyDate.isBefore(now);
    } catch (e) {
      print('Error parsing journey date: $e');
      return false;
    }
  }
  
  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking? The refund will be credited to your wallet.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No', style: TextStyle(color: Colors.black87)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _cancelBooking() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
          ),
        );
      },
    );
    
    try {
      // Call the cancel booking API
      final result = await _bookingService.cancelBooking(widget.bookingId);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Update state to reflect cancellation
      setState(() {
        _isLoading = false;
        _isCancelled = true;
      });
      
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SuccessAnimationDialog(
            message: 'Booking cancelled successfully! ₹${result['refund_amount']} has been credited to your wallet.',
            onAnimationComplete: () {
              // Navigate back to refresh the booking list
              Navigator.of(context).pop();
            },
          );
        },
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
      
      // Show error dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return FailureAnimationDialog(
            message: 'Failed to cancel booking. Please try again later.',
            onAnimationComplete: () {},
          );
        },
      );
      
      print('Error cancelling booking: $e');
    }
  }
  
  Widget _infoRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90, // Fixed width for labels to align them
            child: Text(
              label + ':',
              style: const TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.black87,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Allow up to 2 lines for longer values
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 16, color: Color(0xFF7C3AED)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                // Copy logic
              },
            ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, {VoidCallback? onPressed, bool isDestructive = false, bool isDisabled = false}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDisabled
              ? const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                )
              : isDestructive
                  ? const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    ),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: ElevatedButton.icon(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.zero,
          ),
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Passenger class is now imported from models/passenger.dart
