import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:train_booking_app/api_constants.dart';
import 'package:train_booking_app/screens/city_search_screen.dart';
import 'package:train_booking_app/screens/train_search_results_screen.dart';
import 'search_tab/search_header.dart';
import 'search_tab/search_card.dart';
import 'search_tab/quick_actions.dart';

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
  int passengers = 1;
  String? selectedClass;

  final String citiesEndpoint = "${ApiConstants.baseUrl}/api/v1/cities";

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '☀️';
    } else if (hour >= 12 && hour < 17) {
      return '🌤️';
    } else if (hour >= 17 && hour < 21) {
      return '🌆';
    } else {
      return '🌙';
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning! ';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon ';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening ';
    } else {
      return 'Good night ';
    }
  }

  String _toCamelCase(String? input) {
    if (input == null || input.trim().isEmpty) return '';
    final words = input.trim().split(RegExp(r'[_\s]+'));
    return words
        .map((w) =>
            w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
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

  Future<void> _fetchCities() async {
    try {
      final dio = Dio();
      final response = await dio.get(citiesEndpoint);
      setState(() {
        cities = response.data;
      });
    } catch (e) {
      setState(() {
        cities = [];
      });
    }
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    String? name;
    final userProfileStr = prefs.getString('user_profile');
    if (userProfileStr != null) {
      try {
        final userProfile = jsonDecode(userProfileStr);
        name = userProfile['OtherAttributes']?['FullName'] ??
            userProfile['fullName'] ??
            userProfile['name'] ??
            userProfile['username'];
      } catch (_) {}
    }
    name = name ??
        prefs.getString('flutter.signup_username') ??
        prefs.getString('signup_username') ??
        prefs.getString('username') ??
        'User';
    setState(() {
      username = name;
    });
  }

  // Helper to format date as dd/MM/yyyy
  String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchCities();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateSearchCardHeight());
  }

  @override
  void dispose() {
    originController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient header (now scrolls with content)
            SearchHeader(
              greeting: _getGreeting() + _getGreetingEmoji(),
              username: _toCamelCase(username),
              onNotificationTap: () {},
            ),
            // Overlapping search card
            Transform.translate(
              offset: Offset(0, -160),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchCard(
                  selectedTabIndex: _selectedTabIndex,
                  onTabChange: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  originController: originController,
                  destinationController: destinationController,
                  onOriginTap: () async {
                    final selectedCity = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CitySearchScreen(
                          isOrigin: true,
                          onCitySelected: (city) {
                            Navigator.pop(context, city);
                          },
                        ),
                      ),
                    );
                    if (selectedCity != null) {
                      setState(() {
                        selectedOrigin = selectedCity['station_code'] ?? '';
                        selectedOriginName = selectedCity['station_name'] ?? '';
                        originController.text =
                            selectedCity['station_name'] ?? '';
                      });
                    }
                  },
                  onDestinationTap: () async {
                    final selectedCity = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CitySearchScreen(
                          isOrigin: false,
                          onCitySelected: (city) {
                            Navigator.pop(context, city);
                          },
                        ),
                      ),
                    );
                    if (selectedCity != null) {
                      setState(() {
                        selectedDestination =
                            selectedCity['station_code'] ?? '';
                        selectedDestinationName =
                            selectedCity['station_name'] ?? '';
                        destinationController.text =
                            selectedCity['station_name'] ?? '';
                      });
                    }
                  },
                  passengers: passengers,
                  onPassengersChanged: (isAdd) {
                    setState(() {
                      if (isAdd) {
                        passengers++;
                      } else if (passengers > 1) {
                        passengers--;
                      }
                    });
                  },
                  onPassengersTap: () {}, // Optionally show a modal in future
                  onDepartureDateTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  onReturnDateTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          returnDate ?? (selectedDate ?? DateTime.now()),
                      firstDate: selectedDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        returnDate = picked;
                      });
                    }
                  },
                  departureDateText: formatDate(selectedDate),
                  returnDateText: formatDate(returnDate),
                  onSearch: () async {
                    // Compose API query parameters
                    final origin = selectedOrigin;
                    final destination = selectedDestination;
                    final date = selectedDate != null
                        ? '${selectedDate!.year.toString().padLeft(4, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                        : '';
                    if (origin.isEmpty || destination.isEmpty || date.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Please select origin, destination, and date.')),
                      );
                      return;
                    }
                    try {
                      final dio = Dio();
                      final response = await dio.get(
                        '${ApiConstants.baseUrl}/api/v1/trains/search'
                            .replaceAll(RegExp(r'\/$'), ''),
                        queryParameters: {
                          'origin': origin,
                          'destination': destination,
                          'date': date,
                        },
                      );
                      final List<dynamic> trains = response.data;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrainSearchResultsScreen(
                            trains: trains,
                            origin: origin, // always station code
                            destination: destination, // always station code
                            originName: selectedOriginName ?? '',
                            destinationName: selectedDestinationName ?? '',
                            date: formatDate(selectedDate),
                            passengers: passengers,
                            selectedClass: selectedClass ?? '',
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to fetch trains: $e')),
                      );
                    }
                  },
                  extraFields: (BuildContext context, String type) {
                    if (type == 'departure') {
                      return null; // The onTap is now handled in the TextFormField itself in SearchCard
                    } else if (type == 'return') {
                      return null;
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 30),
            Transform.translate(
              offset: Offset(0, -130), // Tighter gap
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Card(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          QuickAction(
                              icon: Icons.train,
                              label: 'Book Train',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.history,
                              label: 'History',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.favorite,
                              label: 'Favorites',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.search,
                              label: 'Search PNR',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.directions_bus,
                              label: 'Book Bus',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.hotel,
                              label: 'Book Hotel',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.airplanemode_active,
                              label: 'Book Flight',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.directions_car,
                              label: 'Cab',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.local_offer,
                              label: 'Offers',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.support_agent,
                              label: 'Support',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.language,
                              label: 'Language',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.info_outline,
                              label: 'Info',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
