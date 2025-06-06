import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import 'transaction_details_screen.dart';
import '../models/passenger.dart';

class PnrSearchScreen extends StatefulWidget {
  const PnrSearchScreen({Key? key}) : super(key: key);

  @override
  State<PnrSearchScreen> createState() => _PnrSearchScreenState();
}

class _PnrSearchScreenState extends State<PnrSearchScreen> {
  final TextEditingController _pnrController = TextEditingController();
  final BookingService _bookingService = BookingService();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _bookingDetails;

  @override
  void dispose() {
    _pnrController.dispose();
    super.dispose();
  }

  Future<void> _searchPnr() async {
    final pnr = _pnrController.text.trim();
    if (pnr.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter a PNR number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _bookingDetails = null;
    });

    try {
      final booking = await _bookingService.getBookingByPNR(pnr);
      setState(() {
        _bookingDetails = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
        title: const Text(
          'PNR Search',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50), // Top padding as per design guidelines
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter PNR Number',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pnrController,
                      decoration: InputDecoration(
                        hintText: 'e.g. PNR250603123456',
                        prefixIcon: const Icon(
                          Icons.confirmation_number,
                          color: Color(0xFF7C3AED),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 16,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onFieldSubmitted: (_) => _searchPnr(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _searchPnr,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Search',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_hasError && _errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Colors.red[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_bookingDetails != null) _buildBookingDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    final booking = _bookingDetails!;
    final pnr = booking['pnr'] ?? '';
    final trainName = booking['train_name'] ?? '';
    final trainNumber = booking['train_number'] ?? booking['train_id'] ?? '';
    final journeyDate = booking['journey_date'] ?? '';
    final origin = booking['origin_station_code'] ?? '';
    final destination = booking['destination_station_code'] ?? '';
    final travelClass = booking['travel_class'] ?? booking['class'] ?? '';
    final status = booking['booking_status'] ?? 'confirmed';
    final fare = booking['fare'] ?? '0';
    final passengers = booking['passengers'] ?? [];

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Card(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Booking Found',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('PNR', pnr),
                  _buildInfoRow('Train', '$trainName ($trainNumber)'),
                  _buildInfoRow('Journey Date', journeyDate),
                  _buildInfoRow('Route', '$origin - $destination'),
                  _buildInfoRow('Class', travelClass),
                  _buildInfoRow('Fare', '₹$fare'),
                  _buildInfoRow('Passengers', '${passengers.length}'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _viewBookingDetails(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Full Details',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'ProductSans',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
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

  void _viewBookingDetails(Map<String, dynamic> booking) {
    // Extract booking details
    final bookingId = booking['booking_id'] ?? '';
    final pnr = booking['pnr'] ?? '';
    final trainName = booking['train_name'] ?? '';
    final trainClass = booking['travel_class'] ?? booking['class'] ?? '';
    final departureStation = booking['origin_station_code'] ?? '';
    final arrivalStation = booking['destination_station_code'] ?? '';
    final journeyDate = booking['journey_date'] ?? '';
    final fare = double.tryParse(booking['fare'].toString()) ?? 0.0;
    final tax = double.tryParse(booking['tax']?.toString() ?? '0') ?? 0.0;
    final totalAmount = double.tryParse(booking['total_amount']?.toString() ??
            booking['fare'].toString()) ??
        fare;
    final status = booking['booking_status'] ?? 'confirmed';
    final paymentMethod = booking['payment_method'] ?? 'wallet';

    // Convert passengers to Passenger objects
    final List<dynamic> passengersData = booking['passengers'] ?? [];
    final List<Passenger> passengers = passengersData.map((p) {
      return Passenger(
        fullName: p['name'] ?? '',
        age: int.tryParse(p['age'].toString()) ?? 0,
        gender: p['gender'] ?? '',
        idType: p['id_type'] ?? '',
        idNumber: p['id_number'] ?? '',
        seat: p['seat'] ?? '',
        isSenior: p['is_senior'] == true,
      );
    }).toList();

    // Navigate to transaction details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(
          bookingId: bookingId,
          barcodeData: pnr,
          trainName: trainName,
          trainClass: trainClass,
          departureStation: departureStation,
          arrivalStation: arrivalStation,
          departureTime: booking['departure_time'] ?? '08:00',
          arrivalTime: booking['arrival_time'] ?? '14:00',
          departureDate: journeyDate,
          arrivalDate: journeyDate,
          duration: booking['duration'] ?? '6h',
          price: fare,
          tax: tax,
          totalPrice: totalAmount,
          status: status,
          transactionId: booking['payment_id'] ?? '',
          merchantId: 'TATKALPRO',
          paymentMethod: paymentMethod,
          passengers: passengers,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'waitlist':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
