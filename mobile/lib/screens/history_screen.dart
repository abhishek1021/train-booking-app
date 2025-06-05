import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import 'transaction_details_screen.dart';
import '../models/passenger.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;

  const HistoryScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();
  List<dynamic> _bookings = [];
  List<dynamic> _transactions = [];
  bool _isLoadingBookings = true;
  bool _isLoadingTransactions = true;
  String? _walletId;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoadingBookings = true;
      _isLoadingTransactions = true;
      _errorMessage = '';
    });

    try {
      // Fetch bookings
      final bookings = await _bookingService.getBookingsByUserId(widget.userId);
      
      // Fetch wallet and transactions
      final wallet = await _bookingService.getWalletByUserId(widget.userId);
      _walletId = wallet['wallet_id'];
      
      if (_walletId != null) {
        final transactions = await _bookingService.getWalletTransactions(_walletId!);
        
        setState(() {
          _bookings = bookings;
          _transactions = transactions;
          _isLoadingTransactions = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Wallet not found';
          _isLoadingTransactions = false;
        });
      }
      
      setState(() {
        _isLoadingBookings = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
        _isLoadingBookings = false;
        _isLoadingTransactions = false;
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
          'History',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'ProductSans',
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Bookings'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _fetchData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Bookings Tab
                _isLoadingBookings
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                        ),
                      )
                    : _bookings.isEmpty
                        ? _buildEmptyState('No bookings found', Icons.train)
                        : _buildBookingsList(),

                // Transactions Tab
                _isLoadingTransactions
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                        ),
                      )
                    : _transactions.isEmpty
                        ? _buildEmptyState('No transactions found', Icons.account_balance_wallet)
                        : _buildTransactionsList(),
              ],
            ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: const Color(0xFF7C3AED).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 18,
              color: Colors.black87.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF7C3AED),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          final status = booking['booking_status'] ?? 'confirmed';
          final journeyDate = booking['journey_date'] ?? '';
          final trainName = booking['train_name'] ?? 'Train';
          final trainNumber = booking['train_number'] ?? booking['train_id'] ?? '';
          final origin = booking['origin_station_code'] ?? '';
          final destination = booking['destination_station_code'] ?? '';
          final travelClass = booking['travel_class'] ?? booking['class'] ?? '';
          final pnr = booking['pnr'] ?? '';
          final fare = booking['fare'] ?? '0';
          final passengers = booking['passengers'] ?? [];
          
          // Format date
          String formattedDate = journeyDate;
          try {
            final date = DateTime.parse(journeyDate);
            formattedDate = DateFormat('dd MMM yyyy').format(date);
          } catch (e) {
            // Use original date if parsing fails
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                _viewBookingDetails(booking);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.train,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$trainName ($trainNumber)',
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF7C3AED),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatStatus(status),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Journey',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Route',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$origin - $destination',
                                style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PNR',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pnr,
                                style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Class',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                travelClass,
                                style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fare',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹$fare',
                                style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${passengers.length} Passenger${passengers.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF7C3AED),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          final type = transaction['type'] ?? '';
          final amount = transaction['amount'] ?? '0';
          final source = transaction['source'] ?? '';
          final createdAt = transaction['created_at'] ?? '';
          final notes = transaction['notes'] ?? '';
          
          // Format date
          String formattedDate = '';
          try {
            final date = DateTime.parse(createdAt);
            formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
          } catch (e) {
            formattedDate = createdAt;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: type.toLowerCase() == 'credit'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      type.toLowerCase() == 'credit'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: type.toLowerCase() == 'credit'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source,
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notes,
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${type.toLowerCase() == 'credit' ? '+' : '-'}₹$amount',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: type.toLowerCase() == 'credit'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
    final totalAmount = double.tryParse(booking['total_amount']?.toString() ?? booking['fare'].toString()) ?? fare;
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

  String _formatStatus(String status) {
    return status.toUpperCase();
  }
}
