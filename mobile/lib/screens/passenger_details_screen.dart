import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/passenger_service.dart';
import 'review_summary_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> train;
  final String origin;
  final String destination;
  final String originName;
  final String destinationName;
  final String date;
  final String selectedClass;
  final int price;
  final int seatCount;
  final int passengers;

  const PassengerDetailsScreen({
    Key? key,
    required this.train,
    required this.origin,
    required this.destination,
    required this.originName,
    required this.destinationName,
    required this.date,
    required this.selectedClass,
    required this.price,
    required this.seatCount,
    required this.passengers,
  }) : super(key: key);

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late SharedPreferences _prefs; // Add SharedPreferences instance
  late List<Map<String, dynamic>> _passengerList;
  late List<TextEditingController> _nameControllers;
  late List<TextEditingController> _ageControllers;
  late List<TextEditingController> _idNumberControllers;
  late List<String> _idTypeValues;
  late List<String> _genderValues;
  late List<bool> _favouritePassengers;
  late List<bool> _addToPassengerList; // Track which passengers to save
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _gstCompanyNameController =
      TextEditingController();
  String _gender = 'Male';
  bool _isSenior = false;
  bool _termsAccepted = false;
  bool _showGstDetails = false;
  bool _showTravelInsurance = false;
  bool _optForInsurance = false;

  // Passenger service and related state
  PassengerService? _passengerService;
  List<dynamic> _savedPassengers = [];
  bool _isLoadingSavedPassengers = false;
  
  // Track which saved passengers are already used in passenger list
  // Key is ID number, value is true if used
  Map<String, bool> _usedSavedPassengers = {};
  
  // Track expansion state of passenger accordions
  List<bool> _customTileExpanded = [];

  @override
  void initState() {
    super.initState();
    _passengerList = [];
    _nameControllers = [];
    _ageControllers = [];
    _idNumberControllers = [];
    _idTypeValues = [];
    _genderValues = [];
    _favouritePassengers = [];
    _addToPassengerList = []; // Initialize _addToPassengerList as an empty list
    _customTileExpanded = []; // Initialize expansion state list
    _savedPassengers = []; // Initialize saved passengers list
    _isLoadingSavedPassengers = true; // Set loading state to true
    
    // Pre-initialize passenger list based on passenger count from home screen
    // Only create multiple accordions if more than 1 passenger is needed
    if (widget.passengers > 1) {
      for (int i = 0; i < widget.passengers; i++) {
        _addPassengerWithoutNotification();
      }
    }

    // Initialize SharedPreferences first, then passenger service
    _initSharedPreferences();
  }

  // Initialize SharedPreferences
  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    // Load user profile data for email and phone
    _loadUserProfileData();
    // Initialize passenger service after SharedPreferences is initialized
    await _initPassengerService();
    // Then load saved passengers
    _loadSavedPassengers();
  }
  
  // Load user profile data to pre-populate email and phone fields
  void _loadUserProfileData() {
    try {
      final userProfileJson = _prefs.getString('user_profile');
      print('Loading user profile: $userProfileJson');
      
      if (userProfileJson != null && userProfileJson.isNotEmpty) {
        final userProfile = jsonDecode(userProfileJson);
        
        // Check for email in different possible fields
        if (userProfile.containsKey('email') && userProfile['email'] != null) {
          setState(() {
            _emailController.text = userProfile['email'];
          });
          print('Pre-populated email: ${userProfile['email']}');
        } else if (userProfile.containsKey('Email') && userProfile['Email'] != null) {
          setState(() {
            _emailController.text = userProfile['Email'];
          });
          print('Pre-populated email: ${userProfile['Email']}');
        }
        
        // Check for phone in different possible fields
        if (userProfile.containsKey('phone') && userProfile['phone'] != null) {
          setState(() {
            _phoneController.text = userProfile['phone'];
          });
          print('Pre-populated phone: ${userProfile['phone']}');
        } else if (userProfile.containsKey('Phone') && userProfile['Phone'] != null) {
          setState(() {
            _phoneController.text = userProfile['Phone'];
          });
          print('Pre-populated phone: ${userProfile['Phone']}');
        } else if (userProfile.containsKey('mobile') && userProfile['mobile'] != null) {
          setState(() {
            _phoneController.text = userProfile['mobile'];
          });
          print('Pre-populated phone: ${userProfile['mobile']}');
        } else if (userProfile.containsKey('Mobile') && userProfile['Mobile'] != null) {
          setState(() {
            _phoneController.text = userProfile['Mobile'];
          });
          print('Pre-populated phone: ${userProfile['Mobile']}');
        }
      }
    } catch (e) {
      print('Error loading user profile data: $e');
    }
  }

  // Initialize passenger service
  Future<void> _initPassengerService() async {
    if (_prefs != null) {
      _passengerService = PassengerService(_prefs);
      if (mounted) {
        setState(() {
          _isLoadingSavedPassengers = true;
        });
      }
    } else {
      print('Error: SharedPreferences not initialized');
    }
  }

  // Load saved passengers from database
  Future<void> _loadSavedPassengers() async {
    if (_passengerService == null) return;

    // Set loading state
    setState(() {
      _isLoadingSavedPassengers = true;
    });

    try {
      final passengers = await _passengerService!.getFavoritePassengers();
      print('Loaded ${passengers.length} saved passengers');

      if (mounted) {
        setState(() {
          _savedPassengers = passengers;
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

  // Use a saved passenger
  void _useSavedPassenger(Map<String, dynamic> passenger) {
    if (_passengerList.length >= 6) {
      _showCustomSnackBar(
        message: 'Maximum 6 passengers allowed',
        icon: Icons.error,
        backgroundColor: Colors.red,
      );
      return;
    }

    final name = passenger['name'] ?? '';
    final age = passenger['age']?.toString() ?? '';
    final gender = passenger['gender'] ?? 'Male';
    final idType = passenger['id_type'] ?? 'Aadhar';
    final idNumber = passenger['id_number'] ?? '';
    
    // Check if this passenger is already in use
    if (_usedSavedPassengers.containsKey(idNumber) && _usedSavedPassengers[idNumber] == true) {
      _showCustomSnackBar(
        message: 'This passenger is already in your list',
        icon: Icons.warning,
        backgroundColor: Colors.orange,
      );
      return;
    }
    
    // Find the next available passenger index - always populate in order
    int targetIndex = _passengerList.length;
    
    setState(() {
      // Add the passenger to the list
      if (targetIndex >= _passengerList.length) {
        _nameControllers.add(TextEditingController(text: name));
        _ageControllers.add(TextEditingController(text: age));
        _idNumberControllers.add(TextEditingController(text: idNumber));
        _idTypeValues.add(idType);
        _genderValues.add(gender);
        _favouritePassengers.add(true); // Mark as a favorite since it came from saved list
        _addToPassengerList.add(false); // Disable checkbox since it's already saved
        _customTileExpanded.add(true); // Expand the new passenger accordion
        
        _passengerList.add({
          'name': name,
          'age': age,
          'gender': gender,
          'id_type': idType,
          'id_number': idNumber,
          'is_senior': (int.tryParse(age) ?? 0) >= 60,
          'from_saved_list': true, // Mark that this passenger came from saved list
          'saved_passenger_index': _findSavedPassengerIndex(idNumber), // Store the index for reference
        });
      }
      
      // Mark this passenger as used
      _usedSavedPassengers[idNumber] = true;
    });
    
    // Show a custom confirmation message
    _showCustomSnackBar(
      message: 'Passenger ${name} added as Passenger ${targetIndex + 1}',
      icon: Icons.person_add,
      backgroundColor: Color(0xFF7C3AED),
    );
  }
  
  // Find the index of a saved passenger by ID number
  int _findSavedPassengerIndex(String idNumber) {
    for (int i = 0; i < _savedPassengers.length; i++) {
      if (_savedPassengers[i]['id_number'] == idNumber) {
        return i;
      }
    }
    return -1;
  }
  
  // Remove a passenger from the list
  void _removePassenger(int index) {
    if (index < 0 || index >= _passengerList.length) return;
    
    // Get the passenger's ID number before removing
    final idNumber = _idNumberControllers[index].text;
    final fromSavedList = _passengerList[index].containsKey('from_saved_list') && 
                         _passengerList[index]['from_saved_list'] == true;
    
    setState(() {
      // Remove the passenger from the list
      _nameControllers.removeAt(index);
      _ageControllers.removeAt(index);
      _idNumberControllers.removeAt(index);
      _idTypeValues.removeAt(index);
      _genderValues.removeAt(index);
      _favouritePassengers.removeAt(index);
      _addToPassengerList.removeAt(index);
      _customTileExpanded.removeAt(index); // Remove expansion state
      
      // If the passenger came from saved list, mark it as available again
      if (fromSavedList && idNumber.isNotEmpty) {
        _usedSavedPassengers[idNumber] = false;
      }
      
      _passengerList.removeAt(index);
    });
    
    _showCustomSnackBar(
      message: 'Passenger removed',
      icon: Icons.person_remove,
      backgroundColor: Color(0xFF7C3AED),
    );
  }

  /// Validates ID number based on the ID type
  String? _validateIdNumber(String idNumber, String idType) {
    if (idNumber.isEmpty) {
      return null; // Empty validation will be handled separately
    }
    
    if (idType == 'Aadhar') {
      // Aadhar should be 12 digits
      if (idNumber.length != 12) {
        return 'Aadhar must be 12 digits';
      }
      
      // Check if Aadhar contains only numbers
      if (!RegExp(r'^[0-9]{12}$').hasMatch(idNumber)) {
        return 'Aadhar must contain only digits';
      }
    } else if (idType == 'PAN') {
      // PAN should be 10 characters
      if (idNumber.length != 10) {
        return 'PAN must be 10 characters';
      }
      
      // PAN format: AAAAA1234A (5 letters, 4 numbers, 1 letter)
      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(idNumber.toUpperCase())) {
        return 'Invalid PAN format';
      }
    } else if (idType == 'Driving License') {
      // Driving License should be between 13-16 characters
      if (idNumber.length < 13 || idNumber.length > 16) {
        return 'Driving License must be 13-16 characters';
      }
      
      // Driving License format: Usually alphanumeric
      // Format varies by state but generally follows a pattern
      // Most have 2 letters (state code) + 2 digits (RTO code) + 10 digits (unique number)
      if (!RegExp(r'^[A-Z0-9]{13,16}$').hasMatch(idNumber.toUpperCase())) {
        return 'Invalid Driving License format';
      }
    }
    
    return null;
  }

  /// Validates all passenger and contact fields.
  /// Returns an error message string if invalid, or null if all valid.
  String? _validateAllFields() {
    // Validate each passenger
    for (int i = 0; i < _passengerList.length; i++) {
      final name = _nameControllers[i].text.trim();
      final age = _ageControllers[i].text.trim();
      final gender = _genderValues[i];
      final idNum = _idNumberControllers[i].text.trim();
      final idType = _idTypeValues[i];

      if (name.isEmpty) {
        return 'Please enter full name for passenger ${i + 1}';
      }
      if (age.isEmpty) {
        return 'Please enter age for passenger ${i + 1}';
      }
      if (int.tryParse(age) == null) {
        return 'Please enter a valid age for passenger ${i + 1}';
      }
      if (gender == null || gender.isEmpty) {
        return 'Please select gender for passenger ${i + 1}';
      }
      if (idNum.isEmpty) {
        return 'Please enter ID number for passenger ${i + 1}';
      }
      if (idType == null || idType.isEmpty) {
        return 'Please select ID type for passenger ${i + 1}';
      }
      
      // Validate ID number format based on ID type
      String? idError = _validateIdNumber(idNum, idType);
      if (idError != null) {
        return 'Passenger ${i + 1}: $idError';
      }
    }

    // Validate contact details
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    if (phone.isEmpty) {
      return 'Please enter your mobile number';
    }
    // Support format like +919326808458
    // Allow + at the beginning, followed by country code and number
    // Total length should be between 12-15 digits including the + sign
    if (!RegExp(r'^\+?[0-9]{10,14}$').hasMatch(phone)) {
      return 'Please enter a valid mobile number with country code (e.g., +919326808458)';
    }

    // Validate terms and conditions
    if (!_termsAccepted) {
      return 'Please accept the terms and conditions to continue';
    }

    return null;
  }

  // Add a passenger without showing notification (used for initialization)
  void _addPassengerWithoutNotification() {
    // Add a new passenger to the list
    final newPassenger = {
      'name': '',
      'age': '',
      'gender': 'Male',
      'id_type': 'Aadhar',
      'id_number': '',
      'is_senior': false,
      'is_new': true, // Mark as newly added (not from saved list)
    };
    _passengerList.add(newPassenger);
    _nameControllers.add(TextEditingController());
    _ageControllers.add(TextEditingController());
    _idNumberControllers.add(TextEditingController());
    _idTypeValues.add('Aadhar');
    _genderValues.add('Male');
    _favouritePassengers.add(false);
    _addToPassengerList.add(true); // Set to true for newly added passengers
    _customTileExpanded.add(true); // Default to expanded for new passengers
  }

  void _addPassenger() {
    setState(() {
      // Add a new passenger using the helper method
      _addPassengerWithoutNotification();
      
      // Show confirmation message
      _showCustomSnackBar(
        message: 'New passenger added',
        icon: Icons.person_add,
        backgroundColor: Color(0xFF7C3AED),
      );
    });
  }

  // This is a duplicate initState method that was added by mistake - removing it

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _ageControllers) {
      c.dispose();
    }
    for (final c in _idNumberControllers) {
      c.dispose();
    }
    _emailController.dispose();
    _phoneController.dispose();
    _gstNumberController.dispose();
    _gstCompanyNameController.dispose();
    super.dispose();
  }

  void _showCustomSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.all(10),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _stationTextMarquee(String text,
      {TextAlign align = TextAlign.left,
      Color color = Colors.black,
      double fontSize = 13,
      FontWeight fontWeight = FontWeight.w600}) {
    if (text.length > 14) {
      return SizedBox(
        width: 90,
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
          textDirection: TextDirection.ltr,
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

  @override
  Widget build(BuildContext context) {
    final train = widget.train;
    final trainName = train['train_name'] ?? train['name'] ?? '';
    final trainNumber = train['train_number']?.toString() ?? '';
    final depTime = (train['schedule'] != null && train['schedule'].isNotEmpty)
        ? (train['schedule'].first['departure'] ?? '')
        : '';
    final arrTime = (train['schedule'] != null && train['schedule'].isNotEmpty)
        ? (train['schedule'].last['arrival'] ?? '')
        : '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(Icons.train, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: _stationTextMarquee(
                '${widget.originName} → ${widget.destinationName}',
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip summary card
              Card(
                margin: EdgeInsets.only(bottom: 22),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trip Details',
                            style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF7C3AED))),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _stationTextMarquee(trainName,
                                    fontWeight: FontWeight.bold, fontSize: 17),
                                if (trainNumber.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 2.0, bottom: 2.0),
                                    child: Text(
                                      'Train No: $trainNumber',
                                      style: TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF7C3AED)),
                                    ),
                                  ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    _stationTextMarquee(widget.originName,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                    Icon(Icons.arrow_forward,
                                        color: Color(0xFF7C3AED), size: 20),
                                    _stationTextMarquee(widget.destinationName,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Class',
                                    style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontSize: 15,
                                        color: Colors.black54)),
                                Text(widget.selectedClass,
                                    style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF7C3AED))),
                                SizedBox(height: 8),
                                Text('Fare',
                                    style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontSize: 15,
                                        color: Colors.black54)),
                                Text('₹${widget.price}',
                                    style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                        color: Color(0xFF7C3AED))),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Departure',
                                    style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontSize: 14,
                                        color: Colors.black54)),
                                Text(depTime,
                                    style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Color(0xFF7C3AED))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Arrival',
                                    style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontSize: 14,
                                        color: Colors.black54)),
                                Text(arrTime,
                                    style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Color(0xFF7C3AED))),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Date: ${widget.date}',
                                style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 15,
                                    color: Colors.black87)),
                            Text('Seats: ${widget.seatCount}',
                                style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 15,
                                    color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Saved Passengers Horizontal Scroll
              Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saved Passengers',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          if (!_isLoadingSavedPassengers)
                            IconButton(
                              icon: Icon(Icons.refresh, color: Color(0xFF7C3AED)),
                              onPressed: _loadSavedPassengers,
                              tooltip: 'Refresh saved passengers',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              splashRadius: 20,
                            ),
                        ],
                      ),
                    ),
                    _isLoadingSavedPassengers
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                          ),
                        )
                      : _savedPassengers.isEmpty
                        ? Container(
                            margin: EdgeInsets.symmetric(horizontal: 16.0),
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'No favourite passenger stored',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            height: 130,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _savedPassengers.length,
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              itemBuilder: (context, index) {
                                final passenger = _savedPassengers[index];
                                // Check if this passenger is already used in the passenger list
                                final idNumber = passenger['id_number'] ?? '';
                                final isUsed = _usedSavedPassengers.containsKey(idNumber) && 
                                              _usedSavedPassengers[idNumber] == true;
                                
                                return GestureDetector(
                                  // Only allow tapping if the passenger is not already used
                                  onTap: isUsed ? null : () => _useSavedPassenger(passenger),
                                  child: Container(
                                    width: 200,
                                    margin: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                                    padding: EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      // Gray out the card if already used
                                      color: isUsed ? Color(0xFFF3F4F6) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isUsed ? Color(0xFFD1D5DB) : Color(0xFFE5E7EB)),
                                      boxShadow: isUsed ? [] : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          passenger['name'] ?? '',
                                          style: TextStyle(
                                            fontFamily: 'ProductSans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF111827),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${passenger['age'] ?? ''} yrs • ${passenger['gender'] ?? ''}',
                                          style: TextStyle(
                                            fontFamily: 'ProductSans',
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${passenger['id_type'] ?? ''}: ${passenger['id_number'] ?? ''}',
                                          style: TextStyle(
                                            fontFamily: 'ProductSans',
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Spacer(),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isUsed ? Color(0xFFE5E7EB) : Color(0xFFF3E8FF),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isUsed ? 'Already used' : 'Tap to use',
                                            style: TextStyle(
                                              fontFamily: 'ProductSans',
                                              color: isUsed ? Color(0xFF6B7280) : Color(0xFF7C3AED),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
              
              // Passenger Details Accordion Section
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _passengerList.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                        childrenPadding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.white,
                        collapsedBackgroundColor: Colors.white,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Passenger ${index + 1}',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Remove button - call the _removePassenger method
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removePassenger(index),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              splashRadius: 20,
                              tooltip: 'Remove passenger',
                            ),
                            Icon(_customTileExpanded[index] ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                                 color: Color(0xFF7C3AED)),
                          ],
                        ),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _customTileExpanded[index] = expanded;
                          });
                        },
                        children: [
                          TextFormField(
                            controller: _nameControllers[index],
                            style: TextStyle(
                                color: Color(0xFF222222),
                                fontFamily: 'ProductSans'),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7C3AED)),
                              filled: true,
                              fillColor: Color(0xFFF7F7FA),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ageControllers[index],
                                  style: TextStyle(
                                      color: Color(0xFF222222),
                                      fontFamily: 'ProductSans'),
                                  decoration: InputDecoration(
                                    labelText: 'Age',
                                    labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED)),
                                    filled: true,
                                    fillColor: Color(0xFFF7F7FA),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _idTypeValues[index],
                                  style: TextStyle(
                                      color: Color(0xFF222222),
                                      fontFamily: 'ProductSans'),
                                  onChanged: (v) {
                                    setState(() {
                                      _idTypeValues[index] = v ?? 'Aadhar';
                                    });
                                  },
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: Color(0xFF7C3AED),
                                  items: ['Aadhar', 'PAN', 'Driving License']
                                      .map((id) => DropdownMenuItem(
                                          value: id, child: Text(id)))
                                      .toList(),
                                  decoration: InputDecoration(
                                    labelText: 'ID Type',
                                    labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED)),
                                    filled: true,
                                    fillColor: Color(0xFFF7F7FA),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _genderValues[index],
                                  style: TextStyle(
                                      color: Color(0xFF222222),
                                      fontFamily: 'ProductSans'),
                                  onChanged: (v) {
                                    setState(() {
                                      _genderValues[index] = v ?? 'Male';
                                    });
                                  },
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: Color(0xFF7C3AED),
                                  items: ['Male', 'Female', 'Other']
                                      .map((g) => DropdownMenuItem(
                                          value: g, child: Text(g)))
                                      .toList(),
                                  decoration: InputDecoration(
                                    labelText: 'Gender',
                                    labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED)),
                                    filled: true,
                                    fillColor: Color(0xFFF7F7FA),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: _idNumberControllers[index],
                            style: TextStyle(
                                color: Color(0xFF222222),
                                fontFamily: 'ProductSans'),
                            decoration: InputDecoration(
                              labelText: 'ID Number',
                              labelStyle: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7C3AED)),
                              filled: true,
                              fillColor: Color(0xFFF7F7FA),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              // Show hint text based on selected ID type
                              hintText: _idTypeValues[index] == 'Aadhar' 
                                  ? '12-digit Aadhar number' 
                                  : _idTypeValues[index] == 'PAN' 
                                      ? '10-character PAN number' 
                                      : _idTypeValues[index] == 'Driving License'
                                          ? '13-16 character Driving License'
                                          : 'Enter ID number',
                              // Show error message if validation fails
                              errorText: _validateIdNumber(_idNumberControllers[index].text, _idTypeValues[index]),
                              // Use darker error style
                              errorStyle: TextStyle(
                                color: Colors.red[900],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'ProductSans',
                              ),
                            ),
                            // Auto-capitalize for PAN card
                            textCapitalization: _idTypeValues[index] == 'PAN' 
                                ? TextCapitalization.characters 
                                : TextCapitalization.none,
                            // Set keyboard type based on ID type
                            keyboardType: _idTypeValues[index] == 'Aadhar' 
                                ? TextInputType.number 
                                : TextInputType.text,
                            // Update validation on text change
                            onChanged: (value) {
                              setState(() {
                                // This will trigger a rebuild to show validation errors
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Checkbox(
                                value: _ageControllers[index].text.isNotEmpty
                                    ? (int.tryParse(
                                                _ageControllers[index].text) ??
                                            0) >=
                                        60
                                    : false,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _ageControllers[index].text = '60';
                                    } else {
                                      _ageControllers[index].text = '';
                                    }
                                  });
                                },
                                activeColor: Color(0xFF7C3AED),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Text('Senior Citizen (60+)',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    color: Color(0xFF222222),
                                    fontSize: 14,
                                  )),
                            ],
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: (_addToPassengerList.length > index
                                    ? _addToPassengerList[index]
                                    : false),
                                // Disable checkbox if passenger is from saved list
                                onChanged: _passengerList.length > index && 
                                          _passengerList[index].containsKey('from_saved_list') && 
                                          _passengerList[index]['from_saved_list'] == true
                                    ? null // Null makes the checkbox disabled
                                    : (v) {
                                        setState(() {
                                          while (
                                              _addToPassengerList.length <= index) {
                                            _addToPassengerList.add(false);
                                          }
                                          if (index < _addToPassengerList.length) {
                                            _addToPassengerList[index] = v ?? false;
                                          }
                                        });
                                      },
                                activeColor: Color(0xFF7C3AED),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Text(
                                'Add to Passenger List - For Tatkal Mode',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  // Gray out text if checkbox is disabled
                                  color: _passengerList.length > index && 
                                        _passengerList[index].containsKey('from_saved_list') && 
                                        _passengerList[index]['from_saved_list'] == true
                                      ? Colors.grey[400]
                                      : Color(0xFF222222),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              // Add Passenger Button
              Container(
                margin: EdgeInsets.only(bottom: 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _passengerList.length >= 6 ? null : _addPassenger,
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      )),
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.grey[300]!;
                        }
                        return Color(0xFF7C3AED);
                      }),
                      overlayColor: MaterialStateProperty.all(
                          Color(0xFF9F7AEA).withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_rounded,
                          color: _passengerList.length >= 6
                              ? Colors.grey[600]
                              : Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          _passengerList.length >= 6
                              ? 'Maximum 6 passengers'
                              : 'Add Passenger (${_passengerList.length}/6)',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _passengerList.length >= 6
                                ? Colors.grey[600]
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Contact Details Accordion
              Container(
                margin: EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    childrenPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.white,
                    title: Text(
                      'Contact Details',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                        fontSize: 16,
                      ),
                    ),
                    children: [
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(
                            color: Color(0xFF222222),
                            fontFamily: 'ProductSans'),
                        decoration: InputDecoration(
                          labelText: 'Email (for ticket & alerts)',
                          labelStyle: TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED)),
                          filled: true,
                          fillColor: Color(0xFFF7F7FA),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        style: TextStyle(
                            color: Color(0xFF222222),
                            fontFamily: 'ProductSans'),
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          labelStyle: TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED)),
                          filled: true,
                          fillColor: Color(0xFFF7F7FA),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),

              // Additional Preferences Section
              Container(
                margin: EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    childrenPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.white,
                    title: Text(
                      'Additional Preferences',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                        fontSize: 16,
                      ),
                    ),
                    children: [
                      // Travel Insurance Option
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            childrenPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            title: Text(
                              'Travel Insurance',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF222222),
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              _optForInsurance ? 'Selected: Yes' : 'Optional',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                color: _optForInsurance
                                    ? Color(0xFF7C3AED)
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(
                              _showTravelInsurance
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Color(0xFF7C3AED),
                            ),
                            onExpansionChanged: (bool expanded) {
                              setState(() {
                                _showTravelInsurance = expanded;
                              });
                            },
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IRCTC Travel Insurance provides coverage for journey-related risks. Premium: ₹10 per passenger (inclusive of taxes).',
                                    style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _optForInsurance = true;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _optForInsurance
                                                ? Color(0xFF7C3AED)
                                                : Color(0xFFF7F7FA),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              side: BorderSide(
                                                color: _optForInsurance
                                                    ? Color(0xFF7C3AED)
                                                    : Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10),
                                          ),
                                          child: Text(
                                            'Yes, I want insurance',
                                            style: TextStyle(
                                              color: _optForInsurance
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                              fontFamily: 'ProductSans',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _optForInsurance = false;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: !_optForInsurance
                                                ? Color(0xFF7C3AED)
                                                : Color(0xFFF7F7FA),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              side: BorderSide(
                                                color: !_optForInsurance
                                                    ? Color(0xFF7C3AED)
                                                    : Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10),
                                          ),
                                          child: Text(
                                            'No, thanks',
                                            style: TextStyle(
                                              color: !_optForInsurance
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                              fontFamily: 'ProductSans',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
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

                      // GST Details Option
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            childrenPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            title: Text(
                              'GST Details (Optional)',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF222222),
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              _gstNumberController.text.isNotEmpty
                                  ? 'GSTIN: ${_gstNumberController.text}'
                                  : 'Add GST details for business travel',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                color: _gstNumberController.text.isNotEmpty
                                    ? Color(0xFF7C3AED)
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(
                              _showGstDetails
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Color(0xFF7C3AED),
                            ),
                            onExpansionChanged: (bool expanded) {
                              setState(() {
                                _showGstDetails = expanded;
                              });
                            },
                            children: [
                              Column(
                                children: [
                                  TextFormField(
                                    controller: _gstNumberController,
                                    style: TextStyle(
                                        color: Color(0xFF222222),
                                        fontFamily: 'ProductSans'),
                                    decoration: InputDecoration(
                                      labelText: 'GSTIN',
                                      hintText: '22AAAAA0000A1Z5',
                                      labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED),
                                        fontSize: 12,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _gstCompanyNameController,
                                    style: TextStyle(
                                        color: Color(0xFF222222),
                                        fontFamily: 'ProductSans'),
                                    decoration: InputDecoration(
                                      labelText: 'Company Name',
                                      labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED),
                                        fontSize: 12,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Terms and Conditions Checkbox
              Container(
                margin: EdgeInsets.only(bottom: 18),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: _termsAccepted,
                        onChanged: (bool? value) {
                          setState(() {
                            _termsAccepted = value ?? false;
                          });
                        },
                        activeColor: Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, right: 8),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Color(0xFF555555),
                              fontSize: 12,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                  text:
                                      'By proceeding, I confirm that I have read and agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ', '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ', and '),
                              TextSpan(
                                text: 'Refund Policy',
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ' of TatkalPro.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Color(0xFFE0E0E0); // Light gray when disabled
                      }
                      return Colors.transparent;
                    }),
                    overlayColor: MaterialStateProperty.all(
                        Color(0xFF9F7AEA).withOpacity(0.08)),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Color(0xFF9E9E9E); // Gray text when disabled
                      }
                      return Colors.white;
                    }),
                  ),
                   onPressed: _passengerList.isEmpty ? null : () async {
                    final error = _validateAllFields();
                    if (error != null) {
                      _showCustomSnackBar(
                        message: error,
                        icon: Icons.error_outline,
                        backgroundColor: Colors.red,
                      );
                      return;
                    }

                    // Gather all passengers for navigation, and only checked for saving
                    final passengers = <Map<String, dynamic>>[];
                    final passengersToSave = <Map<String, dynamic>>[];
                    for (int i = 0; i < _passengerList.length; i++) {
                      final passengerMap = {
                        'name': _nameControllers[i].text.trim(),
                        'age': int.tryParse(_ageControllers[i].text.trim()) ?? 0,
                        'gender': _genderValues[i],
                        'id_type': _idTypeValues[i],
                        'id_number': _idNumberControllers[i].text.trim(),
                        'is_senior': (int.tryParse(_ageControllers[i].text.trim()) ?? 0) >= 60,
                        'carriage': '-', // Placeholder
                        'seat': '-', // Placeholder
                      };
                      passengers.add(passengerMap);
                      // Check if this passenger should be saved to the list
                      if (_addToPassengerList[i]) {
                        // Get UserID from the stored user_profile in SharedPreferences
                        String userId = '';
                        final userProfileJson = _prefs.getString('user_profile');
                        if (userProfileJson != null && userProfileJson.isNotEmpty) {
                          try {
                            final userProfile = jsonDecode(userProfileJson);
                            userId = userProfile['UserID'] ?? '';
                          } catch (e) {
                            print('Error parsing user profile: $e');
                          }
                        }
                        if (userId.isNotEmpty) {
                          final passengerToSave = {
                            ...passengerMap,
                            'user_id': userId,
                          };
                          passengersToSave.add(passengerToSave);
                        }
                      }
                    }

                    if (passengersToSave.isNotEmpty) {
                      try {
                        // Use the correct backend endpoint path
                        final baseUrl = ApiConstants.baseUrl;
                        int savedCount = 0;
                        
                        // Show loading indicator
                        _showCustomSnackBar(
                          message: 'Saving passengers to your list...',
                          icon: Icons.save,
                          backgroundColor: Color(0xFF7C3AED),
                        );
                        
                        for (var passenger in passengersToSave) {
                          final response = await http.post(
                            Uri.parse('$baseUrl/api/v1/passengers'),
                            headers: {
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode(passenger),
                          );
                          print('Passenger save response: ${response.statusCode} - ${response.body}');
                          if (response.statusCode >= 200 && response.statusCode < 300) {
                            savedCount++;
                          }
                        }
                        
                        // Reload saved passengers after save
                        await _loadSavedPassengers();
                        
                        // Show success message with custom snackbar
                        _showCustomSnackBar(
                          message: 'Saved $savedCount ${savedCount == 1 ? 'passenger' : 'passengers'} to your list!',
                          icon: Icons.check_circle,
                          backgroundColor: Colors.green,
                        );
                      } catch (e) {
                        print('Error saving passengers: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save passengers',
                                style: TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ProductSans',
                                )),
                            backgroundColor: Color(0xFFF3E8FF),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        );
                      }
                    }

                    // Gather contact details
                    final contactName = _nameControllers.isNotEmpty
                        ? _nameControllers[0].text.trim()
                        : '';
                    final contactEmail = _emailController.text.trim();
                    final contactPhone = _phoneController.text.trim();
                    // Update the train data to include seat count
                    final updatedTrain = Map<String, dynamic>.from(widget.train);
                    // Ensure seat_count is included in the train data
                    if (!updatedTrain.containsKey('seat_count')) {
                      updatedTrain['seat_count'] = widget.seatCount;
                    }
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewSummaryScreen(
                          train: updatedTrain, // Pass the updated train data with seat count
                          originName: widget.originName,
                          destinationName: widget.destinationName,
                          depTime: (widget.train['schedule'] != null &&
                                  widget.train['schedule'].isNotEmpty)
                              ? (widget.train['schedule'].first['departure'] ??
                                  '')
                              : '',
                          arrTime: (widget.train['schedule'] != null &&
                                  widget.train['schedule'].isNotEmpty)
                              ? (widget.train['schedule'].last['arrival'] ?? '')
                              : '',
                          date: widget.date,
                          selectedClass: widget.selectedClass,
                          price: widget.price,
                          passengers: passengers,
                          email: contactEmail,
                          phone: contactPhone,
                          coins: 25, // Placeholder
                          tax: 2.0, // Placeholder
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _passengerList.isEmpty
                          ? null // No gradient when disabled
                          : LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                            ),
                      color: _passengerList.isEmpty ? Color(0xFFE0E0E0) : null, // Light gray background when disabled
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _passengerList.isEmpty ? Color(0xFF9E9E9E) : Colors.white, // Gray text when disabled
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
}
