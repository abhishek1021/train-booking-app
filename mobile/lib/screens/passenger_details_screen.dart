import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/passenger_service.dart';
import 'review_summary_screen.dart';
import 'dart:convert';

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
  late List<Map<String, dynamic>> _passengerList;
  late List<TextEditingController> _nameControllers;
  late List<TextEditingController> _ageControllers;
  late List<TextEditingController> _idNumberControllers;
  late List<String> _idTypeValues;
  late List<String> _genderValues;
  late List<bool> _favouritePassengers;
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

    // Initialize with the number of passengers from the widget
    for (int i = 0; i < widget.passengers; i++) {
      _addPassenger();
    }

    // Initialize passenger service and load saved passengers
    _initPassengerService();
  }

  // Initialize passenger service
  Future<void> _initPassengerService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check if user object is present in prefs (logged in)
      final userJson = prefs.getString('user');
      if (userJson != null && userJson.isNotEmpty) {
        setState(() {
          _passengerService = PassengerService(prefs);
          _isLoadingSavedPassengers = true;
        });
        await _loadSavedPassengers();
      } else {
        setState(() {
          _savedPassengers = [];
          _isLoadingSavedPassengers = false;
        });
      }
    } catch (e) {
      print('Error initializing passenger service: $e');
      setState(() {
        _savedPassengers = [];
        _isLoadingSavedPassengers = false;
      });
    }
  }

  // Load saved passengers from database
  Future<void> _loadSavedPassengers() async {
    if (_passengerService == null) return;

    try {
      final passengers = await _passengerService!.getFavoritePassengers();

      if (mounted) {
        setState(() {
          _savedPassengers = passengers;
          _isLoadingSavedPassengers = false;
        });
      }
    } catch (e) {
      print('Error loading saved passengers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load saved passengers'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoadingSavedPassengers = false;
        });
      }
    }
  }

  // Use a saved passenger
  void _useSavedPassenger(Map<String, dynamic> passenger) {
    if (_passengerList.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 6 passengers allowed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final name = passenger['name'] ?? '';
    final age = passenger['age']?.toString() ?? '';
    final gender = passenger['gender'] ?? 'Male';
    final idType = passenger['id_type'] ?? 'Aadhar';
    final idNumber = passenger['id_number'] ?? '';

    setState(() {
      _nameControllers.add(TextEditingController(text: name));
      _ageControllers.add(TextEditingController(text: age));
      _idNumberControllers.add(TextEditingController(text: idNumber));
      _idTypeValues.add(idType);
      _genderValues.add(gender);
      _favouritePassengers.add(false);

      _passengerList.add({
        'name': name,
        'age': age,
        'gender': gender,
        'id_type': idType,
        'id_number': idNumber,
        'is_senior': (int.tryParse(age) ?? 0) >= 60,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $name to passengers'),
        backgroundColor: Color(0xFF7C3AED),
      ),
    );
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
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return 'Please enter a valid 10-digit mobile number';
    }

    // Validate terms and conditions
    if (!_termsAccepted) {
      return 'Please accept the terms and conditions to continue';
    }

    return null;
  }

  void _addPassenger() {
    if (_passengerList.length >= 6) return; // Safety check

    setState(() {
      _passengerList.add({});
      _nameControllers.add(TextEditingController());
      _ageControllers.add(TextEditingController());
      _idNumberControllers.add(TextEditingController());
      _idTypeValues.add('Aadhar');
      _genderValues.add('Male');
      _favouritePassengers.add(false);
    });
  }

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
                        title: Text(
                          'Passenger ${index + 1}',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                            fontSize: 16,
                          ),
                        ),
                        trailing: index > 0
                            ? IconButton(
                                icon: Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _passengerList.removeAt(index);
                                    _nameControllers.removeAt(index);
                                    _ageControllers.removeAt(index);
                                    _idNumberControllers.removeAt(index);
                                    _idTypeValues.removeAt(index);
                                    _genderValues.removeAt(index);
                                    if (_favouritePassengers.length > index) {
                                      _favouritePassengers.removeAt(index);
                                    }
                                  });
                                },
                              )
                            : null,
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
                            ),
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
                                value: (_favouritePassengers.length > index
                                    ? _favouritePassengers[index]
                                    : false),
                                onChanged: (v) {
                                  setState(() {
                                    while (
                                        _favouritePassengers.length <= index) {
                                      _favouritePassengers.add(false);
                                    }
                                    if (index < _favouritePassengers.length) {
                                      _favouritePassengers[index] = v ?? false;
                                    }
                                  });
                                },
                              ),
                              Text('Add to Passenger List - For Tatkal Mode',
                                  style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      color: Color(0xFF222222))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),

              // Saved Passengers Section
              // --- SAVED PASSENGERS SECTION ---
              if (_isLoadingSavedPassengers)
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
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                      ),
                    ),
                  ),
                )
              else if (_savedPassengers.isEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: 18),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 18.0),
                    child: Center(
                      child: Text(
                        'No favourite passenger stored',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                )
              else
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saved Passengers',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                                fontSize: 16,
                              ),
                            ),
                            if (!_isLoadingSavedPassengers)
                              IconButton(
                                icon: Icon(Icons.refresh,
                                    color: Color(0xFF7C3AED)),
                                onPressed: _loadSavedPassengers,
                                tooltip: 'Refresh saved passengers',
                              ),
                          ],
                        ),
                      ),
                      _isLoadingSavedPassengers
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF7C3AED)),
                                ),
                              ),
                            )
                          : _savedPassengers.isEmpty
                              ? Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'No saved passengers found',
                                      style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 150,
                                  padding:
                                      EdgeInsets.only(bottom: 16, left: 16),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _savedPassengers.length,
                                    itemBuilder: (context, index) {
                                      final passenger = _savedPassengers[index];
                                      return Container(
                                        width: 220,
                                        margin: EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF3E8FF),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Color(0xFF7C3AED),
                                            width: 1,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person,
                                                        color:
                                                            Color(0xFF7C3AED),
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          passenger['name'] ??
                                                              '',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'ProductSans',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.info_outline,
                                                        color: Colors.grey[600],
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        '${passenger['age'] ?? ''} yrs • ${passenger['gender'] ?? ''}',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'ProductSans',
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[800],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.badge_outlined,
                                                        color: Colors.grey[600],
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          '${passenger['id_type'] ?? ''}: ${passenger['id_number'] ?? ''}',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'ProductSans',
                                                            fontSize: 14,
                                                            color: Colors
                                                                .grey[800],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 12),
                                                  Expanded(
                                                    child: Align(
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child: ElevatedButton(
                                                        onPressed: () =>
                                                            _useSavedPassenger(
                                                                passenger),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Color(0xFF7C3AED),
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      12),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Use This Passenger',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'ProductSans',
                                                            fontSize: 13,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ],
                  ),
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
                                                  ? Color(0xFF7C3AED)
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
                      return Colors.transparent;
                    }),
                    overlayColor: MaterialStateProperty.all(
                        Color(0xFF9F7AEA).withOpacity(0.08)),
                  ),
                   onPressed: () async {
                    final error = _validateAllFields();
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error,
                              style: TextStyle(
                                color: Color(0xFFD32F2F), // Material red
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ProductSans',
                              )),
                          backgroundColor:
                              Color(0xFFF3E8FF), // Light purple/white
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
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
                      if (_favouritePassengers.length > i && _favouritePassengers[i]) {
                        passengersToSave.add(passengerMap);
                      }
                    }

                    if (passengersToSave.isNotEmpty && _passengerService != null) {
                      try {
                        // Ensure network call for each passenger
                        await _passengerService!.saveMultiplePassengers(passengersToSave);
                        // Optionally reload saved passengers after save
                        await _loadSavedPassengers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected passengers saved to your list!',
                                style: TextStyle(
                                  color: Color(0xFF388E3C),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ProductSans',
                                )),
                            backgroundColor: Color(0xFFE8F5E9),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewSummaryScreen(
                          train: widget.train,
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
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Continue',
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
}
