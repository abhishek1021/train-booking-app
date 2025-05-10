import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'review_summary_screen.dart';

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
  // ...existing fields...
  List<bool> _favouritePassengers = [];

  @override
  void initState() {
    super.initState();
    _favouritePassengers = List<bool>.filled(_passengerList.length, false, growable: true);
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
        return 'Please enter full name for passenger ${i + 1}.';
      }
      if (age.isEmpty) {
        return 'Please enter age for passenger ${i + 1}.';
      }
      if (gender.isEmpty) {
        return 'Please select gender for passenger ${i + 1}.';
      }
      if (idNum.isEmpty) {
        return 'Please enter ID number for passenger ${i + 1}.';
      }
      if (idType.isEmpty) {
        return 'Please select ID type for passenger ${i + 1}.';
      }
    }
    // Validate contact details
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (email.isEmpty) {
      return 'Please enter your email address.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    if (phone.isEmpty) {
      return 'Please enter your mobile number.';
    }
    if (phone.length < 10) {
      return 'Please enter a valid mobile number.';
    }
    return null;
  }
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _passengerList = <Map<String, dynamic>>[{}]; // Dynamic passenger list
  List<TextEditingController> _nameControllers = <TextEditingController>[TextEditingController()];
  List<TextEditingController> _ageControllers = <TextEditingController>[TextEditingController()];
  List<TextEditingController> _idNumberControllers = <TextEditingController>[TextEditingController()];
  List<String> _idTypeValues = <String>['Aadhar'];
  List<String> _genderValues = <String>['Male'];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _gender = 'Male';
  bool _isSenior = false;

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
    // _genderValues is just a list of strings, no dispose needed
    _emailController.dispose();
    _phoneController.dispose();
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
              fontFamily: 'Lato',
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
            fontFamily: 'Lato',
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
                                fontFamily: 'Lato',
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
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF7C3AED)),
                                    ),
                                  ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    _stationTextMarquee(widget.originName,
                                        fontWeight: FontWeight.bold, fontSize: 15),
                                    Icon(Icons.arrow_forward,
                                        color: Color(0xFF7C3AED), size: 20),
                                    _stationTextMarquee(widget.destinationName,
                                        fontWeight: FontWeight.bold, fontSize: 15),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Class',
                                    style: TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 15,
                                        color: Colors.black54)),
                                Text(widget.selectedClass,
                                    style: TextStyle(
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF7C3AED))),
                                SizedBox(height: 8),
                                Text('Fare',
                                    style: TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 15,
                                        color: Colors.black54)),
                                Text('₹${widget.price}',
                                    style: TextStyle(
                                        fontFamily: 'Lato',
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
                                        fontFamily: 'Lato',
                                        fontSize: 14,
                                        color: Colors.black54)),
                                Text(depTime,
                                    style: TextStyle(
                                        fontFamily: 'Lato',
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
                                        fontFamily: 'Lato',
                                        fontSize: 14,
                                        color: Colors.black54)),
                                Text(arrTime,
                                    style: TextStyle(
                                        fontFamily: 'Lato',
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
                                    fontFamily: 'Lato',
                                    fontSize: 15,
                                    color: Colors.black87)),
                            Text('Seats: ${widget.seatCount}',
                                style: TextStyle(
                                    fontFamily: 'Lato',
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
                            fontFamily: 'Lato',
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
                            style: TextStyle(color: Color(0xFF222222), fontFamily: 'Lato'),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: TextStyle(
                                  fontFamily: 'Lato',
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
                                  style: TextStyle(color: Color(0xFF222222), fontFamily: 'Lato'),
                                  decoration: InputDecoration(
                                    labelText: 'Age',
                                    labelStyle: TextStyle(
                                        fontFamily: 'Lato',
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
                                  style: TextStyle(color: Color(0xFF222222), fontFamily: 'Lato'),
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
                                        fontFamily: 'Lato',
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
                                  style: TextStyle(color: Color(0xFF222222), fontFamily: 'Lato'),
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
                                        fontFamily: 'Lato',
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
                            style: TextStyle(color: Color(0xFF222222), fontFamily: 'Lato'),
                            decoration: InputDecoration(
                              labelText: 'ID Number',
                              labelStyle: TextStyle(
                                  fontFamily: 'Lato',
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
                              Checkbox(value: false, onChanged: (v) {}),
                              Text('Senior Citizen (60+)',
                                  style: TextStyle(fontFamily: 'Lato', color: Color(0xFF222222))),
                            ],
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: (_favouritePassengers.length > index ? _favouritePassengers[index] : false),
                                onChanged: (v) {
                                  setState(() {
                                    while (_favouritePassengers.length <= index) {
                                      _favouritePassengers.add(false);
                                    }
                                    _favouritePassengers[index] = v ?? false;
                                  });
                                },
                              ),
                              Text('Add to Passenger List - For Tatkal Mode',
                                  style: TextStyle(fontFamily: 'Lato', color: Color(0xFF222222))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              // Add More Passengers button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                    padding: MaterialStateProperty.all(EdgeInsets.zero),
                    backgroundColor:
                        MaterialStateProperty.resolveWith((states) => null),
                    elevation: MaterialStateProperty.all(0),
                    overlayColor: MaterialStateProperty.all(
                        Color(0xFF9F7AEA).withOpacity(0.08)),
                  ),
                  onPressed: () {
                    setState(() {
                      _passengerList.add({});
                      _nameControllers.add(TextEditingController());
                      _ageControllers.add(TextEditingController());
                      _idNumberControllers.add(TextEditingController());
                      _idTypeValues.add('Aadhar');
                      _genderValues.add('Male');
                      _favouritePassengers.add(false);
                    });
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text('Add more passengers',
                          style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Contact Details Accordion styled as a card
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
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                        fontSize: 16,
                      ),
                    ),
                    children: [
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: Color(0xFF222222), fontFamily: 'Lato'),
                        decoration: InputDecoration(
                          labelText: 'Email (for ticket & alerts)',
                          labelStyle: TextStyle(
                              fontFamily: 'Lato',
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
                        style: TextStyle(color: Color(0xFF222222), fontFamily: 'Lato'),
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          labelStyle: TextStyle(
                              fontFamily: 'Lato',
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
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                      return Colors.transparent;
                    }),
                    overlayColor: MaterialStateProperty.all(Color(0xFF9F7AEA).withOpacity(0.08)),
                  ),
                  onPressed: () {
                    final error = _validateAllFields();
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error,
                              style: TextStyle(
                                color: Color(0xFFD32F2F), // Material red
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              )),
                          backgroundColor: Color(0xFFF3E8FF), // Light purple/white
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      );
                      return;
                    }
                    // Gather passenger data
                    final passengers = List.generate(_passengerList.length, (i) => {
                      'name': _nameControllers[i].text.trim(),
                      'age': _ageControllers[i].text.trim(),
                      'gender': _genderValues[i],
                      'idType': _idTypeValues[i],
                      'idNumber': _idNumberControllers[i].text.trim(),
                      'carriage': '-', // Placeholder, update if carriage info is available
                      'seat': '-', // Placeholder, update if seat info is available
                    });
                    // Gather contact details
                    final contactName = _nameControllers.isNotEmpty ? _nameControllers[0].text.trim() : '';
                    final contactEmail = _emailController.text.trim();
                    final contactPhone = _phoneController.text.trim();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewSummaryScreen(
                          train: widget.train,
                          originName: widget.originName,
                          destinationName: widget.destinationName,
                          depTime: (widget.train['schedule'] != null && widget.train['schedule'].isNotEmpty) ? (widget.train['schedule'].first['departure'] ?? '') : '',
                          arrTime: (widget.train['schedule'] != null && widget.train['schedule'].isNotEmpty) ? (widget.train['schedule'].last['arrival'] ?? '') : '',
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
                      gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text('Continue',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white)),
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
