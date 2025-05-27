import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'select_payment_method_screen.dart';
import 'transaction_details_screen.dart';

class ReviewSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> train;
  final String originName;
  final String destinationName;
  final String depTime;
  final String arrTime;
  final String date;
  final String selectedClass;
  final int price;
  final List<Map<String, dynamic>> passengers;

  String _calculateDuration(String dep, String arr) {
    // Dummy implementation, you can replace with actual duration logic
    return '4h';
  }
  
  // Helper method to get seat count safely
  int _getSeatCount() {
    // Try to get seat count from train data first
    if (train.containsKey('seat_count')) {
      // Handle both int and String types for seat_count
      if (train['seat_count'] is int) {
        return train['seat_count'];
      } else if (train['seat_count'] is String) {
        return int.tryParse(train['seat_count']) ?? 0;
      }
    }
    
    // Check seat availability for the selected class if available
    if (train.containsKey('seat_availability') && 
        train['seat_availability'] is Map && 
        train['seat_availability'].containsKey(selectedClass)) {
      final seatAvailability = train['seat_availability'][selectedClass];
      if (seatAvailability is int) {
        return seatAvailability;
      } else if (seatAvailability is String) {
        return int.tryParse(seatAvailability) ?? 0;
      }
    }
    
    // Last fallback based on price
    return price > 3000 ? 77 : 120; // If price is high, seats are likely filling up fast
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
  Widget build(BuildContext context) {
    final totalPrice = price + tax;
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            child: Icon(Icons.train, color: Color(0xFF7C3AED), size: 28),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  train['train_name'] ?? '',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  train['train_number'] != null ? 'Train No: ${train['train_number']}' : '',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                SizedBox(height: 2),
                                // Use only marquee without 'From' text to avoid overflow
                                _stationTextMarquee(
                                  '$originName → $destinationName',
                                  width: 150, // Reduced width to fit in the card
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF7C3AED),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Class: $selectedClass',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Availability indicator based on seat count
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getSeatCount() < 100 
                                  ? Color(0xFFFEE2E2) // Light red background for 'Filling up fast'
                                  : Color(0xFFE8F5E9), // Light green background for 'Available'
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
                                originName,
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                depTime,
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              Text(
                                date,
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
                                destinationName,
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                arrTime,
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              Text(
                                date,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
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
                      _infoRow('Email', email),
                      SizedBox(height: 10),
                      _infoRow('Phone Number', phone),
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
                      ...passengers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final p = entry.value;
                        // Check if passenger is a senior based on age
                        final isSenior = (p['age'] is int ? p['age'] : int.tryParse(p['age'].toString()) ?? 0) >= 60;
                        
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.person, color: Color(0xFF7C3AED), size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Passenger ${idx + 1}${isSenior ? ' - Senior' : ''}',
                                              style: TextStyle(
                                                fontFamily: 'ProductSans',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Seat indicator (placeholder)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF3E8FF),
                                            borderRadius: BorderRadius.circular(4),
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icon(Icons.account_balance_wallet, color: Color(0xFF7C3AED)),
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
                                  builder: (context) => SelectPaymentMethodScreen(
                                    walletBalance: 946.50, // TODO: Replace with actual wallet balance from user profile/state
                                    bookingId: 'PNR${DateTime.now().millisecondsSinceEpoch}',
                                    trainName: train['train_name'] ?? '',
                                    trainClass: selectedClass,
                                    departureStation: originName,
                                    arrivalStation: destinationName,
                                    departureTime: depTime,
                                    arrivalTime: arrTime,
                                    departureDate: date,
                                    arrivalDate: date,
                                    duration: _calculateDuration(depTime, arrTime),
                                    price: price.toDouble(),
                                    tax: tax,
                                    totalPrice: price.toDouble() + tax,
                                    status: 'Paid',
                                    transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
                                    merchantId: 'MERCHANT123',
                                    paymentMethod: 'Wallet',
                                    passengers: passengers.map((p) => Passenger(
                                      fullName: p['name'] ?? '',
                                      idType: p['id_type'] ?? '',
                                      idNumber: p['id_number'] ?? '',
                                      passengerType: (p['age'] is int ? p['age'] : int.tryParse(p['age'].toString()) ?? 0) >= 60 ? 'Senior' : 'Adult',
                                      seat: p['seat'] ?? 'B2-34',
                                    )).toList(),
                                  ),
                                ),
                              );
                            },
                            child: Text('Change', style: TextStyle(fontFamily: 'ProductSans', color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
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
                              decoration: InputDecoration(
                                hintText: 'Enter Code',
                                hintStyle: TextStyle(fontFamily: 'ProductSans', color: Colors.black38),
                                filled: true,
                                fillColor: Color(0xFFF7F7FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              style: TextStyle(fontFamily: 'ProductSans', fontSize: 15),
                            ),
                          ),
                          SizedBox(width: 12),
                          SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SelectPaymentMethodScreen(
                                      walletBalance: 946.50, // TODO: Replace with actual wallet balance from user profile/state
                                      bookingId: 'PNR${DateTime.now().millisecondsSinceEpoch}',
                                      trainName: train['train_name'] ?? '',
                                      trainClass: selectedClass,
                                      departureStation: originName,
                                      arrivalStation: destinationName,
                                      departureTime: depTime,
                                      arrivalTime: arrTime,
                                      departureDate: date,
                                      arrivalDate: date,
                                      duration: _calculateDuration(depTime, arrTime),
                                      price: price.toDouble(),
                                      tax: tax,
                                      totalPrice: price.toDouble() + tax,
                                      status: 'Paid',
                                      transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
                                      merchantId: 'MERCHANT123',
                                      paymentMethod: 'Wallet',
                                      passengers: passengers.map((p) => Passenger(
                                        fullName: p['fullName'],
                                        idType: p['idType'],
                                        idNumber: p['idNumber'],
                                        passengerType: p['passengerType'],
                                        seat: p['seat'] ?? 'B2-34',
                                      )).toList(),
                                    ),
                                  ),
                                );
                              },
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                )),
                                padding: MaterialStateProperty.all(EdgeInsets.zero),
                                elevation: MaterialStateProperty.all(0),
                                backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                overlayColor: MaterialStateProperty.all(Color(0xFF9F7AEA).withOpacity(0.08)),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  constraints: BoxConstraints(minWidth: 90, minHeight: 42),
                                  child: Text('Redeem',
                                    style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Color(0xFF7C3AED)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You have 25 coins',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          StatefulBuilder(
                            builder: (context, setState) {
                              bool useCoins = false;
                              return Switch(
                                value: useCoins,
                                onChanged: (v) {
                                  setState(() {
                                    useCoins = v;
                                  });
                                },
                                activeColor: Color(0xFF7C3AED),
                              );
                            },
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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
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
                      _priceRow('Price (Adult x ${passengers.length})', price),
                      _priceRow('Tax', tax),
                      Divider(),
                      _priceRow('Total Price', price + tax, bold: true),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectPaymentMethodScreen(
                          walletBalance: 946.50, // TODO: Replace with actual wallet balance from user profile/state
                          bookingId: 'PNR${DateTime.now().millisecondsSinceEpoch}',
                          trainName: train['train_name'] ?? '',
                          trainClass: selectedClass,
                          departureStation: originName,
                          arrivalStation: destinationName,
                          departureTime: depTime,
                          arrivalTime: arrTime,
                          departureDate: date,
                          arrivalDate: date,
                          duration: _calculateDuration(depTime, arrTime),
                          price: price.toDouble(),
                          tax: tax,
                          totalPrice: price.toDouble() + tax,
                          status: 'Paid',
                          transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
                          merchantId: 'MERCHANT123',
                          paymentMethod: 'Wallet',
                          passengers: passengers.map((p) => Passenger(
                            fullName: p['fullName'] ?? '',
                            idType: p['idType'] ?? '',
                            idNumber: p['idNumber'] ?? '',
                            passengerType: p['passengerType'] ?? '',
                            seat: p['seat'] ?? 'B2-34',
                          )).toList(),
                        ),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                    elevation: MaterialStateProperty.all(0),
                    overlayColor: MaterialStateProperty.all(Color(0xFF9F7AEA).withOpacity(0.08)),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Confirm Booking',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        )),
                  ),
                ),
              ),
            ], // <-- End of children for Column
          ), // <-- End of Column
        ), // <-- End of Padding
      ), // <-- End of SingleChildScrollView
    ); // <-- End of Scaffold
  
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontFamily: 'ProductSans', color: Colors.black54, fontSize: 13))),
        Expanded(
            child: Text(value, style: TextStyle(fontFamily: 'ProductSans', color: Colors.black87, fontSize: 14))),
      ],
    );
  }

  TextStyle _headerStyle() => TextStyle(fontFamily: 'ProductSans', fontWeight: FontWeight.bold, color: Color(0xFF7C3AED), fontSize: 13);
  TextStyle _cellStyle() => TextStyle(fontFamily: 'ProductSans', color: Colors.black87, fontSize: 13);

  Widget _priceRow(String label, num value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }
}
