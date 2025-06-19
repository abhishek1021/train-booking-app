import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'dart:math' show max;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'select_payment_method_screen.dart';
import 'transaction_details_screen.dart';
import '../models/passenger.dart';
import '../services/offer_service.dart';
import '../services/passenger_service.dart';

class ReviewSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> train;
  final String originName;
  final String destinationName;
  final String depTime;
  final String arrTime;
  final String date;
  final String selectedClass;
  final int price;
  final List<Map<String, dynamic>> passengers;

  final String email;
  final String phone;
  final int coins;
  final double tax;

  const ReviewSummaryScreen({
    Key? key,
    required this.train,
    required this.originName,
    required this.destinationName,
    required this.depTime,
    required this.arrTime,
    required this.date,
    required this.selectedClass,
    required this.price,
    required this.passengers,
    required this.email,
    required this.phone,
    this.coins = 0,
    this.tax = 2.0,
  }) : super(key: key);

  @override
  State<ReviewSummaryScreen> createState() => _ReviewSummaryScreenState();
}

class _ReviewSummaryScreenState extends State<ReviewSummaryScreen> {
  // List to store passengers that can be modified
  late List<Map<String, dynamic>> _passengers;
  bool _useCoins = false;
  final int _coinValue = 100; // Default coin value
  
  // Voucher related variables
  final TextEditingController _voucherController = TextEditingController();
  String? _offerErrorMessage;
  Map<String, dynamic>? _appliedOffer;
  double _discountAmount = 0.0;
  final OfferService _offerService = OfferService();
  
  // Passenger service for saving and loading passengers
  PassengerService? _passengerService;
  List<Map<String, dynamic>> _savedPassengers = [];
  bool _isLoadingSavedPassengers = false;
  // Map to track which saved passengers have been used
  final Map<String, bool> _usedSavedPassengers = {};

  @override
  void initState() {
    super.initState();
    _passengers = List.from(widget.passengers);
    _initPassengerService();
  }
  
  // Initialize passenger service and load saved passengers
  Future<void> _initPassengerService() async {
    final prefs = await SharedPreferences.getInstance();
    _passengerService = PassengerService(prefs);
    _loadSavedPassengers();
  }
  
