import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sort_filter_screen.dart';
import '../../api_constants.dart';

class TrainSearchResultsScreen extends StatefulWidget {
  final List<dynamic> trains;
  final String origin;
  final String destination;
  final String originName;
  final String destinationName;
  final String date;
  final int passengers;
  final String selectedClass;

  const TrainSearchResultsScreen({
    Key? key,
    required this.trains,
    required this.origin,
    required this.destination,
    required this.originName,
    required this.destinationName,
    required this.date,
    required this.passengers,
    required this.selectedClass,
  }) : super(key: key);

  @override
  State<TrainSearchResultsScreen> createState() =>
      _TrainSearchResultsScreenState();
}

class _TrainSearchResultsScreenState extends State<TrainSearchResultsScreen> {
  late DateTime selectedDate;
  late List<DateTime> dateOptions;
  late List<dynamic> trains;
  int? expandedCardIdx;
  Map<int, String?> selectedClassByCard = {};
  Map<int, Map<String, int>> seatCountsByCard = {};
  Map<int, Map<String, int>> backendSeatCountsByCard =
      {}; // {cardIdx: {class: seatCount}}
  Map<int, Map<String, int>> backendPricesByCard =
      {}; // {cardIdx: {class: price}}
  Map<int, GlobalKey<PriceBounceState>> priceKeys = {};
  ScrollController dateScrollController = ScrollController();
  Map<int, ScrollController> classScrollControllers = {};
  Map<int, bool> showLeftArrow = {};
  Map<int, bool> showRightArrow = {};

  @override
  void initState() {
    super.initState();
    selectedDate = _parseDate(widget.date);
    dateOptions =
        List.generate(11, (i) => selectedDate.subtract(Duration(days: 5 - i)));
    trains = widget.trains;
    for (int idx = 0; idx < trains.length; idx++) {
      final List<dynamic> classes = trains[idx]['classes_available'] ?? [];
      String? defaultClass = classes.contains('SL')
          ? 'SL'
          : (classes.isNotEmpty ? classes[0] : null);
      selectedClassByCard[idx] = defaultClass;
      // Set initial price to SL or first class
      if (defaultClass != null && trains[idx]['class_prices'] != null) {
        trains[idx]['price'] = trains[idx]['class_prices'][defaultClass] ?? 0;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedIdx = dateOptions.indexOf(selectedDate);
      if (selectedIdx != -1) {
        dateScrollController
            .jumpTo((selectedIdx - 2).clamp(0, dateOptions.length - 1) * 72.0);
      }
    });
  }

