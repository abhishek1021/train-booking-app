import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'package:dio/dio.dart';

class CitySearchScreen extends StatefulWidget {
  final String searchType; // 'city' or 'station'
  final bool isOrigin;
  final Function(Map<String, dynamic>)? onCitySelected;
  final String sourceScreen; // To identify which screen called this
  
  const CitySearchScreen({
    Key? key, 
    this.searchType = 'city',
    this.isOrigin = true, 
    this.onCitySelected,
    this.sourceScreen = 'default',
  }) : super(key: key);

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _filteredCities = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchCities();
    // Auto-focus the search box after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCities() async {
    try {
      final dio = Dio();
      final String endpoint = widget.searchType == 'station' 
          ? "${ApiConfig.baseUrl}${ApiConfig.stationEndpoint}"
          : "${ApiConfig.baseUrl}${ApiConfig.cityEndpoint}";
      
      final response = await dio.get(endpoint);
      setState(() {
        _cities = (response.data as List)
            .map((item) => {
                  'id': item['id'] ?? item['city_id'] ?? item['station_id'],
                  'code': item['code'] ?? item['station_code'] ?? item['keyword'],
                  'name': item['name'] ?? item['station_name'] ?? item['city'],
                  'state': item['state'] ?? '',
                })
            .toList();
        _cities.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
        _filteredCities = _cities;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _cities = [];
        _filteredCities = [];
        _loading = false;
      });
    }
  }

  void _filterCities(String query) {
    setState(() {
      _search = query;
      _filteredCities = _cities.where((city) {
        final code = city['code']?.toString().toLowerCase() ?? '';
        final name = city['name']?.toString().toLowerCase() ?? '';
        final state = city['state']?.toString().toLowerCase() ?? '';
        return code.contains(query.toLowerCase()) ||
            name.contains(query.toLowerCase()) ||
            state.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _onCityTap(Map<String, dynamic> city) {
    // Return a standardized format for both city and station
    final result = {
      'id': city['id'],
      'code': city['code'],
      'name': city['name'],
      'state': city['state'],
      'sourceScreen': widget.sourceScreen, // Add source screen to identify where to return
    };
    
    if (widget.onCitySelected != null) {
      widget.onCitySelected!(result);
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 30.0), // Add 30px top margin to header
          child: Text(
            widget.searchType == 'station'
                ? (widget.isOrigin ? 'Select Origin Station' : 'Select Destination Station')
                : (widget.isOrigin ? 'Select Origin City' : 'Select Destination City'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24, // Increased font size
              fontFamily: 'ProductSans',
            ),
          ),
        ),
        toolbarHeight: 100, // Increased height to accommodate the top padding
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF7C3AED),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _filterCities,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'ProductSans',
                fontSize: 16, // Increased font size
              ),
              decoration: InputDecoration(
                hintText: 'Search by name or code',
                hintStyle: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'ProductSans',
                  fontSize: 16, // Increased font size
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white70,
                  size: 24, // Increased icon size
                ),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ),
          
          // Results list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                : _filteredCities.isEmpty
                    ? Center(
                        child: Text(
                          _search.isEmpty
                              ? 'No cities found'
                              : 'No results for "$_search"',
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 18, // Increased font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Changed to black
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredCities.length,
                        padding: const EdgeInsets.only(top: 8),
                        itemBuilder: (context, index) {
                          return _buildCityItem(_filteredCities[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityItem(Map<String, dynamic> city) {
    final name = city['name'] ?? '';
    final code = city['code'] ?? '';
    final state = city['state'] ?? '';
    
    return InkWell(
      onTap: () => _onCityTap(city),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // City name with larger font and black color
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Increased font size
                      color: Colors.black, // Explicitly set to black
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Code aligned to the right with fixed width
                Container(
                  width: 70, // Fixed width to align all codes
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center, // Center the text
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Increased font size
                    ),
                  ),
                ),
              ],
            ),
            if (state.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  state,
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.grey[600],
                    fontSize: 16, // Increased font size
                  ),
                ),
              ),
            const SizedBox(height: 12), // Increased spacing
            Divider(color: Colors.grey[300], thickness: 1.0), // Thicker divider
          ],
        ),
      ),
    );
  }
}