import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchTab extends StatefulWidget {
  const SearchTab({Key? key}) : super(key: key);

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String selectedOrigin = 'New Delhi';
  String selectedDestination = 'Mumbai';
  DateTime? selectedDate;
  final List<String> stations = [
    'New Delhi', 'Mumbai', 'Kolkata', 'Chennai', 'Bangalore', 'Hyderabad', 'Ahmedabad', 'Pune'
  ];
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    // Try user_profile (JSON) first, then signup_username, then username
    String? name;
    final userProfileStr = prefs.getString('user_profile');
    if (userProfileStr != null) {
      try {
        final userProfile = jsonDecode(userProfileStr);
        name = userProfile['OtherAttributes']?['FullName'] ?? userProfile['fullName'] ?? userProfile['name'] ?? userProfile['username'];
      } catch (_) {}
    }
    name = name ?? prefs.getString('flutter.signup_username') ?? prefs.getString('signup_username') ?? prefs.getString('username') ?? 'User';
    setState(() {
      username = name;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Button style matching previous screens
    final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: const Color(0xFF7C3AED),
      textStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16),
      minimumSize: const Size.fromHeight(52),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient header with greeting, comes down further
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 400, // Increased height for deeper gradient
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 56, left: 24, right: 24, bottom: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_getGreeting()}, $username!',
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '',
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 120, // Place card below greeting, but not too far down
                  child: Card(
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tabs
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('One-Way', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF7C3AED))),
                                    Container(height: 3, width: 56, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: Color(0xFF7C3AED), borderRadius: BorderRadius.circular(2))),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text('Round Trip', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black26)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          // Origin Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedOrigin,
                            decoration: InputDecoration(
                              labelText: 'Origin',
                              labelStyle: TextStyle(fontFamily: 'Lato'),
                              filled: true,
                              fillColor: Color(0xFFF7F7FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            icon: const Icon(Icons.expand_more, color: Color(0xFF7C3AED)),
                            style: const TextStyle(fontFamily: 'Lato', fontSize: 15, color: Colors.black87),
                            items: stations.map((station) => DropdownMenuItem(value: station, child: Text(station, style: TextStyle(fontFamily: 'Lato')))).toList(),
                            onChanged: (value) => setState(() => selectedOrigin = value!),
                          ),
                          const SizedBox(height: 18),
                          // Destination Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedDestination,
                            decoration: InputDecoration(
                              labelText: 'Destination',
                              labelStyle: TextStyle(fontFamily: 'Lato'),
                              filled: true,
                              fillColor: Color(0xFFF7F7FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            icon: const Icon(Icons.expand_more, color: Color(0xFF7C3AED)),
                            style: const TextStyle(fontFamily: 'Lato', fontSize: 15, color: Colors.black87),
                            items: stations.map((station) => DropdownMenuItem(value: station, child: Text(station, style: TextStyle(fontFamily: 'Lato')))).toList(),
                            onChanged: (value) => setState(() => selectedDestination = value!),
                          ),
                          const SizedBox(height: 18),
                          // Date Picker
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => selectedDate = picked);
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Departure Date',
                                  labelStyle: TextStyle(fontFamily: 'Lato'),
                                  filled: true,
                                  fillColor: Color(0xFFF7F7FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  suffixIcon: Icon(Icons.calendar_today_outlined, color: Color(0xFF7C3AED)),
                                ),
                                controller: TextEditingController(
                                  text: selectedDate == null ? '' : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                ),
                                style: const TextStyle(fontFamily: 'Lato', fontSize: 15, color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Train Class
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Train Class',
                              labelStyle: TextStyle(fontFamily: 'Lato'),
                              filled: true,
                              fillColor: Color(0xFFF7F7FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            style: const TextStyle(fontFamily: 'Lato', fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 18),
                          // Passenger
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Passengers',
                              labelStyle: TextStyle(fontFamily: 'Lato'),
                              filled: true,
                              fillColor: Color(0xFFF7F7FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            style: const TextStyle(fontFamily: 'Lato', fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: primaryButtonStyle,
                              child: const Text('Search Trains', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 240),
            const SizedBox(height: 32),
            // Quick Actions Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quick Actions', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                      const SizedBox(height: 18),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 12,
                        children: const [
                          _QuickAction(icon: Icons.event_available, label: 'Check Booking'),
                          _QuickAction(icon: Icons.repeat, label: 'Re-Schedule'),
                          _QuickAction(icon: Icons.cancel, label: 'Cancellation'),
                          _QuickAction(icon: Icons.fastfood, label: 'Order Food'),
                          _QuickAction(icon: Icons.currency_rupee, label: 'Fare'),
                          _QuickAction(icon: Icons.info_outline, label: 'Live Status'),
                          _QuickAction(icon: Icons.alarm, label: 'Station Alarm'),
                          _QuickAction(icon: Icons.calculate, label: 'Refund'),
                          _QuickAction(icon: Icons.info, label: 'Line Info'),
                          _QuickAction(icon: Icons.local_shipping, label: 'Shipping'),
                          _QuickAction(icon: Icons.train, label: 'Connection'),
                          _QuickAction(icon: Icons.wallet, label: 'Wallet'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7FA),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Color(0xFF7C3AED), size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Lato', fontSize: 11, color: Colors.black),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
