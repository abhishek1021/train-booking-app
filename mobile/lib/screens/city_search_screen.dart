import 'package:flutter/material.dart';
import 'package:train_booking_app/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:marquee/marquee.dart';

class CitySearchScreen extends StatefulWidget {
  final bool isOrigin;
  final Function(Map<String, dynamic>) onCitySelected;
  const CitySearchScreen(
      {Key? key, required this.isOrigin, required this.onCitySelected})
      : super(key: key);

  @override
  _CitySearchScreenState createState() => _CitySearchScreenState();
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
      final response = await dio.get("${ApiConstants.baseUrl}/api/v1/cities");
      setState(() {
        _cities = (response.data as List)
            .map((item) => {
                  'city_id': item['city_id'] ?? item['id'],
                  'station_code':
                      item['keyword'] ?? item['station_code'] ?? item['code'],
                  'station_name':
                      item['name'] ?? item['station_name'] ?? item['city'],
                  'state': item['state'] ?? '',
                  'id': item['id'] ?? item['city_id'],
                })
            .toList();
        _cities.sort((a, b) => (a['station_name'] ?? '').toString().toLowerCase().compareTo((b['station_name'] ?? '').toString().toLowerCase()));
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
        return code.contains(query.toLowerCase()) ||
            name.contains(query.toLowerCase()) ||
            cityName.contains(query.toLowerCase());
      }).toList();
    });
  }

  Widget _stationTextMarquee(String text, {TextAlign align = TextAlign.left}) {
    if (text.length > 20) {
      return SizedBox(
        width: 120,
        height: 22,
        child: Marquee(
          text: text,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
          scrollAxis: Axis.horizontal,
          blankSpace: 30.0,
          velocity: 25.0,
          pauseAfterRound: const Duration(milliseconds: 800),
          startAfter: const Duration(milliseconds: 800),
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
        style: const TextStyle(
          fontFamily: 'ProductSans',
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
      );
    }
  }

  Widget _buildCityTile(Map city) {
    final Map<String, dynamic> cityMap = Map<String, dynamic>.from(city);
    final cityName =
        cityMap['station_name'] ?? cityMap['name'] ?? cityMap['city'] ?? '';
    final code =
        cityMap['station_code'] ?? cityMap['keyword'] ?? cityMap['code'] ?? '';
    final state = cityMap['state'] ?? '';
    return InkWell(
      onTap: () => widget.onCitySelected(cityMap),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _stationTextMarquee(cityName),
                if (code.isNotEmpty) ...[
                  SizedBox(width: 10),
                  Text(
                    '($code)',
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ]
              ],
            ),
            if (state.isNotEmpty) ...[
              SizedBox(height: 6),
              Text(
                state,
                style: const TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ]
          ],
        ),
      ),
    );
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
                        fontFamily: 'ProductSans',
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
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _filterCities,
              decoration: InputDecoration(
                hintText: 'Search by city, code or name',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              style: const TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 16,
                  color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_loading && _filteredCities.isEmpty)
            const Expanded(
                child: Center(
                    child: Text('No cities found',
                        style: TextStyle(
                            fontFamily: 'ProductSans', fontWeight: FontWeight.w600)))),
          if (!_loading && _filteredCities.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCities.length,
                padding: const EdgeInsets.only(top: 8),
                itemBuilder: (context, index) {
                  final city = _filteredCities[index];
                  return _buildCityTile(city);
                },
              ),
            ),
        ],
      ),
    );
  }
}
