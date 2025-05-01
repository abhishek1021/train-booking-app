import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:train_booking_app/api_constants.dart';
import 'package:train_booking_app/screens/city_search_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({Key? key}) : super(key: key);

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String selectedOrigin = '';
  String selectedDestination = '';
  String? selectedOriginName;
  String? selectedDestinationName;
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  DateTime? selectedDate;
  DateTime? returnDate;
  List<Map<String, dynamic>> cities = [];
  String? username;
  int _selectedTabIndex = 0; // 0: One-Way, 1: Round Trip
  final GlobalKey _searchCardKey = GlobalKey();
  double _searchCardHeight = 0;

  final String citiesEndpoint = "${ApiConstants.baseUrl}/api/v1/cities";

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchCities();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSearchCardHeight());
  }

  @override
  void dispose() {
    originController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCities() async {
    try {
      final dio = Dio();
      final response = await dio.get(citiesEndpoint); 
      setState(() {
        cities = response.data;
      });
    } catch (e) {
      // Handle error, maybe show a snackbar
      setState(() {
        cities = [];
      });
    }
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
      return 'Good morning! ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon 🌤️';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening 🌆';
    } else {
      return 'Good night 🌙';
    }
  }

  String _toCamelCase(String? input) {
    if (input == null || input.trim().isEmpty) return '';
    final words = input.trim().split(RegExp(r'[_\s]+'));
    return words.map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  void _updateSearchCardHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _searchCardKey.currentContext;
      if (context != null) {
        final newHeight = context.size?.height ?? 0;
        if ((_searchCardHeight - newHeight).abs() > 2) {
          setState(() {
            _searchCardHeight = newHeight;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print("SearchTab build");
    // Button style matching previous screens
    final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: const Color(0xFF7C3AED),
      textStyle: const TextStyle(
        inherit: true,
        fontFamily: 'Lato',
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      minimumSize: const Size.fromHeight(52),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stack for gradient header and floating search card
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient header wrapped in IgnorePointer
                IgnorePointer(
                  child: Container(
                    width: double.infinity,
                    height: 230,
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontFamilyFallback: ['NotoColorEmoji'],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.4),
                                    color: Colors.white.withOpacity(0.10),
                                  ),
                                  child: Icon(Icons.notifications_none_outlined, color: Colors.white, size: 24),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_toCamelCase(username), style: TextStyle(fontFamily: 'Lato', fontFamilyFallback: ['NotoColorEmoji'], fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white.withOpacity(0.95))),
                        ],
                      ),
                    ),
                  ),
                ),
                // Floating Search Card
                Positioned(
                  left: 0,
                  right: 0,
                  top: 170, // Overlap the bottom of the gradient
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Card(
                        key: _searchCardKey,
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
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedTabIndex = 0;
                                        });
                                        _updateSearchCardHeight();
                                      },
                                      child: Column(
                                        children: [
                                          Text('One-Way',
                                            style: TextStyle(
                                              inherit: true,
                                              fontFamily: 'Lato',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: _selectedTabIndex == 0 ? Color(0xFF7C3AED) : Colors.black26,
                                            )),
                                          AnimatedContainer(
                                            duration: Duration(milliseconds: 200),
                                            height: 3, width: 56, margin: const EdgeInsets.only(top: 6),
                                            decoration: BoxDecoration(
                                              color: _selectedTabIndex == 0 ? Color(0xFF7C3AED) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(2)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedTabIndex = 1;
                                        });
                                        _updateSearchCardHeight();
                                      },
                                      child: Column(
                                        children: [
                                          Text('Round Trip',
                                            style: TextStyle(
                                              inherit: true,
                                              fontFamily: 'Lato',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: _selectedTabIndex == 1 ? Color(0xFF7C3AED) : Colors.black26,
                                            )),
                                          AnimatedContainer(
                                            duration: Duration(milliseconds: 200),
                                            height: 3, width: 56, margin: const EdgeInsets.only(top: 6),
                                            decoration: BoxDecoration(
                                              color: _selectedTabIndex == 1 ? Color(0xFF7C3AED) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(2)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (_selectedTabIndex == 0)
                                // One-Way UI (existing search fields)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Add a temporary GestureDetector above the Origin TextFormField for tap debugging
                                    GestureDetector(
                                      onTap: () {
                                        print("Test GestureDetector tapped");
                                      },
                                      child: Container(
                                        height: 40,
                                        color: Colors.red.withOpacity(0.3),
                                        child: Center(child: Text('Test Tap Area')),
                                      ),
                                    ),
                                    // Origin
                                    TextFormField(
                                      readOnly: true,
                                      controller: originController,
                                      decoration: InputDecoration(
                                        labelText: 'Origin',
                                        labelStyle: TextStyle(fontFamily: 'Lato'),
                                        filled: true,
                                        fillColor: Color(0xFFF7F7FA),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                        suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                                      ),
                                      style: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16),
                                      onTap: () async {
                                        print("Tapped Origin TextField");
                                        final city = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CitySearchScreen(
                                              isOrigin: true,
                                              onCitySelected: (selectedCity) {
                                                Navigator.pop(context, selectedCity);
                                              },
                                            ),
                                          ),
                                        );
                                        if (city != null) {
                                          setState(() {
                                            selectedOrigin = city['station_code'];
                                            selectedOriginName = city['station_name'];
                                            originController.text = '${selectedOriginName ?? ''} (${selectedOrigin})';
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    // Destination
                                    TextFormField(
                                      readOnly: true,
                                      controller: destinationController,
                                      decoration: InputDecoration(
                                        labelText: 'Destination',
                                        labelStyle: TextStyle(fontFamily: 'Lato'),
                                        filled: true,
                                        fillColor: Color(0xFFF7F7FA),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                        suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                                      ),
                                      style: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16),
                                      onTap: () async {
                                        print("Tapped Destination TextField");
                                        final city = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CitySearchScreen(
                                              isOrigin: false,
                                              onCitySelected: (selectedCity) {
                                                Navigator.pop(context, selectedCity);
                                              },
                                            ),
                                          ),
                                        );
                                        if (city != null) {
                                          setState(() {
                                            selectedDestination = city['station_code'];
                                            selectedDestinationName = city['station_name'];
                                            destinationController.text = '${selectedDestinationName ?? ''} (${selectedDestination})';
                                          });
                                        }
                                      },
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
                                        if (picked != null) {
                                          setState(() => selectedDate = picked);
                                          _updateSearchCardHeight();
                                        }
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
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          minimumSize: const Size.fromHeight(52),
                                          elevation: 0,
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                        ).merge(
                                          ButtonStyle(
                                            overlayColor: MaterialStateProperty.all(Colors.deepPurple.withOpacity(0.07)),
                                          ),
                                        ),
                                        child: Ink(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            constraints: const BoxConstraints(minHeight: 52),
                                            child: const Text(
                                              'Search Trains',
                                              style: TextStyle(
                                                fontFamily: 'Lato',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                // Round Trip UI
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Add a temporary GestureDetector above the Origin TextFormField for tap debugging
                                    GestureDetector(
                                      onTap: () {
                                        print("Test GestureDetector tapped");
                                      },
                                      child: Container(
                                        height: 40,
                                        color: Colors.red.withOpacity(0.3),
                                        child: Center(child: Text('Test Tap Area')),
                                      ),
                                    ),
                                    // Origin
                                    TextFormField(
                                      readOnly: true,
                                      controller: originController,
                                      decoration: InputDecoration(
                                        labelText: 'Origin',
                                        labelStyle: TextStyle(fontFamily: 'Lato'),
                                        filled: true,
                                        fillColor: Color(0xFFF7F7FA),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                        suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                                      ),
                                      style: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16),
                                      onTap: () async {
                                        print("Tapped Origin TextField");
                                        final city = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CitySearchScreen(
                                              isOrigin: true,
                                              onCitySelected: (selectedCity) {
                                                Navigator.pop(context, selectedCity);
                                              },
                                            ),
                                          ),
                                        );
                                        if (city != null) {
                                          setState(() {
                                            selectedOrigin = city['station_code'];
                                            selectedOriginName = city['station_name'];
                                            originController.text = '${selectedOriginName ?? ''} (${selectedOrigin})';
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    // Destination
                                    TextFormField(
                                      readOnly: true,
                                      controller: destinationController,
                                      decoration: InputDecoration(
                                        labelText: 'Destination',
                                        labelStyle: TextStyle(fontFamily: 'Lato'),
                                        filled: true,
                                        fillColor: Color(0xFFF7F7FA),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                        suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                                      ),
                                      style: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16),
                                      onTap: () async {
                                        print("Tapped Destination TextField");
                                        final city = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CitySearchScreen(
                                              isOrigin: false,
                                              onCitySelected: (selectedCity) {
                                                Navigator.pop(context, selectedCity);
                                              },
                                            ),
                                          ),
                                        );
                                        if (city != null) {
                                          setState(() {
                                            selectedDestination = city['station_code'];
                                            selectedDestinationName = city['station_name'];
                                            destinationController.text = '${selectedDestinationName ?? ''} (${selectedDestination})';
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    GestureDetector(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: selectedDate ?? DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (picked != null) {
                                          setState(() => selectedDate = picked);
                                          _updateSearchCardHeight();
                                        }
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
                                    GestureDetector(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: returnDate ?? selectedDate ?? DateTime.now(),
                                          firstDate: selectedDate ?? DateTime.now(),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (picked != null) {
                                          setState(() => returnDate = picked);
                                          _updateSearchCardHeight();
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            labelText: 'Return Date',
                                            labelStyle: TextStyle(fontFamily: 'Lato'),
                                            filled: true,
                                            fillColor: Color(0xFFF7F7FA),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                            suffixIcon: Icon(Icons.calendar_today_outlined, color: Color(0xFF7C3AED)),
                                          ),
                                          controller: TextEditingController(
                                            text: returnDate == null ? '' : '${returnDate!.day}/${returnDate!.month}/${returnDate!.year}',
                                          ),
                                          style: const TextStyle(fontFamily: 'Lato', fontSize: 15, color: Colors.black87),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
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
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          minimumSize: const Size.fromHeight(52),
                                          elevation: 0,
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                        ).merge(
                                          ButtonStyle(
                                            overlayColor: MaterialStateProperty.all(Colors.deepPurple.withOpacity(0.07)),
                                          ),
                                        ),
                                        child: Ink(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            constraints: const BoxConstraints(minHeight: 52),
                                            child: const Text(
                                              'Search Trains',
                                              style: TextStyle(
                                                fontFamily: 'Lato',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Dynamically sized gap below the floating search card
            SizedBox(height: (_searchCardHeight > 0 ? (_searchCardHeight - 40) : 120)),
            // Quick Actions Card (below the floating card, not in Stack)
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
