import 'package:flutter/material.dart';
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
            fontFamily: 'Lato',
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
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  train['train_number'] != null ? 'Train No: ${train['train_number']}' : '',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'From $originName → $destinationName',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Class: $selectedClass',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Available',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '₹${price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7C3AED),
                                  fontSize: 16,
                                ),
                              ),
                            ],
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
                                  fontFamily: 'Lato',
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                depTime,
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              Text(
                                date,
                                style: TextStyle(
                                  fontFamily: 'Lato',
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
                                  fontFamily: 'Lato',
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                arrTime,
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              Text(
                                date,
                                style: TextStyle(
                                  fontFamily: 'Lato',
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
                              fontFamily: 'Lato',
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
              // Passenger(s) Card
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
                      Text('Passenger(s)',
                          style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF7C3AED))),
                      SizedBox(height: 12),
                      ...List.generate(passengers.length, (idx) {
                        final p = passengers[idx];
                        return Container(
                          margin: EdgeInsets.only(bottom: 14),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFF7F7FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Passenger ${idx + 1}',
                                      style: TextStyle(
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87)),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text('Name: ${p['name'] ?? ''}', style: TextStyle(fontFamily: 'Lato', fontSize: 14, color: Colors.black87)),
                              Text('Gender: ${p['gender'] ?? ''}', style: TextStyle(fontFamily: 'Lato', fontSize: 14, color: Colors.black87)),
                              Text('Age: ${p['age'] ?? ''}', style: TextStyle(fontFamily: 'Lato', fontSize: 14, color: Colors.black87)),
                              Text('ID Type: ${p['idType'] ?? ''}', style: TextStyle(fontFamily: 'Lato', fontSize: 14, color: Colors.black87)),
                              Text('ID Number: ${p['idNumber'] ?? ''}', style: TextStyle(fontFamily: 'Lato', fontSize: 14, color: Colors.black87)),
                            ],
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
                                  fontFamily: 'Lato',
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
                            child: Text('Change', style: TextStyle(fontFamily: 'Lato', color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
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
                                  fontFamily: 'Lato',
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
                                hintStyle: TextStyle(fontFamily: 'Lato', color: Colors.black38),
                                filled: true,
                                fillColor: Color(0xFFF7F7FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              style: TextStyle(fontFamily: 'Lato', fontSize: 15),
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
                                      fontFamily: 'Lato',
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
                                fontFamily: 'Lato',
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
                          fontFamily: 'Lato',
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
                              fontFamily: 'Lato',
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
                          fontFamily: 'Lato',
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
            child: Text(label, style: TextStyle(fontFamily: 'Lato', color: Colors.black54, fontSize: 13))),
        Expanded(
            child: Text(value, style: TextStyle(fontFamily: 'Lato', color: Colors.black87, fontSize: 14))),
      ],
    );
  }

  TextStyle _headerStyle() => TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, color: Color(0xFF7C3AED), fontSize: 13);
  TextStyle _cellStyle() => TextStyle(fontFamily: 'Lato', color: Colors.black87, fontSize: 13);

  Widget _priceRow(String label, num value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Lato',
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