  // Load saved passengers from the backend
  Future<void> _loadSavedPassengers() async {
    if (_passengerService == null) return;

    setState(() {
      _isLoadingSavedPassengers = true;
    });

    try {
      final passengers = await _passengerService!.getFavoritePassengers();
      print('Loaded ${passengers.length} saved passengers');

      if (mounted) {
        setState(() {
          // Cast the List<dynamic> to List<Map<String, dynamic>> using map function
          _savedPassengers = passengers
              .map((passenger) => Map<String, dynamic>.from(passenger as Map))
              .toList();
          _isLoadingSavedPassengers = false;
        });
      }
    } catch (e) {
      print('Error loading saved passengers: $e');
      if (mounted) {
        setState(() {
          _isLoadingSavedPassengers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }
  
  // Apply voucher code and calculate discount
  void _applyVoucher() {
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _offerErrorMessage = 'Please enter a voucher code';
      });
      return;
    }

    // Find the offer by code
    final offer = _offerService.getOfferByCode(code);
    if (offer == null) {
      setState(() {
        _offerErrorMessage = 'Invalid voucher code';
      });
      return;
    }

    // Prepare booking details for validation
    final bookingDetails = {
      'departureDate': DateFormat('yyyy-MM-dd').parse(widget.date),
      'passengers': widget.passengers,
      'isFirstBooking': false, // TODO: Get this from user profile
    };

    // Validate the offer
    if (!_offerService.isOfferValid(offer, bookingDetails)) {
      setState(() {
        _offerErrorMessage = 'This offer is not applicable to your booking';
      });
      return;
    }

    // Calculate discount amount
    final baseAmount = _getBaseFareForClass() * _passengers.length;
    _discountAmount = _offerService.calculateDiscount(offer, baseAmount);

    // Update state
    setState(() {
      _appliedOffer = offer;
      _offerErrorMessage = null;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Offer applied successfully!',
          style: TextStyle(fontFamily: 'ProductSans'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Remove applied voucher
  void _removeVoucher() {
    setState(() {
      _appliedOffer = null;
      _discountAmount = 0.0;
      _voucherController.clear();
      _offerErrorMessage = null;
    });
  }

  // Remove a passenger from the list
  void _removePassenger(int index) {
    setState(() {
      _passengers.removeAt(index);
    });
  }
  
  // Save passengers to backend
  Future<void> _savePassengers() async {
    print('Starting _savePassengers method');
    if (_passengerService == null) {
      print('Error: _passengerService is null');
      return;
    }
    
    try {
      print('Total passengers to process: ${_passengers.length}');
      // Process each passenger
      for (var passenger in _passengers) {
        print('Processing passenger: ${passenger['name']}');
        // Check if this passenger has the required fields for saving
        if (passenger.containsKey('name') && 
            passenger.containsKey('age') && 
            passenger.containsKey('gender') && 
            passenger.containsKey('id_type') && 
            passenger.containsKey('id_number')) {
          print('Passenger has all required fields');
          
          // Extract passenger data
          final name = passenger['name'] is TextEditingController 
              ? passenger['name'].text 
              : passenger['name']?.toString() ?? '';
              
          final age = passenger['age'] is TextEditingController 
              ? passenger['age'].text 
              : passenger['age']?.toString() ?? '';
              
          final gender = passenger['gender']?.toString() ?? 'Male';
          final idType = passenger['id_type']?.toString() ?? 'Aadhar';
          
          final idNumber = passenger['id_number'] is TextEditingController 
              ? passenger['id_number'].text 
              : passenger['id_number']?.toString() ?? '';
              
          // Skip if any essential field is empty
          if (name.isEmpty || age.isEmpty || idNumber.isEmpty) {
            print('Skipping passenger due to empty fields: name=$name, age=$age, idNumber=$idNumber');
            continue;
          }
          print('Processing passenger: name=$name, age=$age, gender=$gender, idType=$idType, idNumber=$idNumber');
          
          // Determine if this is a senior citizen
          final isSenior = (int.tryParse(age) ?? 0) >= 60;
          
          // Check if this passenger already exists in saved passengers
          bool passengerExists = false;
          String? existingId;
          
          for (var savedPassenger in _savedPassengers) {
            // Match based on ID number as it should be unique
            if (savedPassenger['id_number'] == idNumber) {
              passengerExists = true;
              existingId = savedPassenger['id']?.toString();
              break;
            }
          }
          
          try {
            if (passengerExists && existingId != null) {
              // Update existing passenger
              print('Updating existing passenger with ID: $existingId');
              final response = await _passengerService!.updateFavoritePassenger(
                existingId,
                {
                  'name': name,
                  'age': int.tryParse(age) ?? 0,
                  'gender': gender,
                  'id_type': idType,
                  'id_number': idNumber,
                  'is_senior': isSenior,
                }
              );
              print('Updated passenger response: $response');
            } else {
              // Add new passenger
              print('Adding new passenger: $name');
              final response = await _passengerService!.saveAsFavorite(
                name: name,
                age: age,
                gender: gender,
                idType: idType,
                idNumber: idNumber,
                isSenior: isSenior,
              );
              print('Saved new passenger response: $response');
            }
          } catch (e) {
            print('Error saving/updating passenger $name: $e');
          }
        }
      }
    } catch (e) {
      print('Error in _savePassengers: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    print('Finished _savePassengers method');
  }

  String _calculateDuration(String dep, String arr) {
    // Dummy implementation, you can replace with actual duration logic
    return '4h';
  }

  // Helper method to get seat count safely
  int _getSeatCount() {
    // Try to get seat count from train data first
    if (widget.train.containsKey('seat_count')) {
      // Handle both int and String types for seat_count
      if (widget.train['seat_count'] is int) {
        return widget.train['seat_count'];
      } else if (widget.train['seat_count'] is String) {
        return int.tryParse(widget.train['seat_count']) ?? 0;
      }
    }

    // Check seat availability for the selected class if available
    if (widget.train.containsKey('seat_availability') &&
        widget.train['seat_availability'] is Map &&
        widget.train['seat_availability'].containsKey(widget.selectedClass)) {
      final seatAvailability =
          widget.train['seat_availability'][widget.selectedClass];
      if (seatAvailability is int) {
        return seatAvailability;
      } else if (seatAvailability is String) {
        return int.tryParse(seatAvailability) ?? 0;
      }
    }

    // Last fallback based on price
    return widget.price > 3000
        ? 77
        : 120; // If price is high, seats are likely filling up fast
  }

  // Station text marquee widget for scrolling text
  Widget _stationTextMarquee(String text,
      {TextAlign align = TextAlign.left,
      Color color = Colors.black,
      double fontSize = 13,
      double width = 90,
      FontWeight fontWeight = FontWeight.w600}) {
    if (text.length > 14) {
      return SizedBox(
        width: width,
        height: 20,
        child: Marquee(
          text: text,
          style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: fontWeight,
              fontSize: fontSize,
              color: color),
          scrollAxis: Axis.horizontal,
          blankSpace: 30.0,
          velocity: 25.0,
          pauseAfterRound: Duration(milliseconds: 800),
          startAfter: Duration(milliseconds: 800),
          fadingEdgeStartFraction: 0.1,
          fadingEdgeEndFraction: 0.1,
          showFadingOnlyWhenScrolling: false,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      );
    } else {
      return Text(
        text,
        style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: fontWeight,
            fontSize: fontSize,
            color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
      );
    }
  }

  // Calculate total price with coin and voucher discounts if applicable
  double _calculateTotalPrice() {
    // Get base fare for the selected class
    double baseFare = _getBaseFareForClass();

    // Calculate fare based on number of passengers
    double totalBaseFare = 0.0;

    // Calculate fare for each passenger based on their type (adult, senior, etc.)
    for (var passenger in _passengers) {
      // Check if passenger is a senior citizen
      bool isSenior = false;
      if (passenger.containsKey('age')) {
        int age = passenger['age'] is int
            ? passenger['age']
            : int.tryParse(passenger['age'].toString()) ?? 0;
        isSenior = age >= 60;
      } else if (passenger.containsKey('is_senior')) {
        isSenior = passenger['is_senior'] == true;
      }

      // Apply senior discount (25% off) if applicable
      double passengerFare = isSenior ? baseFare * 0.75 : baseFare;
      totalBaseFare += passengerFare;
    }

    // Add tax
    double totalPrice = totalBaseFare + widget.tax;
    
    // Apply voucher discount if available
    if (_discountAmount > 0) {
      totalPrice = max(0, totalPrice - _discountAmount);
    }

    // Apply coin discount if toggle is on
    if (_useCoins) {
      // Calculate how many coins to use (up to the user's available coins)
      int coinsToUse = widget.coins;
      // Convert coins to discount amount (1 coin = 1 rupee)
      double coinDiscount = coinsToUse.toDouble();
      // Apply discount (ensure total doesn't go below 0)
      totalPrice = max(0, totalPrice - coinDiscount);
    }

    return totalPrice;
  }

  // Get base fare for the selected class
  double _getBaseFareForClass() {
    // Try to get class prices from train data
    if (widget.train.containsKey('class_prices') &&
        widget.train['class_prices'] is Map &&
        widget.train['class_prices'].containsKey(widget.selectedClass)) {
      var price = widget.train['class_prices'][widget.selectedClass];
      if (price is int) {
        return price.toDouble();
      } else if (price is double) {
        return price;
      } else if (price is String) {
        return double.tryParse(price) ?? widget.price.toDouble();
      }
    }

    // Fallback to widget price if class price not found
    return widget.price.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF7C3AED),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Review Summary',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Departure Train Card
              Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Train Logo Placeholder
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(0xFFF7F7FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.train,
                                color: Color(0xFF7C3AED), size: 28),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.train['train_name'] ?? '',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  widget.train['train_number'] != null
                                      ? 'Train No: ${widget.train['train_number']}'
                                      : '',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Class: ${widget.selectedClass}',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Seats: ${_getSeatCount()}',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Availability indicator based on seat count
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getSeatCount() < 100
                                  ? Color(
                                      0xFFFEE2E2) // Light red background for 'Filling up fast'
                                  : Color(
                                      0xFFE8F5E9), // Light green background for 'Available'
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getSeatCount() < 100
                                  ? 'Filling up fast'
                                  : 'Available',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                color: _getSeatCount() < 100
                                    ? Colors.red
                                    : Colors.green,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.originName,
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                widget.depTime,
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              Text(
                                widget.date,
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.train, color: Color(0xFF7C3AED)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.destinationName,
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                widget.arrTime,
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              Text(
                                widget.date,
                                style: TextStyle(
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
              ),
              // Contact Details Card
              Card(
                color: Colors.white,
                margin: EdgeInsets.only(bottom: 22),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact Details',
                          style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF7C3AED))),
                      SizedBox(height: 18),
                      _infoRow('Email', widget.email),
                      SizedBox(height: 10),
                      _infoRow('Phone Number', widget.phone),
                    ],
                  ),
                ),
              ),
              // Passenger Details Card
              Card(
                color: Colors.white,
                margin: EdgeInsets.only(bottom: 22),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: Color(0xFF7C3AED)),
                          SizedBox(width: 10),
                          Text('Passenger(s)',
                              style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87)),
                        ],
                      ),
                      SizedBox(height: 16),
                      ..._passengers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final p = entry.value;
                        // Check if passenger is a senior based on age
                        final isSenior = (p['age'] is int
                                ? p['age']
                                : int.tryParse(p['age'].toString()) ?? 0) >=
                            60;
                        // Determine if remove button should be enabled (only if more than 1 passenger)
                        final canRemove = _passengers.length > 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Color(0xFF7C3AED),
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p['fullName'] ?? '',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Remove passenger button
                                        GestureDetector(
                                          onTap: canRemove
                                              ? () => _removePassenger(idx)
                                              : null,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: canRemove
                                                  ? Colors.red.withOpacity(0.1)
                                                  : Colors.grey
                                                      .withOpacity(0.1),
                                            ),
                                            child: Icon(
                                              Icons.remove,
                                              color: canRemove
                                                  ? Colors.red
                                                  : Colors.grey,
                                              size: 16,
                                            ),
                                          ),
                                        ),

                                        // Seat indicator (placeholder)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF3E8FF),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            p['seat'] ?? 'B2-34',
                                            style: TextStyle(
                                              fontFamily: 'ProductSans',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Name',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                p['name'] ?? '',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Gender',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                p['gender'] ?? '',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Age',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                p['age']?.toString() ?? '',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ID Type',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                p['id_type'] ?? '',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ID Number',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                p['id_number'] ?? '',
                                                style: TextStyle(
                                                  fontFamily: 'ProductSans',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Payment Method Card
              Card(
                color: Colors.white,
                margin: EdgeInsets.only(bottom: 22),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              color: Color(0xFF7C3AED)),
                          SizedBox(width: 10),
                          Text('My Wallet',
                              style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87)),
                          Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SelectPaymentMethodScreen(
                                    walletBalance:
                                        946.50, // TODO: Replace with actual wallet balance from user profile/state
                                    bookingId:
                                        'PNR${DateTime.now().millisecondsSinceEpoch}',
                                    trainName: widget.train['train_name'] ?? '',
                                    trainNumber: widget.train['train_number'] ??
                                        widget.train['train_id'] ??
                                        '',
                                    trainClass: widget.selectedClass,
                                    departureStation: widget.originName,
                                    arrivalStation: widget.destinationName,
                                    departureTime: widget.depTime,
                                    arrivalTime: widget.arrTime,
                                    departureDate: widget.date,
                                    arrivalDate: widget.date,
                                    duration: _calculateDuration(
                                        widget.depTime, widget.arrTime),
                                    price: widget.price.toDouble(),
                                    tax: widget.tax,
                                    totalPrice: _calculateTotalPrice(),
                                    status: 'Paid',
                                    transactionId:
                                        'TXN${DateTime.now().millisecondsSinceEpoch}',
                                    merchantId: 'MERCHANT123',
                                    paymentMethod: 'Wallet',
                                    email: widget.email,
                                    phone: widget.phone,
                                    passengers: widget.passengers
                                        .map((p) => Passenger(
                                              fullName: p['name'] ?? '',
                                              idType: p['id_type'] ?? '',
                                              idNumber: p['id_number'] ?? '',
                                              passengerType: (p['age'] is int
                                                          ? p['age']
                                                          : int.tryParse(p[
                                                                          'age']
                                                                      ?.toString() ??
                                                                  '0') ??
                                                              0) >=
                                                      60
                                                  ? 'Senior'
                                                  : 'Adult',
                                              seat: p['seat'] ?? 'B2-34',
                                              age: p['age'] is int
                                                  ? p['age']
                                                  : int.tryParse(p['age']
                                                              ?.toString() ??
                                                          '30') ??
                                                      30,
                                              gender: p['gender'] ?? 'male',
                                              isSenior: p['is_senior'] ??
                                                  ((p['age'] is int
                                                          ? p['age']
                                                          : int.tryParse(p[
                                                                          'age']
                                                                      ?.toString() ??
                                                                  '0') ??
                                                              0) >=
                                                      60),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                            child: Text('Change',
                                style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    color: Color(0xFF7C3AED),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Discount/Voucher Card
              Card(
                color: Colors.white,
                margin: EdgeInsets.only(bottom: 22),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_offer, color: Color(0xFF7C3AED)),
                          SizedBox(width: 10),
                          Text('Discount / Voucher',
                              style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87)),
                        ],
                      ),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _voucherController,
                              enabled: _appliedOffer == null,
                              decoration: InputDecoration(
                                hintText: 'Enter Code',
                                errorText: _offerErrorMessage,
                                filled: true,
                                fillColor: _appliedOffer == null
                                    ? Color(0xFFF7F7FA)
                                    : Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              style: TextStyle(
                                  fontFamily: 'ProductSans', fontSize: 15),
                            ),
                          ),
                          SizedBox(width: 12),
                          SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed:
                                  _appliedOffer == null ? _applyVoucher : _removeVoucher,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: _appliedOffer == null
                                    ? Color(0xFF7C3AED)
                                    : Colors.red.shade50,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                _appliedOffer == null ? 'Apply' : 'Remove',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _appliedOffer == null
                                      ? Colors.white
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_appliedOffer != null) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _appliedOffer!['title'] ?? 'Offer Applied',
                                      style: TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.green.shade800),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'You saved ₹${_discountAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 13,
                                          color: Colors.green.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Coin Usage Card
              Card(
                color: Colors.white,
                margin: EdgeInsets.only(bottom: 22),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Color(0xFF7C3AED)),
                          SizedBox(width: 10),
                          Text('Use Coins',
                              style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87)),
                        ],
                      ),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          Text('You have ${widget.coins} coins',
                              style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Spacer(),
                          Switch(
                            value: _useCoins,
                            onChanged: (v) => setState(() => _useCoins = v),
                            activeColor: Color(0xFF7C3AED),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Use coins for your payments. You will get 5 coins after this order.',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Price Details Card
              Card(
                color: Colors.white,
                margin: EdgeInsets.only(bottom: 22),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price Details',
                          style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF7C3AED))),
                      SizedBox(height: 18),
                      // Base fare for each passenger type
                      ..._getPassengerTypeCounts().entries.map((entry) {
                        String passengerType = entry.key;
                        int count = entry.value;
                        double fare = _getBaseFareForClass();

                        // Apply discount for seniors
                        if (passengerType == 'Senior') {
                          return _priceRow(
                              '$passengerType (x$count)', fare * 0.75 * count,
                              note: '25% off');
                        } else {
                          return _priceRow(
                              '$passengerType (x$count)', fare * count);
                        }
                      }),
                      _priceRow('Tax', widget.tax),
                      _discountAmount > 0
                          ? _priceRow('Voucher Discount', -_discountAmount,
                              color: Colors.green)
                          : SizedBox(),
                      _useCoins
                          ? _priceRow('Coin Discount', -widget.coins,
                              color: Colors.green)
                          : SizedBox(),
                      Divider(),
                      _priceRow('Total Price', _calculateTotalPrice(),
                          bold: true),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                    padding: MaterialStateProperty.all(EdgeInsets.zero),
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor:
                        MaterialStateProperty.all(Colors.transparent),
                    overlayColor: MaterialStateProperty.all(
                        Color(0xFF9F7AEA).withOpacity(0.08)),
                  ),
                  onPressed: () async {
                    // print('Confirm Booking button pressed - saving passengers');
                    // await _savePassengers();
                    // print('Passenger saving completed');
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectPaymentMethodScreen(
                          walletBalance:
                              946.50, // TODO: Replace with actual wallet balance from user profile/state
                          bookingId:
                              'PNR${DateTime.now().millisecondsSinceEpoch}',
                          trainName: widget.train['train_name'] ?? '',
                          trainNumber: widget.train['train_number'] ??
                              widget.train['train_id'] ??
                              '',
                          trainClass: widget.selectedClass,
                          departureStation: widget.originName,
                          arrivalStation: widget.destinationName,
                          departureTime: widget.depTime,
                          arrivalTime: widget.arrTime,
                          departureDate: widget.date,
                          arrivalDate: widget.date,
                          duration: _calculateDuration(
                              widget.depTime, widget.arrTime),
                          price: widget.price.toDouble(),
                          tax: widget.tax,
                          totalPrice: _calculateTotalPrice(),
                          status: 'Paid',
                          transactionId:
                              'TXN${DateTime.now().millisecondsSinceEpoch}',
                          merchantId: 'MERCHANT123',
                          paymentMethod: 'Wallet',
                          passengers: _passengers
                              .map((p) => Passenger(
                                    fullName: p['name'] ?? '',
                                    idType: p['id_type'] ?? '',
                                    idNumber: p['id_number'] ?? '',
                                    passengerType:
                                        p['passenger_type'] ?? 'Adult',
                                    seat: p['seat'] ?? 'B2-34',
                                    age: p['age'] is int
                                        ? p['age']
                                        : int.tryParse(
                                                p['age']?.toString() ?? '30') ??
                                            30,
                                    gender: p['gender'] ?? 'male',
                                    isSenior: p['is_senior'] ?? false,
                                  ))
                              .toList(),
                          email: widget.email,
                          phone: widget.phone,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Confirm Booking',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.black54,
                    fontSize: 13))),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.black87,
                    fontSize: 14))),
      ],
    );
  }

  TextStyle _headerStyle() => TextStyle(
      fontFamily: 'ProductSans',
      fontWeight: FontWeight.bold,
      color: Color(0xFF7C3AED),
      fontSize: 13);
  TextStyle _cellStyle() =>
      TextStyle(fontFamily: 'ProductSans', color: Colors.black87, fontSize: 13);

  // Get counts of each passenger type (Adult, Senior, etc.)
  Map<String, int> _getPassengerTypeCounts() {
    Map<String, int> counts = {};

    for (var passenger in _passengers) {
      // Determine passenger type
      String passengerType = 'Adult'; // Default type

      // Check if passenger is a senior based on age
      if (passenger.containsKey('age')) {
        int age = passenger['age'] is int
            ? passenger['age']
            : int.tryParse(passenger['age'].toString()) ?? 0;
        passengerType = age >= 60 ? 'Senior' : 'Adult';
      } else if (passenger.containsKey('is_senior') &&
          passenger['is_senior'] == true) {
        passengerType = 'Senior';
      } else if (passenger.containsKey('passenger_type')) {
        passengerType = passenger['passenger_type'];
        // Capitalize first letter
        passengerType = passengerType.substring(0, 1).toUpperCase() +
            passengerType.substring(1).toLowerCase();
      }

      // Increment count for this passenger type
      counts[passengerType] = (counts[passengerType] ?? 0) + 1;
    }

    return counts;
  }

  Widget _priceRow(String label, dynamic value,
      {bool bold = false, Color? color, String? note}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (note != null) ...[
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      note,
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₹ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 16 : 14,
              color: color ?? (bold ? Color(0xFF7C3AED) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}