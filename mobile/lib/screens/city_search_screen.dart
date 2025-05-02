import 'package:flutter/material.dart';
import 'package:train_booking_app/api_constants.dart';
import 'package:dio/dio.dart';

class CitySearchScreen extends StatefulWidget {
  final bool isOrigin;
  final Function(Map<String, dynamic>) onCitySelected;
  const CitySearchScreen({Key? key, required this.isOrigin, required this.onCitySelected}) : super(key: key);

  @override
  _CitySearchScreenState createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _filteredCities = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    try {
      final dio = Dio();
      final response = await dio.get("${ApiConstants.baseUrl}/api/v1/cities");
      setState(() {
        _cities = (response.data as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
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
        final code = city['station_code']?.toString()?.toLowerCase() ?? '';
        final name = city['station_name']?.toString()?.toLowerCase() ?? '';
        final cityName = city['city']?.toString()?.toLowerCase() ?? '';
        return code.contains(query.toLowerCase()) || name.contains(query.toLowerCase()) || cityName.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Purple gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isOrigin ? 'Select Origin' : 'Select Destination',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: _filterCities,
              decoration: InputDecoration(
                hintText: 'Search by city, code or name',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              style: const TextStyle(fontFamily: 'Lato', fontSize: 16),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_loading && _filteredCities.isEmpty)
            const Expanded(child: Center(child: Text('No cities found', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600)))),
          if (!_loading && _filteredCities.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCities.length,
                padding: const EdgeInsets.only(top: 8),
                itemBuilder: (context, index) {
                  final city = _filteredCities[index];
                  return ListTile(
                    title: Text(
                      '${city['station_name']} (${city['station_code']})',
                      style: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${city['city']}, ${city['state']}',
                      style: const TextStyle(fontFamily: 'Lato', color: Colors.black54),
                    ),
                    onTap: () {
                      Navigator.pop(context, city); // Pop and return city to previous screen
                    },
                    tileColor: Colors.transparent,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
