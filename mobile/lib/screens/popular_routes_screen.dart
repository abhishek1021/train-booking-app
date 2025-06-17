import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api_constants.dart';
import 'train_search_results_screen.dart';

class PopularRoutesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> popularRoutes;

  const PopularRoutesScreen({
    Key? key,
    required this.popularRoutes,
  }) : super(key: key);

  @override
  State<PopularRoutesScreen> createState() => _PopularRoutesScreenState();
}

class _PopularRoutesScreenState extends State<PopularRoutesScreen> {
  // Map to track loading state for each route card
  Map<int, bool> isLoading = {};

  @override
  void initState() {
    super.initState();
    // Initialize all routes as not loading
    for (int i = 0; i < widget.popularRoutes.length; i++) {
      isLoading[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Popular Routes',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9F7FF), Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.popularRoutes.length,
          itemBuilder: (context, index) {
            final route = widget.popularRoutes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRouteCard(context, route, index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, Map<String, dynamic> route, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route image with gradient overlay
          Stack(
            children: [
              // Image or gradient background
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: route['image'] != null
                    ? Image.network(
                        route['image'] as String,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildGradientBackground(index);
                        },
                      )
                    : _buildGradientBackground(index),
              ),
              // Gradient overlay for better text visibility
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Route codes
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        route['fromCode'] as String,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.train,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Text(
                        route['toCode'] as String,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Route details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${route['from']} - ${route['to']}',
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        route['duration'] as String,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_railway,
                      size: 18,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${route['trains']} Trains Available',
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading[index] == true ? null : () => _performSearch(context, route, index),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor:
                          MaterialStateProperty.all(Colors.transparent),
                      overlayColor: MaterialStateProperty.resolveWith((states) =>
                          states.contains(MaterialState.pressed)
                              ? Colors.purple.withOpacity(0.08)
                              : null),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: isLoading[index] == true
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text(
                                'Select This Route',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to perform search operation
  Future<void> _performSearch(BuildContext context, Map<String, dynamic> route, int index) async {
    final String origin = route['fromCode'];
    final String destination = route['toCode'];
    final String originName = route['from'];
    final String destinationName = route['to'];
    
    // Use current date
    final DateTime selectedDate = DateTime.now();
    final String date = '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    
    // Set loading state to true
    setState(() {
      isLoading[index] = true;
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
      
      final List<dynamic> trains = response.data;
      
      // Reset loading state
      setState(() {
        isLoading[index] = false;
      });
      
      // Navigate to search results screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrainSearchResultsScreen(
            trains: trains,
            origin: origin,
            destination: destination,
            originName: originName,
            destinationName: destinationName,
            date: _formatDate(selectedDate),
            passengers: 1, // Default to 1 passenger
            selectedClass: '', // Default to empty class
          ),
        ),
      );
    } catch (e) {
      // Reset loading state
      setState(() {
        isLoading[index] = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch trains: $e')),
      );
    }
  }
  
  // Helper method to format date
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString().padLeft(4, '0')}';
  }
  
  // Helper method to build gradient background
  Widget _buildGradientBackground(int index) {
    // Create different gradient colors based on the index
    List<List<Color>> gradients = [
      [const Color(0xFF5D50FE), const Color(0xFF9F7AEA)],
      [const Color(0xFF009688), const Color(0xFF4DB6AC)],
      [const Color(0xFFE91E63), const Color(0xFFF48FB1)],
      [const Color(0xFF2196F3), const Color(0xFF90CAF9)],
      [const Color(0xFFFF9800), const Color(0xFFFFCC80)],
    ];
    
    // Use modulo to cycle through gradients if there are more routes than gradients
    final colorIndex = index % gradients.length;
    
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients[colorIndex],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
