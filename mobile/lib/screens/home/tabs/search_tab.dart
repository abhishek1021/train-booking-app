import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../screens/pnr_search_screen.dart';
import '../../../screens/history_screen.dart';
import '../../../screens/offers_screen.dart';
import '../../../screens/support_screen.dart';
import '../../../screens/info_screen.dart';
import '../../../screens/language_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:train_booking_app/api_constants.dart';
import 'package:train_booking_app/screens/city_search_screen.dart';
import 'package:train_booking_app/screens/train_search_results_screen.dart';
import 'package:train_booking_app/screens/tatkal_mode_screen.dart';
import 'package:train_booking_app/screens/tatkal_jobs_screen.dart';
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
  String userId = ''; // Will be loaded from SharedPreferences
  int _selectedTabIndex = 0; // 0: One-Way, 1: Round Trip
  final GlobalKey _searchCardKey = GlobalKey();
  double _searchCardHeight = 0;
  int passengers = 1;

  String? selectedClass;
  bool _isSearching = false; // Track when a search is in progress

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
      if (!mounted) return;
      setState(() {
        cities = response.data;
      });
    } catch (e) {
      if (!mounted) return;
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
    _loadUserId();
    _fetchCities();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateSearchCardHeight());
  }

  // Load user ID from SharedPreferences
  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String loadedUserId = '';

      // Try to get user ID from user profile
      final userProfileStr = prefs.getString('user_profile');
      if (userProfileStr != null) {
        try {
          final userProfile = jsonDecode(userProfileStr);
          loadedUserId = userProfile['UserID'] ??
              userProfile['userId'] ??
              userProfile['user_id'] ??
              userProfile['id'] ??
              '';
        } catch (e) {
          print('Error parsing user profile: $e');
        }
      }

      // If not found in profile, try other keys
      loadedUserId = loadedUserId.isNotEmpty
          ? loadedUserId
          : prefs.getString('UserID') ??
              prefs.getString('userId') ??
              prefs.getString('user_id') ??
              '';

      if (mounted) {
        setState(() {
          userId = loadedUserId;
        });
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
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
              onNotificationTap: () {
                Navigator.of(context).pushNamed('/notifications');
              },
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
                  onSwapLocations: () {
                    // Swap the underlying state variables
                    final tempOrigin = selectedOrigin;
                    final tempOriginName = selectedOriginName;

                    setState(() {
                      selectedOrigin = selectedDestination;
                      selectedOriginName = selectedDestinationName;

                      selectedDestination = tempOrigin;
                      selectedDestinationName = tempOriginName;
                    });
                  },
                  onOriginTap: () async {
                    final selectedCity = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CitySearchScreen(
                          isOrigin: true,
                          searchType: 'station',
                          sourceScreen: 'search_tab',
                        ),
                      ),
                    );
                    if (selectedCity != null) {
                      // Check if the result is intended for this screen
                      if (selectedCity['sourceScreen'] == 'search_tab' ||
                          selectedCity['sourceScreen'] == 'default') {
                        setState(() {
                          selectedOrigin = selectedCity['station_code'] ??
                              selectedCity['code'] ??
                              '';
                          selectedOriginName = selectedCity['station_name'] ??
                              selectedCity['name'] ??
                              '';
                          originController.text =
                              selectedCity['station_name'] ??
                                  selectedCity['name'] ??
                                  '';
                        });
                      }
                    }
                  },
                  onDestinationTap: () async {
                    final selectedCity = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CitySearchScreen(
                          isOrigin: false,
                          searchType: 'station',
                          sourceScreen: 'search_tab',
                        ),
                      ),
                    );
                    if (selectedCity != null) {
                      // Check if the result is intended for this screen
                      if (selectedCity['sourceScreen'] == 'search_tab' ||
                          selectedCity['sourceScreen'] == 'default') {
                        setState(() {
                          selectedDestination = selectedCity['station_code'] ??
                              selectedCity['code'] ??
                              '';
                          selectedDestinationName =
                              selectedCity['station_name'] ??
                                  selectedCity['name'] ??
                                  '';
                          destinationController.text =
                              selectedCity['station_name'] ??
                                  selectedCity['name'] ??
                                  '';
                        });
                      }
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
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            dialogBackgroundColor: Colors.white,
                            colorScheme: ColorScheme.light(
                              primary:
                                  Color(0xFF7C3AED), // Purple for selected day
                              onPrimary:
                                  Colors.white, // Text color on selected day
                              onSurface: Colors
                                  .black, // Text color for unselected days
                              surface: Colors.white, // Background color
                            ),
                            textTheme: Theme.of(context).textTheme.copyWith(
                                  bodyLarge: TextStyle(
                                      color: Colors.black), // Calendar text
                                  bodyMedium: TextStyle(
                                      color: Colors.black), // Month/year text
                                ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Color(0xFF7C3AED), // Button text color
                              ),
                            ),
                            dialogTheme: DialogTheme(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
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
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            dialogBackgroundColor: Colors.white,
                            colorScheme: ColorScheme.light(
                              primary:
                                  Color(0xFF7C3AED), // Purple for selected day
                              onPrimary:
                                  Colors.white, // Text color on selected day
                              onSurface: Colors
                                  .black, // Text color for unselected days
                              surface: Colors.white, // Background color
                            ),
                            textTheme: Theme.of(context).textTheme.copyWith(
                                  bodyLarge: TextStyle(
                                      color: Colors.black), // Calendar text
                                  bodyMedium: TextStyle(
                                      color: Colors.black), // Month/year text
                                ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Color(0xFF7C3AED), // Button text color
                              ),
                            ),
                            dialogTheme: DialogTheme(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        returnDate = picked;
                      });
                    }
                  },
                  departureDateText: formatDate(selectedDate),
                  returnDateText: formatDate(returnDate),
                  isLoading: _isSearching,
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

                    // Set loading state to true before API call
                    setState(() {
                      _isSearching = true;
                    });

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

                      // Set loading state to false after API call
                      setState(() {
                        _isSearching = false;
                      });

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
                      // Reset loading state on error
                      setState(() {
                        _isSearching = false;
                      });

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
                        fontFamily: 'ProductSans',
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
                              labelColor: Color(0xFF7C3AED),
                              onTap: () async {
                                // Show loading indicator
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF7C3AED)),
                                      ),
                                    );
                                  },
                                );

                                try {
                                  // Use the already loaded userId from state
                                  String historyUserId = userId;

                                  // If userId is empty, try to load it directly
                                  if (historyUserId.isEmpty) {
                                    final prefs =
                                        await SharedPreferences.getInstance();

                                    // Try to get user ID from user profile
                                    final userProfileStr =
                                        prefs.getString('user_profile');
                                    if (userProfileStr != null) {
                                      try {
                                        final userProfile =
                                            jsonDecode(userProfileStr);
                                        historyUserId = userProfile['UserID'] ??
                                            userProfile['userId'] ??
                                            userProfile['user_id'] ??
                                            userProfile['id'] ??
                                            '';
                                      } catch (e) {
                                        print('Error parsing user profile: $e');
                                      }
                                    }

                                    // If not found in profile, try other keys
                                    historyUserId = historyUserId.isNotEmpty
                                        ? historyUserId
                                        : prefs.getString('UserID') ??
                                            prefs.getString('userId') ??
                                            prefs.getString('user_id') ??
                                            ''; // No default fallback
                                  }

                                  // Close loading dialog
                                  Navigator.pop(context);

                                  // Navigate to history screen with the fetched user ID
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HistoryScreen(userId: historyUserId),
                                    ),
                                  );
                                } catch (e) {
                                  // Close loading dialog
                                  Navigator.pop(context);

                                  // Show error message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'User ID not found. Please log in again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }),
                          QuickAction(
                              icon: Icons.favorite,
                              label: 'Favorites',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED)),
                          QuickAction(
                              icon: Icons.search,
                              label: 'Search PNR',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PnrSearchScreen(),
                                  ),
                                );
                              }),
                          QuickAction(
                              icon: Icons.local_offer,
                              label: 'Offers',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const OffersScreen(),
                                  ),
                                );
                              }),
                          QuickAction(
                              icon: Icons.support_agent,
                              label: 'Support',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SupportScreen(),
                                  ),
                                );
                              }),
                          QuickAction(
                              icon: Icons.language,
                              label: 'Language',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LanguageScreen(),
                                  ),
                                );
                              }),
                          QuickAction(
                              icon: Icons.info_outline,
                              label: 'Info',
                              iconColor: Color(0xFF7C3AED),
                              labelColor: Color(0xFF7C3AED),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const InfoScreen(),
                                  ),
                                );
                              }),
                        ],
                      ),
                    ),
                  ),

                  // Tatkal Mode Banner
                  const SizedBox(height: 24),
                  _buildTatkalModeBanner(context),

                  // Popular Routes Section
                  const SizedBox(height: 24),
                  _buildSectionHeader('Popular Routes'),
                  const SizedBox(height: 12),
                  _buildPopularRoutesSection(),

                  // Featured Trains Section
                  const SizedBox(height: 24),
                  _buildSectionHeader('Featured Trains'),
                  const SizedBox(height: 12),
                  _buildFeaturedTrainsSection(),

                  // Travel Tips Section
                  const SizedBox(height: 24),
                  _buildSectionHeader('Travel Tips'),
                  const SizedBox(height: 12),
                  _buildTravelTipsSection(),

                  // Upcoming Festivals Section
                  const SizedBox(height: 24),
                  _buildSectionHeader('Upcoming Festivals'),
                  const SizedBox(height: 12),
                  _buildFestivalsSection(),

                  // Footer Section
                  const SizedBox(height: 40),
                  _buildFooterSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tatkal Mode Banner
  Widget _buildTatkalModeBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TatkalJobsScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background design elements
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Left side with icon and text
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.flash_on,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Tatkal Mode',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ProductSans',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Automate your Tatkal booking process for faster ticket booking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'ProductSans',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right side with button
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Try Now',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'ProductSans',
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
        ),
      ),
    );
  }

  // Section Header Widget
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF7C3AED),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'See All',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Popular Routes Section
  Widget _buildPopularRoutesSection() {
    final List<Map<String, dynamic>> popularRoutes = [
      {
        'from': 'Delhi',
        'to': 'Mumbai',
        'fromCode': 'NDLS',
        'toCode': 'CSTM',
        'trains': 42,
        'duration': '16h 35m',
        'image': 'assets/images/delhi_mumbai.jpg',
      },
      {
        'from': 'Bangalore',
        'to': 'Chennai',
        'fromCode': 'SBC',
        'toCode': 'MAS',
        'trains': 23,
        'duration': '5h 15m',
        'image': 'assets/images/bangalore_chennai.jpg',
      },
      {
        'from': 'Kolkata',
        'to': 'Delhi',
        'fromCode': 'KOAA',
        'toCode': 'NDLS',
        'trains': 35,
        'duration': '17h 20m',
        'image': 'assets/images/kolkata_delhi.jpg',
      },
      {
        'from': 'Mumbai',
        'to': 'Goa',
        'fromCode': 'CSTM',
        'toCode': 'MAO',
        'trains': 18,
        'duration': '8h 40m',
        'image': 'assets/images/mumbai_goa.jpg',
      },
      {
        'from': 'Hyderabad',
        'to': 'Bangalore',
        'fromCode': 'HYD',
        'toCode': 'SBC',
        'trains': 15,
        'duration': '10h 30m',
        'image': 'assets/images/hyderabad_bangalore.jpg',
      },
    ];

    return SizedBox(
      height: 175,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: popularRoutes.length,
        itemBuilder: (context, index) {
          final route = popularRoutes[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                // Pre-fill search with this route
                setState(() {
                  selectedOrigin = route['fromCode'];
                  selectedDestination = route['toCode'];
                  selectedOriginName = route['from'];
                  selectedDestinationName = route['to'];
                  originController.text = route['from'];
                  destinationController.text = route['to'];
                });

                // Scroll back to top to show the search form
                // This would require a ScrollController
              },
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route image or gradient
                    Container(
                      height: 75,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.train,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    // Route details
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${route['from']} - ${route['to']}',
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF7C3AED),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${route['trains']} Trains • ${route['duration']}',
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Book Now',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Featured Trains Section
  Widget _buildFeaturedTrainsSection() {
    final List<Map<String, dynamic>> featuredTrains = [
      {
        'name': 'Rajdhani Express',
        'number': '12301',
        'from': 'NDLS',
        'to': 'HWH',
        'departure': '16:55',
        'arrival': '10:10',
        'duration': '17h 15m',
        'rating': 4.7,
      },
      {
        'name': 'Shatabdi Express',
        'number': '12002',
        'from': 'NDLS',
        'to': 'LKO',
        'departure': '06:15',
        'arrival': '12:40',
        'duration': '6h 25m',
        'rating': 4.5,
      },
      {
        'name': 'Duronto Express',
        'number': '12213',
        'from': 'CSTM',
        'to': 'NDLS',
        'departure': '11:05',
        'arrival': '04:00',
        'duration': '16h 55m',
        'rating': 4.3,
      },
      {
        'name': 'Vande Bharat',
        'number': '22435',
        'from': 'NDLS',
        'to': 'BKN',
        'departure': '06:00',
        'arrival': '13:45',
        'duration': '7h 45m',
        'rating': 4.8,
      },
      {
        'name': 'Tejas Express',
        'number': '22119',
        'from': 'CSTM',
        'to': 'MAO',
        'departure': '05:50',
        'arrival': '16:00',
        'duration': '10h 10m',
        'rating': 4.6,
      },
    ];

    return SizedBox(
      height: 175,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: featuredTrains.length,
        itemBuilder: (context, index) {
          final train = featuredTrains[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRect(
              child: Container(
                width: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Train header with gradient
                    Container(
                      height: 65,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  train['name'],
                                  style: const TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  train['number'],
                                  style: const TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${train['rating']}',
                                style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Train details
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 50,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // From station
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        train['from'],
                                        style: const TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF7C3AED),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        train['departure'],
                                        style: const TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Duration
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Color(0xFF7C3AED),
                                        size: 16,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        train['duration'],
                                        style: const TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                // To station
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        train['to'],
                                        style: const TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF7C3AED),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        train['arrival'],
                                        style: const TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Travel Tips Section
  Widget _buildTravelTipsSection() {
    final List<Map<String, dynamic>> travelTips = [
      {
        'title': 'Book in Advance',
        'description':
            'Book tickets at least 60 days in advance for best availability and prices.',
        'icon': Icons.calendar_today,
      },
      {
        'title': 'Tatkal Booking',
        'description':
            'Tatkal booking opens at 10:00 AM for AC classes and 11:00 AM for non-AC classes.',
        'icon': Icons.flash_on,
      },
      {
        'title': 'Senior Citizen',
        'description': 'Senior citizens get 40-50% concession on ticket fares.',
        'icon': Icons.person,
      },
      {
        'title': 'ID Proof',
        'description':
            'Always carry original ID proof matching the name on your ticket.',
        'icon': Icons.badge,
      },
      {
        'title': 'Food Options',
        'description':
            'Pre-order meals through IRCTC e-catering for better quality food.',
        'icon': Icons.restaurant,
      },
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: travelTips.length,
        itemBuilder: (context, index) {
          final tip = travelTips[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            tip['icon'],
                            color: const Color(0xFF7C3AED),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip['title'],
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF7C3AED),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        tip['description'],
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Festivals Section
  Widget _buildFestivalsSection() {
    final List<Map<String, dynamic>> festivals = [
      {
        'name': 'Diwali',
        'date': 'Nov 12, 2025',
        'description': 'Book your tickets early for the festival of lights.',
        'color': const Color(0xFFFFA000),
      },
      {
        'name': 'Durga Puja',
        'date': 'Oct 2, 2025',
        'description':
            'Special trains available for Kolkata during this period.',
        'color': const Color(0xFFE91E63),
      },
      {
        'name': 'Christmas',
        'date': 'Dec 25, 2025',
        'description': 'Holiday special trains to Goa and Kerala.',
        'color': const Color(0xFF4CAF50),
      },
      {
        'name': 'Holi',
        'date': 'Mar 14, 2026',
        'description': 'Plan your colorful celebration with special packages.',
        'color': const Color(0xFF2196F3),
      },
      {
        'name': 'Onam',
        'date': 'Sep 6, 2025',
        'description': 'Kerala bound trains get fully booked weeks in advance.',
        'color': const Color(0xFFFF5722),
      },
    ];

    return SizedBox(
      height: 130,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: festivals.length,
        itemBuilder: (context, index) {
          final festival = festivals[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Festival header
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: festival['color'],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          festival['name'],
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const Icon(
                          Icons.celebration,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  // Festival details
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          festival['date'],
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          festival['description'],
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Footer Section
  Widget _buildFooterSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[300]!,
            Colors.grey[200]!,
            Colors.grey[100]!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Made with love in India',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterLink('Terms & Conditions'),
              _buildFooterDot(),
              _buildFooterLink('Privacy Policy'),
              _buildFooterDot(),
              _buildFooterLink('Help'),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '© 2025 Train Booking App. All rights reserved.',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 12,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.facebook),
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.telegram),
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.chat),
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.email),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'ProductSans',
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFooterDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '•',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: const Color(0xFF7C3AED),
        size: 18,
      ),
    );
  }
}
