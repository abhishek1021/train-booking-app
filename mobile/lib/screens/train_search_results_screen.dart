import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'dart:math';
import 'sort_filter_screen.dart';

class TrainSearchResultsScreen extends StatefulWidget {
  final List<dynamic> trains;
  final String origin;
  final String destination;
  final String date;

  const TrainSearchResultsScreen({
    Key? key,
    required this.trains,
    required this.origin,
    required this.destination,
    required this.date,
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
  Map<int, GlobalKey<__PriceBounceState>> priceKeys = {};
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedIdx = dateOptions.indexOf(selectedDate);
      if (selectedIdx != -1) {
        dateScrollController.jumpTo((selectedIdx - 2).clamp(0, dateOptions.length - 1) * 72.0);
      }
    });
  }

  void onDateChange(DateTime newDate) async {
    setState(() {
      selectedDate = newDate;
    });
    // TODO: Replace with actual fetch logic
    // final newTrains = await fetchTrainsForDate(newDate);
    // setState(() { trains = newTrains; });
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

  @override
  Widget build(BuildContext context) {
    List<String> allClasses = [];
    int minPrice = 999999;
    int maxPrice = 0;
    Set<String> allDays = {};
    for (var train in trains) {
      if (train['classes_available'] != null) {
        allClasses.addAll(List<String>.from(train['classes_available']));
      }
      if (train['days_of_run'] != null) {
        allDays.addAll(List<String>.from(train['days_of_run']));
      }
      // If price is available in train object, update min/max
      if (train['price'] != null) {
        int price = train['price'] is int ? train['price'] : int.tryParse(train['price'].toString()) ?? 0;
        if (price < minPrice) minPrice = price;
        if (price > maxPrice) maxPrice = price;
      }
    }
    if (allClasses.isEmpty) allClasses = ['1A', '2A', '3A', 'SL', '2S'];
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
              child: _headerStationMarquee(widget.origin, widget.destination),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sort, color: Colors.white),
            onPressed: () async {
              final apiFilters = {
                'sortBy': 'Relevance', // Replace with actual value from your API response/state
                'onlyAvailable': false, // Replace with actual value
                'selectedClasses': [], // Replace with actual value
                'minPrice': minPrice,
                'maxPrice': maxPrice,
                'selectedDays': [], // Replace with actual value
              };
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SortFilterScreen(
                    apiFilters: apiFilters,
                    allClasses: allClasses,
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
                              fontFamily: 'Lato',
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontFamily: 'Lato',
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
                            fontFamily: 'Lato',
                            fontSize: 18,
                            color: Colors.black54)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (context, idx) => SizedBox(height: 18),
                    itemCount: trains.length,
                    itemBuilder: (context, idx) {
                      final train = trains[idx];
                      final String trainName =
                          train['train_name'] ?? train['name'] ?? '';
                      final String trainNumber =
                          train['train_number']?.toString() ?? '';
                      final List<dynamic> classes =
                          train['classes_available'] ?? [];
                      final List<dynamic> days = train['days_of_run'] ?? [];
                      final List<dynamic> route = train['route'] ?? [];
                      final List<dynamic> schedule = train['schedule'] ?? [];
                      final String depTime = schedule.isNotEmpty
                          ? (schedule.first['departure'] ?? '')
                          : '';
                      final String arrTime = schedule.isNotEmpty
                          ? (schedule.last['arrival'] ?? '')
                          : '';

                      if (!seatCountsByCard.containsKey(idx)) {
                        final random = Random(idx + DateTime.now().millisecondsSinceEpoch);
                        seatCountsByCard[idx] = {
                          for (final c in classes)
                            c.toString(): random.nextInt(150), // 0-149 seats
                        };
                      }
                      final seatCounts = seatCountsByCard[idx]!;
                      final selectedClass = selectedClassByCard[idx];

                      if (!priceKeys.containsKey(idx)) priceKeys[idx] = GlobalKey<__PriceBounceState>();

                      if (!classScrollControllers.containsKey(idx)) {
                        classScrollControllers[idx] = ScrollController();
                        showLeftArrow[idx] = false;
                        showRightArrow[idx] = true;
                        classScrollControllers[idx]!.addListener(() {
                          final ctrl = classScrollControllers[idx]!;
                          final maxScroll = ctrl.position.maxScrollExtent;
                          final minScroll = ctrl.position.minScrollExtent;
                          final pos = ctrl.position.pixels;
                          setState(() {
                            showLeftArrow[idx] = pos > minScroll + 5;
                            showRightArrow[idx] = pos < maxScroll - 5;
                          });
                        });
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            expandedCardIdx =
                                expandedCardIdx == idx ? null : idx;
                          });
                        },
                        child: Card(
                          color: Colors.white,
                          margin: EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18.0, vertical: 22.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                                padding:
                                                    const EdgeInsets.only(
                                                        top: 2.0, bottom: 2.0),
                                                child: Text(
                                                  'Train No: $trainNumber',
                                                  style: TextStyle(
                                                    fontFamily: 'Lato',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: Color(0xFF7C3AED),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(width: 4),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Available',
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontFamily: 'Lato',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 11),
                                        ),
                                        SizedBox(height: 4),
                                        (selectedClass != null)
                                          ? PriceBounce(
                                              key: priceKeys[idx],
                                              price: _getPriceForClass(selectedClass),
                                              fontSize: 16,
                                            )
                                          : SizedBox.shrink(),
                                      ],
                                    ),
                                  ],
                                ),
                                // Purple thin separator with bottom padding
                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  margin:
                                      EdgeInsets.only(top: 7, bottom: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(1),
                                    gradient: LinearGradient(colors: [
                                      Color(0xFF7C3AED),
                                      Color(0xFF9F7AEA)
                                    ]),
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _stationTextMarquee(widget.origin, align: TextAlign.left),
                                          SizedBox(height: 6),
                                          Text(
                                            depTime,
                                            style: TextStyle(
                                                fontFamily: 'Lato',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF7C3AED)),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            _getScheduleDate(
                                                schedule.isNotEmpty
                                                    ? schedule.first
                                                    : null,
                                                selectedDate),
                                            style: TextStyle(
                                                fontFamily: 'Lato',
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
                                                fontFamily: 'Lato',
                                                fontSize: 13,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            _getDuration(depTime, arrTime),
                                            style: TextStyle(
                                                fontFamily: 'Lato',
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
                                          _stationTextMarquee(widget.destination, align: TextAlign.right),
                                          SizedBox(height: 6),
                                          Text(
                                            arrTime,
                                            style: TextStyle(
                                                fontFamily: 'Lato',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF7C3AED)),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            _getScheduleDate(
                                                schedule.isNotEmpty
                                                    ? schedule.last
                                                    : null,
                                                selectedDate),
                                            style: TextStyle(
                                                fontFamily: 'Lato',
                                                fontSize: 13,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (expandedCardIdx == idx) ...[
                                  SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Color(0xFF7C3AED), width: 1),
                                    ),
                                    padding: const EdgeInsets.all(18.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Availability Details',
                                          style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF7C3AED)),
                                        ),
                                        SizedBox(height: 10),
                                        SizedBox(
                                          height: 56,
                                          child: Stack(
                                            children: [
                                              ListView.separated(
                                                controller: classScrollControllers[idx],
                                                scrollDirection: Axis.horizontal,
                                                itemCount: classes.length,
                                                physics: BouncingScrollPhysics(),
                                                padding: EdgeInsets.symmetric(horizontal: 38),
                                                itemBuilder: (context, i) {
                                                  final c = classes[i];
                                                  return _buildClassAvailabilityBox(idx, c.toString(), seatCounts[c.toString()]!, selectedClass == c.toString());
                                                },
                                                separatorBuilder: (_, __) => SizedBox(width: 12),
                                              ),
                                              if (showRightArrow[idx] == true)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  bottom: 0,
                                                  child: IgnorePointer(
                                                    child: Container(
                                                      width: 38,
                                                      alignment: Alignment.center,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.centerLeft,
                                                          end: Alignment.centerRight,
                                                          colors: [Colors.transparent, Color(0x337C3AED)],
                                                        ),
                                                      ),
                                                      child: Icon(Icons.arrow_forward_ios, color: Color(0xFF7C3AED), size: 22),
                                                    ),
                                                  ),
                                                ),
                                              if (showLeftArrow[idx] == true)
                                                Positioned(
                                                  left: 0,
                                                  top: 0,
                                                  bottom: 0,
                                                  child: IgnorePointer(
                                                    child: Container(
                                                      width: 38,
                                                      alignment: Alignment.center,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.centerRight,
                                                          end: Alignment.centerLeft,
                                                          colors: [Colors.transparent, Color(0x337C3AED)],
                                                        ),
                                                      ),
                                                      child: Icon(Icons.arrow_back_ios_new, color: Color(0xFF7C3AED), size: 22),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (selectedClass != null) ...[
                                          SizedBox(height: 16),
                                          Container(
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
                                                // Book now action
                                              },
                                              child: Ink(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)]),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  child: Text('Book Now', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
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

  Widget _buildClassAvailabilityBox(int cardIdx, String className, int seatCount, bool isSelected) {
    Color borderColor = isSelected ? Color(0xFF7C3AED) : Colors.grey.shade300;
    Color statusColor;
    String statusText;
    if (seatCount > 100) {
      statusColor = Colors.green;
      statusText = 'Available';
    } else if (seatCount > 0) {
      statusColor = Colors.red;
      statusText = 'Filling up fast';
    } else {
      statusColor = Colors.red;
      statusText = 'Not available';
    }
    return GestureDetector(
      onTap: seatCount > 0 ? () {
        setState(() {
          selectedClassByCard[cardIdx] = className;
        });
        priceKeys[cardIdx]?.currentState?.bounce();
      } : null,
      child: Container(
        width: 110,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF6F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              className,
              style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED)),
            ),
            SizedBox(width: 7),
            Icon(Icons.event_seat, color: Color(0xFF7C3AED), size: 16),
            SizedBox(width: 2),
            Text(
              seatCount.toString(),
              style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  int _getPriceForClass(String? className) {
    switch (className) {
      case '3A':
        return 1300;
      case '2A':
        return 1900;
      case '1A':
        return 3000;
      case 'SL':
        return 550;
      case '2S':
        return 300;
      default:
        return 200;
    }
  }

  Widget _stationTextMarquee(String text, {TextAlign align = TextAlign.left}) {
    if (text.length > 14) {
      return SizedBox(
        width: 90,
        height: 20,
        child: Marquee(
          text: text,
          style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black),
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
        style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black),
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
          style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
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
        style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }
}

class PriceBounce extends StatefulWidget {
  final int price;
  final double fontSize;
  const PriceBounce({Key? key, required this.price, this.fontSize = 16}) : super(key: key);
  @override
  __PriceBounceState createState() => __PriceBounceState();
}

class __PriceBounceState extends State<PriceBounce> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 1400));
    _scaleAnim = Tween<double>(begin: 1, end: 1.45).chain(CurveTween(curve: Curves.elasticOut)).animate(_controller);
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
            style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: widget.fontSize, color: Color(0xFF7C3AED)),
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
