import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class SortFilterScreen extends StatefulWidget {
  final Map<String, dynamic> apiFilters;
  final int minPrice;
  final int maxPrice;
  final List<String> daysOfRun;
  const SortFilterScreen(
      {Key? key,
      required this.apiFilters,
      required this.minPrice,
      required this.maxPrice,
      required this.daysOfRun})
      : super(key: key);

  @override
  State<SortFilterScreen> createState() => _SortFilterScreenState();
}

class _SortFilterScreenState extends State<SortFilterScreen> {
  late String sortBy;
  late bool onlyAvailable;
  late RangeValues priceRange;
  late List<String> selectedDays;

  @override
  void initState() {
    super.initState();
    sortBy = widget.apiFilters['sortBy'] ?? 'Relevance';
    onlyAvailable = widget.apiFilters['onlyAvailable'] ?? false;
    priceRange = RangeValues(
      (widget.apiFilters['minPrice'] ?? widget.minPrice).toDouble(),
      (widget.apiFilters['maxPrice'] ?? widget.maxPrice).toDouble(),
    );
    selectedDays = List<String>.from(widget.apiFilters['selectedDays'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF7C3AED),
        elevation: 0,
        title: Text('Sort & Filter',
            style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By',
                style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF7C3AED))),
            SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                _sortChip('Relevance'),
                _sortChip('Departure Time'),
                _sortChip('Arrival Time'),
                _sortChip('Price'),
                _sortChip('Duration'),
              ],
            ),
            SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Show Only Available',
                    style: TextStyle(
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Switch(
                  value: onlyAvailable,
                  activeColor: Color(0xFF7C3AED),
                  onChanged: (val) => setState(() => onlyAvailable = val),
                ),
              ],
            ),
            SizedBox(height: 28),
            Text('Days of Run',
                style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF7C3AED))),
            SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: widget.daysOfRun.map((d) => _dayChip(d)).toList(),
            ),
            SizedBox(height: 28),
            Text('Price Range',
                style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF7C3AED))),
            SizedBox(height: 8),
            RangeSlider(
              values: priceRange,
              min: widget.minPrice.toDouble(),
              max: widget.maxPrice.toDouble(),
              divisions: 100,
              activeColor: Color(0xFF7C3AED),
              inactiveColor: Color(0xFFEEE8FD),
              labels: RangeLabels(
                  '₹${priceRange.start.toInt()}', '₹${priceRange.end.toInt()}'),
              onChanged: (range) => setState(() => priceRange = range),
            ),
            Spacer(),
            SizedBox(
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
                  overlayColor: MaterialStateProperty.all(
                      Color(0xFF9F7AEA).withOpacity(0.08)),
                ),
                onPressed: () {
                  Navigator.of(context).pop({
                    'sortBy': sortBy,
                    'onlyAvailable': onlyAvailable,
                    'selectedDays': selectedDays,
                    'minPrice': priceRange.start.toInt(),
                    'maxPrice': priceRange.end.toInt(),
                  });
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text('Apply',
                        style: TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String label) {
    final selected = sortBy == label;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontFamily: 'Lato',
              color: selected ? Colors.white : Color(0xFF7C3AED),
              fontWeight: FontWeight.bold)),
      selected: selected,
      selectedColor: Color(0xFF7C3AED),
      backgroundColor: Color(0xFFF6F3FF),
      onSelected: (val) => setState(() => sortBy = label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _dayChip(String d) {
    final selected = selectedDays.contains(d);
    return FilterChip(
      label: Text(d,
          style: TextStyle(
              fontFamily: 'Lato',
              color: selected ? Colors.white : Color(0xFF7C3AED),
              fontWeight: FontWeight.bold)),
      selected: selected,
      selectedColor: Color(0xFF7C3AED),
      backgroundColor: Color(0xFFF6F3FF),
      onSelected: (val) => setState(() {
        if (val) {
          selectedDays.add(d);
        } else {
          selectedDays.remove(d);
        }
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