  Future<void> fetchTrainsForDate(DateTime date) async {
    final formattedDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    // Ensure we always use station code, not name
    String originCode = widget.origin;
    String destinationCode = widget.destination;
    // If the value contains both code and name (e.g. "BKSC - BOKARO STEEL CITY"), split and take the code
    if (originCode.contains(' - ')) originCode = originCode.split(' - ')[0];
    if (destinationCode.contains(' - '))
      destinationCode = destinationCode.split(' - ')[0];
    final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/v1/trains/search?origin=$originCode&destination=$destinationCode&date=$formattedDate');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> trainList = json.decode(response.body);
      setState(() {
        trains = trainList;
        selectedDate = date;
        expandedCardIdx = null;
        selectedClassByCard.clear();
        // Optionally re-initialize class selection for new trains
        for (int idx = 0; idx < trains.length; idx++) {
          final List<dynamic> classes = trains[idx]['classes_available'] ?? [];
          String? defaultClass = classes.contains('SL')
              ? 'SL'
              : (classes.isNotEmpty ? classes[0] : null);
          selectedClassByCard[idx] = defaultClass;
          if (defaultClass != null && trains[idx]['class_prices'] != null) {
            trains[idx]['price'] =
                trains[idx]['class_prices'][defaultClass] ?? 0;
          }
        }
      });
    }
  }

  void onDateChange(DateTime newDate) async {
    await fetchTrainsForDate(newDate);
  }

  DateTime _parseDate(String dateStr) {
    if (dateStr.contains('-')) {
      // yyyy-MM-dd or yyyy/MM/dd
      return DateTime.parse(dateStr.replaceAll('/', '-'));
    } else if (dateStr.contains('/')) {
      // dd/MM/yyyy
      final parts = dateStr.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } else {
      throw FormatException('Unknown date format: $dateStr');
    }
  }

  Future<Map<String, dynamic>?> fetchSeatAndPrice(
      int trainId, String travelClass) async {
    try {
      final uri = Uri.parse(
          '${ApiConstants.baseUrl}/api/v1/trains/seat_count?train_id=$trainId&travel_class=$travelClass');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['seat_count'] != null && data['price'] != null) {
          return data;
        }
      }
    } catch (e) {
      // Optionally log error
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    int minPrice = 999999;
    int maxPrice = 0;
    Set<String> allDays = {};
    for (var train in trains) {
      if (train['days_of_run'] != null) {
        allDays.addAll(List<String>.from(train['days_of_run']));
      }
      // If price is available in train object, update min/max
      if (train['price'] != null) {
        int price = train['price'] is int
            ? train['price']
            : int.tryParse(train['price'].toString()) ?? 0;
        if (price < minPrice) minPrice = price;
        if (price > maxPrice) maxPrice = price;
      }
    }
    if (minPrice == 999999) minPrice = 0;
    if (maxPrice == 0) maxPrice = 5000;

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
              child: _headerStationMarquee(
                  widget.originName, widget.destinationName),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sort, color: Colors.white),
            onPressed: () async {
              final apiFilters = {
                'sortBy':
                    'Relevance', // Replace with actual value from your API response/state
                'onlyAvailable': false, // Replace with actual value
                'minPrice': minPrice,
                'maxPrice': maxPrice,
                'selectedDays': [], // Replace with actual value
              };
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SortFilterScreen(
                    apiFilters: apiFilters,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    daysOfRun: allDays.toList(),
                  ),
                ),
              );
              if (result != null && result is Map) {
                // TODO: Apply the updated sort/filter to your train search logic
              }
            },
            tooltip: 'Sort/Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              controller: dateScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dateOptions.map((date) {
                  final isSelected = date == selectedDate;
                  return GestureDetector(
                    onTap: () => onDateChange(date),
                    child: Container(
                      width: 64,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(0xFF7C3AED)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun'
                            ][date.weekday - 1],
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: isSelected ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: trains.isEmpty
                ? Center(
                    child: Text('No trains found.',
                        style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 18,
                            color: Colors.black54)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (context, idx) => SizedBox(height: 18),
                    itemCount: trains.length,
                    itemBuilder: (context, idx) {
                      if (!classScrollControllers.containsKey(idx)) {
                        classScrollControllers[idx] = ScrollController();
                      }
                      final train = trains[idx];
                      final String trainName =
                          train['train_name'] ?? train['name'] ?? '';
                      final String trainNumber =
                          train['train_number']?.toString() ?? '';
                      final List<dynamic> days = train['days_of_run'] ?? [];
                      final List<dynamic> route = train['route'] ?? [];
                      final List<dynamic> schedule = train['schedule'] ?? [];
                      final String depTime = schedule.isNotEmpty
                          ? (schedule.first['departure'] ?? '')
                          : '';
                      final String arrTime = schedule.isNotEmpty
                          ? (schedule.last['arrival'] ?? '')
                          : '';

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            expandedCardIdx =
                                expandedCardIdx == idx ? null : idx;
                            print('Accordion tapped. expandedCardIdx: '
                                '\x1B[32m$expandedCardIdx\x1B[0m'); // Debug print, shows in green in console
                          });
                        },
                        child: Card(
                          key: ValueKey(idx),
                          color: Colors.white,
                          margin:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    // Expansion arrow indicator
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Icon(
                                        expandedCardIdx == idx
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        color: Color(0xFF7C3AED),
                                        size: 28,
                                      ),
                                    ),
                                    // Main content row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: train['logo'] != null
                                                  ? Image.network(train['logo'],
                                                      fit: BoxFit.contain)
                                                  : Icon(Icons.train,
                                                      color: Color(0xFF7C3AED),
                                                      size: 24),
                                            ),
                                            SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _stationTextMarquee(trainName),
                                                if (trainNumber.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(
                                                        top: 2.0, bottom: 2.0),
                                                    child: Text(
                                                      'Train No: $trainNumber',
                                                      style: TextStyle(
                                                        fontFamily: 'ProductSans',
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Color(0xFF7C3AED),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            SizedBox(width: 4),
                                          ],
                                        ),

                                      ],
                                    ),
                                  ],
                                ),
                                // Purple thin separator with bottom padding
                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  margin: EdgeInsets.only(top: 7, bottom: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(1),
                                    gradient: LinearGradient(colors: [
                                      Color(0xFF7C3AED),
                                      Color(0xFF9F7AEA)
                                    ]),
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _stationTextMarquee(widget.originName,
                                              align: TextAlign.left),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                color: Color(0xFF7C3AED),
                                                size: 18,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                depTime,
                                                style: TextStyle(
                                                    fontFamily: 'ProductSans',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF7C3AED)),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            _getScheduleDate(
                                                schedule.isNotEmpty
                                                    ? schedule.first
                                                    : null,
                                                selectedDate),
                                            style: TextStyle(
                                                fontFamily: 'ProductSans',
                                                fontSize: 13,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.train,
                                              color: Color(0xFF7C3AED),
                                              size: 22),
                                          SizedBox(height: 6),
                                          Text(
                                            'Duration',
                                            style: TextStyle(
                                                fontFamily: 'ProductSans',
                                                fontSize: 13,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            _getDuration(depTime, arrTime),
                                            style: TextStyle(
                                                fontFamily: 'ProductSans',
                                                fontSize: 13,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          _stationTextMarquee(
                                              widget.destinationName,
                                              align: TextAlign.right),
                                          SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                color: Color(0xFF7C3AED),
                                                size: 18,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                arrTime,
                                                style: TextStyle(
                                                    fontFamily: 'ProductSans',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF7C3AED)),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            _getScheduleDate(
                                                schedule.isNotEmpty
                                                    ? schedule.last
                                                    : null,
                                                selectedDate),
                                            style: TextStyle(
                                                fontFamily: 'ProductSans',
                                                fontSize: 13,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Animated accordion section
                                if (expandedCardIdx == idx)
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: Column(
                                      children: [
                                        SizedBox(height: 12),
                                        Builder(
                                          builder: (context) {
                                            final ScrollController? controller =
                                                classScrollControllers[idx];
                                            final int classCount =
                                                (train['classes_available'] as List?)
                                                        ?.length ??
                                                    0;
                                            final double boxWidth = 142;
                                            final double totalWidth = classCount *
                                                    (boxWidth + 12) +
                                                76; // 12 is separator, 76 is padding
                                            final double viewWidth =
                                                MediaQuery.of(context).size.width -
                                                    72; // 38 left + 38 right
                                            if (controller != null && controller.hasClients) {
                                              // Optionally, you can implement scroll arrow logic here if needed in the future
                                            }
                                            if (totalWidth <= viewWidth) {
                                              // No scroll arrows needed
                                            }
                                            return Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.all(20.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Availability Details',
                                                    style: TextStyle(
                                                        fontFamily: 'ProductSans',
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Color(0xFF7C3AED)),
                                                  ),
                                                  SizedBox(height: 16),
                                                  SizedBox(
                                                    height: 72,
                                                    child: Stack(
                                                      children: [
                                                        ListView.separated(
                                                          controller: controller,
                                                          scrollDirection: Axis.horizontal,
                                                          itemCount: classCount,
                                                          physics: BouncingScrollPhysics(),
                                                          padding: EdgeInsets.symmetric(horizontal: 38),
                                                          itemBuilder: (context, i) {
                                                            final String className = train['classes_available'][i];
                                                            final int seatCount = train['seat_availability']?[className] ?? 0;
                                                            final int price = train['class_prices']?[className] ?? 0;
                                                            final bool isSelected = selectedClassByCard[idx] == className;
                                                            final Color textColor = seatCount > 0 ? Colors.green : Colors.red;
                                                            final String seatText = seatCount > 0 ? "$seatCount Seats" : "Not Available";
                                                            return GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  selectedClassByCard[idx] = className;
                                                                  if (train['class_prices'] != null) {
                                                                    train['price'] = train['class_prices'][className];
                                                                    if (priceKeys.containsKey(idx)) {
                                                                      priceKeys[idx]!.currentState?.bounce();
                                                                    }
                                                                  }
                                                                });
                                                              },
                                                              child: Container(
                                                                width: 150, // Increased width to prevent overflow
                                                                margin: EdgeInsets.only(right: 12),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.white, // Always white background
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  boxShadow: [
                                                                    if (isSelected)
                                                                      BoxShadow(
                                                                        color: Color(0x337C3AED),
                                                                        blurRadius: 8,
                                                                        offset: Offset(0, 2),
                                                                      ),
                                                                  ],
                                                                  border: isSelected
                                                                      ? Border.all(color: Color(0xFF7C3AED), width: 2)
                                                                      : null,
                                                                ),
                                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                                child: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Flexible(
                                                                          child: Text(
                                                                            className,
                                                                            overflow: TextOverflow.ellipsis,
                                                                            style: TextStyle(
                                                                              fontFamily: 'ProductSans',
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 16,
                                                                              color: Color(0xFF7C3AED),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        PriceBounce(
                                                                          price: price,
                                                                          fontSize: 16,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    SizedBox(height: 6),
                                                                    Flexible(
                                                                      child: Text(
                                                                        seatText,
                                                                        overflow: TextOverflow.ellipsis,
                                                                        style: TextStyle(
                                                                          fontFamily: 'ProductSans',
                                                                          fontSize: 16,
                                                                          color: seatCount > 100 ? Colors.green : Colors.red,
                                                                          fontWeight: FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          separatorBuilder: (_, __) => SizedBox(width: 12),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
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
                ),
              ],
            ),
          );
        }
  }

  String _getDuration(String dep, String arr) {
    try {
      final depParts = dep.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      final arrParts = arr.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      final depTime = Duration(hours: depParts[0], minutes: depParts[1]);
      final arrTime = Duration(hours: arrParts[0], minutes: arrParts[1]);
      Duration duration = arrTime - depTime;
      if (duration.isNegative) {
        duration += Duration(days: 1);
      }
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    } catch (_) {
      return '';
    }
  }

  String _getScheduleDate(dynamic scheduleEntry, DateTime baseDate) {
    if (scheduleEntry == null || scheduleEntry['day_offset'] == null) {
      return _formatDate(baseDate);
    }
    int offset = 0;
    try {
      offset = int.tryParse(scheduleEntry['day_offset'].toString()) ?? 0;
    } catch (_) {}
    final date = baseDate.add(Duration(days: offset));
    return _formatDate(date);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _stationTextMarquee(String text, {TextAlign align = TextAlign.left}) {
    if (text.length > 14) {
      return SizedBox(
        width: 90,
        height: 20,
        child: Marquee(
          text: text,
          style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black),
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
        style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
      );
    }
  }

  Widget _headerStationMarquee(String origin, String destination) {
    final String text = '$origin → $destination';
    if (text.length > 20) {
      return SizedBox(
        height: 22,
        child: Marquee(
          text: text,
          style: TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white),
          scrollAxis: Axis.horizontal,
          blankSpace: 32.0,
          velocity: 25.0,
          pauseAfterRound: Duration(milliseconds: 900),
          startAfter: Duration(milliseconds: 900),
          fadingEdgeStartFraction: 0.06,
          fadingEdgeEndFraction: 0.06,
          showFadingOnlyWhenScrolling: false,
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.ltr,
        ),
      );
    } else {
      return Text(
        text,
        style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

class PriceBounce extends StatefulWidget {
  final int price;
  final double fontSize;
  PriceBounce({Key? key, required this.price, this.fontSize = 16}) : super(key: key);
  @override
  PriceBounceState createState() => PriceBounceState();
}

class PriceBounceState extends State<PriceBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1400));
    _scaleAnim = Tween<double>(begin: 1, end: 1.45)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);
  }

  void bounce() {
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(PriceBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price) {
      bounce();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Text(
            '₹${widget.price}',
            key: ValueKey(widget.price),
            style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
                fontSize: widget.fontSize,
                color: Color(0xFF7C3AED)),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
