import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _gender = 'Male';
  bool _isSenior = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _stationTextMarquee(String text, {TextAlign align = TextAlign.left, Color color = Colors.black, double fontSize = 13, FontWeight fontWeight = FontWeight.w600}) {
    if (text.length > 14) {
      return SizedBox(
        width: 90,
        height: 20,
        child: Marquee(
          text: text,
          style: TextStyle(fontFamily: 'Lato', fontWeight: fontWeight, fontSize: fontSize, color: color),
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
        style: TextStyle(fontFamily: 'Lato', fontWeight: fontWeight, fontSize: fontSize, color: color),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE9DFFF), Color(0xFFD6C3FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trip Details', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7C3AED))),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _stationTextMarquee(trainName, fontWeight: FontWeight.bold, fontSize: 15),
                                if (trainNumber.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                                    child: Text('Train No: $trainNumber',
                                      style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED)),
                                    ),
                                  ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    _stationTextMarquee(widget.originName, fontWeight: FontWeight.bold),
                                    Icon(Icons.arrow_forward, color: Color(0xFF7C3AED), size: 18),
                                    _stationTextMarquee(widget.destinationName, fontWeight: FontWeight.bold),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Class', style: TextStyle(fontFamily: 'Lato', fontSize: 13, color: Colors.black54)),
                                Text(widget.selectedClass, style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7C3AED))),
                                SizedBox(height: 8),
                                Text('Fare', style: TextStyle(fontFamily: 'Lato', fontSize: 13, color: Colors.black54)),
                                Text('₹${widget.price}', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF7C3AED))),
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
                                Text('Departure', style: TextStyle(fontFamily: 'Lato', fontSize: 12, color: Colors.black54)),
                                Text(depTime, style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF7C3AED))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Arrival', style: TextStyle(fontFamily: 'Lato', fontSize: 12, color: Colors.black54)),
                                Text(arrTime, style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF7C3AED))),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Date: ${widget.date}', style: TextStyle(fontFamily: 'Lato', fontSize: 13, color: Colors.black87)),
                            Text('Seats: ${widget.seatCount}', style: TextStyle(fontFamily: 'Lato', fontSize: 13, color: Colors.green)),
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
                itemCount: widget.passengers,
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
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                        childrenPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Color(0xFFF7F7FA),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              labelStyle: TextStyle(fontFamily: 'Lato'),
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Age',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    filled: true,
                                    fillColor: Color(0xFFF7F7FA),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    labelStyle: TextStyle(fontFamily: 'Lato'),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                  value: 'Male',
                                  onChanged: (v) {},
                                  decoration: InputDecoration(
                                    labelText: 'Gender',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    filled: true,
                                    fillColor: Color(0xFFF7F7FA),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    labelStyle: TextStyle(fontFamily: 'Lato'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Checkbox(value: false, onChanged: (v) {}),
                              Text('Senior Citizen (60+)', style: TextStyle(fontFamily: 'Lato')),
                            ],
                          ),
                          SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                children: [
                                  Container(
                                    width: (constraints.maxWidth - 10) * 0.48,
                                    child: DropdownButtonFormField<String>(
                                      items: ['Aadhar', 'PAN', 'Driving License'].map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
                                      value: 'Aadhar',
                                      onChanged: (v) {},
                                      decoration: InputDecoration(
                                        labelText: 'ID Type',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        filled: true,
                                        fillColor: Color(0xFFF7F7FA),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        labelStyle: TextStyle(fontFamily: 'Lato'),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Container(
                                    width: (constraints.maxWidth - 10) * 0.52,
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'ID Number',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        filled: true,
                                        fillColor: Color(0xFFF7F7FA),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        labelStyle: TextStyle(fontFamily: 'Lato'),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              ExpansionPanelList.radio(
                expandedHeaderPadding: EdgeInsets.symmetric(vertical: 0),
                elevation: 1,
                children: [
                  ExpansionPanelRadio(
                    value: 'contact',
                    headerBuilder: (context, isExpanded) {
                      return ListTile(
                        title: Text('Contact Details', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                      );
                    },
                    body: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Email (for ticket & alerts)', border: OutlineInputBorder()),
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                    backgroundColor: MaterialStateProperty.resolveWith((states) {
                      return null;
                    }),
                    elevation: MaterialStateProperty.all(0),
                    overlayColor: MaterialStateProperty.all(Color(0xFF9F7AEA).withOpacity(0.08)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      // TODO: Next step or booking logic
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Passenger details submitted!')));
                    }
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text('Continue', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
