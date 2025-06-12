import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:convert';
import '../models/passenger.dart';

class TransactionDetailsScreen extends StatelessWidget {
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
                    bookingId,
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
                              trainName,
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Class: $trainClass',
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
                            departureStation,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            departureTime,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          Text(
                            departureDate,
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
                            duration,
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
                            arrivalStation,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            arrivalTime,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          Text(
                            arrivalDate,
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
                  _paymentRow('Price (Adult x 1)', price),
                  _paymentRow('Tax', tax),
                  const Divider(),
                  _paymentRow('Total Price', totalPrice, bold: true),
                  const SizedBox(height: 12),
                  _statusRow(status),
                  _infoRow('Payment Method', paymentMethod),
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
                  for (int i = 0; i < passengers.length; i++) ...[
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
                              (passengers[i].fullName.isNotEmpty
                                  ? passengers[i].fullName
                                  : 'Passenger ${i + 1}')),
                          _infoRow('ID Type', passengers[i].idType),
                          _infoRow('ID Number', passengers[i].idNumber),
                          _infoRow(
                              'Passenger Type',
                              (passengers[i].passengerType.isNotEmpty
                                  ? passengers[i].passengerType
                                  : 'Adult')),
                          _infoRow(
                              'Seat',
                              (passengers[i].seat.isNotEmpty
                                  ? passengers[i].seat
                                  : 'B2-${34 + i}')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            _actionButton(context, 'Order Train Food', Icons.fastfood),
            const SizedBox(height: 8),
            _actionButton(context, 'Re-Schedule Ticket', Icons.schedule),
            const SizedBox(height: 8),
            _actionButton(context, 'Cancel Ticket', Icons.cancel),
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

  Widget _actionButton(BuildContext context, String label, IconData icon) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
          ),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: ElevatedButton.icon(
          onPressed: () {},
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
