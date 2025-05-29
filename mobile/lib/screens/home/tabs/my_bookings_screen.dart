import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/booking_service.dart';
import '../../booking_details_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  late TabController _tabController;
  bool _isLoading = true;
  String _userId = '';
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _pastBookings = [];
  String _sortBy = 'date_desc'; // Default sorting: newest first

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileJson = prefs.getString('user_profile');

      if (userProfileJson != null && userProfileJson.isNotEmpty) {
        final userProfile = jsonDecode(userProfileJson);
        final userId = userProfile['UserID'] ?? '';

        setState(() {
          _userId = userId;
        });

        if (userId.isNotEmpty) {
          await _fetchBookings(userId);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch bookings for a user
  Future<void> _fetchBookings(String userId) async {
    try {
      final bookingsData = await _bookingService.getBookingsByUserId(userId);
      
      List<Map<String, dynamic>> allBookings = [];
      List<Map<String, dynamic>> upcomingBookings = [];
      List<Map<String, dynamic>> pastBookings = [];
      
      final now = DateTime.now();
      
      for (var booking in bookingsData) {
        final Map<String, dynamic> bookingMap = Map<String, dynamic>.from(booking);
        
        // Parse journey date
        DateTime? journeyDate;
        try {
          if (bookingMap['journey_date'] != null) {
            journeyDate = DateTime.parse(bookingMap['journey_date']);
          }
        } catch (e) {
          print('Error parsing journey date: $e');
        }
        
        allBookings.add(bookingMap);
        
        // Separate upcoming and past bookings
        if (journeyDate != null) {
          if (journeyDate.isAfter(now) || journeyDate.day == now.day) {
            upcomingBookings.add(bookingMap);
          } else {
            pastBookings.add(bookingMap);
          }
        } else {
          // If journey date is not available, add to upcoming by default
          upcomingBookings.add(bookingMap);
        }
      }
      
      setState(() {
        _allBookings = allBookings;
        _upcomingBookings = upcomingBookings;
        _pastBookings = pastBookings;
        _sortBookings();
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() {
        _allBookings = [];
        _upcomingBookings = [];
        _pastBookings = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bookings: $e')),
      );
    }
  }
  
  // Sort bookings based on selected sort option
  void _sortBookings() {
    final comparisonFunction = _getSortComparison();
    
    _allBookings.sort(comparisonFunction);
    _upcomingBookings.sort(comparisonFunction);
    _pastBookings.sort(comparisonFunction);
  }
  
  // Get comparison function for sorting
  int Function(Map<String, dynamic>, Map<String, dynamic>) _getSortComparison() {
    switch (_sortBy) {
      case 'date_asc':
        return (a, b) {
          final dateA = a['journey_date'] != null ? DateTime.parse(a['journey_date']) : DateTime(2000);
          final dateB = b['journey_date'] != null ? DateTime.parse(b['journey_date']) : DateTime(2000);
          return dateA.compareTo(dateB);
        };
      case 'date_desc':
        return (a, b) {
          final dateA = a['journey_date'] != null ? DateTime.parse(a['journey_date']) : DateTime(2000);
          final dateB = b['journey_date'] != null ? DateTime.parse(b['journey_date']) : DateTime(2000);
          return dateB.compareTo(dateA);
        };
      case 'price_asc':
        return (a, b) {
          final priceA = a['fare'] != null ? double.tryParse(a['fare'].toString()) ?? 0.0 : 0.0;
          final priceB = b['fare'] != null ? double.tryParse(b['fare'].toString()) ?? 0.0 : 0.0;
          return priceA.compareTo(priceB);
        };
      case 'price_desc':
        return (a, b) {
          final priceA = a['fare'] != null ? double.tryParse(a['fare'].toString()) ?? 0.0 : 0.0;
          final priceB = b['fare'] != null ? double.tryParse(b['fare'].toString()) ?? 0.0 : 0.0;
          return priceB.compareTo(priceA);
        };
      default:
        return (a, b) {
          final dateA = a['journey_date'] != null ? DateTime.parse(a['journey_date']) : DateTime(2000);
          final dateB = b['journey_date'] != null ? DateTime.parse(b['journey_date']) : DateTime(2000);
          return dateB.compareTo(dateA);
        };
    }
  }
  
  // Format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
  
  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF059669); // Green
      case 'pending':
        return const Color(0xFFD97706); // Amber
      case 'cancelled':
        return const Color(0xFFB91C1C); // Red
      default:
        return const Color(0xFF6B7280); // Gray
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
          'My Bookings',
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
            onPressed: () => _loadUserData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'UPCOMING'),
            Tab(text: 'PAST'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              ),
            )
          : Column(
              children: [
                // Sort options
                _buildSortOptions(),
                
                // Bookings list
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Upcoming bookings
                      _buildBookingsList(_upcomingBookings),
                      
                      // Past bookings
                      _buildBookingsList(_pastBookings),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'Sort by:',
            style: TextStyle(
              fontFamily: 'ProductSans',
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('Newest First', 'date_desc'),
                  _buildSortChip('Oldest First', 'date_asc'),
                  _buildSortChip('Price: High to Low', 'price_desc'),
                  _buildSortChip('Price: Low to High', 'price_asc'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSortChip(String label, String sortValue) {
    final isSelected = _sortBy == sortValue;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFFF0EAFB),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _sortBy = sortValue;
              _sortBookings();
            });
          }
        },
      ),
    );
  }
  
  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No bookings found',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your bookings will appear here',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final bookingId = booking['booking_id'] ?? '';
        final pnr = booking['pnr'] ?? 'N/A';
        final journeyDate = booking['journey_date'] != null 
            ? _formatDate(booking['journey_date']) 
            : 'N/A';
        final originStation = booking['origin_station_code'] ?? 'N/A';
        final destinationStation = booking['destination_station_code'] ?? 'N/A';
        final status = booking['booking_status'] ?? 'Unknown';
        final travelClass = booking['class'] ?? 'N/A';
        final fare = booking['fare'] != null 
            ? double.tryParse(booking['fare'].toString()) ?? 0.0 
            : 0.0;
        final passengers = booking['passengers'] ?? [];
        final passengerCount = passengers.length;
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(bookingId: bookingId),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
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
              children: [
                // Header with PNR and status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            color: Color(0xFF7C3AED),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PNR: $pnr',
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Booking details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Journey details
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  originStation,
                                  style: const TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Departure',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              const Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF7C3AED),
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                journeyDate,
                                style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  destinationStation,
                                  style: const TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Arrival',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      
                      // Additional details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem(
                            'Class',
                            travelClass,
                            Icons.airline_seat_recline_normal,
                          ),
                          _buildDetailItem(
                            'Passengers',
                            passengerCount.toString(),
                            Icons.people_outline,
                          ),
                          _buildDetailItem(
                            'Fare',
                            '₹${fare.toStringAsFixed(2)}',
                            Icons.payments_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // View details button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF7C3AED),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7C3AED), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
