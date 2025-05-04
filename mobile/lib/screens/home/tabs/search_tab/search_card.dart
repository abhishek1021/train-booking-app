import 'package:flutter/material.dart';

class SearchCard extends StatelessWidget {
  final int selectedTabIndex;
  final void Function(int) onTabChange;
  final TextEditingController originController;
  final TextEditingController destinationController;
  final VoidCallback onOriginTap;
  final VoidCallback onDestinationTap;
  final Widget? Function(BuildContext, String)?
      extraFields; // e.g. date pickers, etc.
  final int passengers;
  final void Function(bool)? onPassengersChanged;
  final VoidCallback onPassengersTap;
  final String trainClass;
  final void Function(String?)? onTrainClassChanged;
  final List<String> trainClasses;
  final VoidCallback onSearch;
  final VoidCallback onDepartureDateTap;
  final VoidCallback onReturnDateTap;
  final String departureDateText;
  final String returnDateText;

  const SearchCard({
    Key? key,
    required this.selectedTabIndex,
    required this.onTabChange,
    required this.originController,
    required this.destinationController,
    required this.onOriginTap,
    required this.onDestinationTap,
    this.extraFields,
    required this.passengers,
    this.onPassengersChanged,
    required this.onPassengersTap,
    required this.trainClass,
    this.onTrainClassChanged,
    required this.trainClasses,
    required this.onSearch,
    required this.onDepartureDateTap,
    required this.onReturnDateTap,
    required this.departureDateText,
    required this.returnDateText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs for One-Way and Round Trip
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChange(0),
                    child: Column(
                      children: [
                        Text('One-Way',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: selectedTabIndex == 0
                                  ? Color(0xFF7C3AED)
                                  : Colors.black26,
                            )),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          height: 3,
                          width: 56,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                              color: selectedTabIndex == 0
                                  ? Color(0xFF7C3AED)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChange(1),
                    child: Column(
                      children: [
                        Text('Round Trip',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: selectedTabIndex == 1
                                  ? Color(0xFF7C3AED)
                                  : Colors.black26,
                            )),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          height: 3,
                          width: 56,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                              color: selectedTabIndex == 1
                                  ? Color(0xFF7C3AED)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Origin field
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                readOnly: true,
                controller: originController,
                decoration: InputDecoration(
                  labelText: 'Origin',
                  labelStyle:
                      TextStyle(fontFamily: 'Lato', color: Color(0xFF444444)),
                  filled: true,
                  fillColor: Color(0xFFF7F7FA),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF7C3AED)),
                  suffixIcon: const Icon(Icons.arrow_drop_down,
                      color: Color(0xFF7C3AED)),
                ),
                style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
                onTap: onOriginTap,
              ),
            ),
            // Destination field
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                readOnly: true,
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  labelStyle:
                      TextStyle(fontFamily: 'Lato', color: Color(0xFF444444)),
                  filled: true,
                  fillColor: Color(0xFFF7F7FA),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF7C3AED)),
                ),
                style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
                onTap: onDestinationTap,
              ),
            ),
            // Date pickers (departure/return)
            if (selectedTabIndex == 0) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Departure Date',
                    labelStyle:
                        TextStyle(fontFamily: 'Lato', color: Color(0xFF444444)),
                    filled: true,
                    fillColor: Color(0xFFF7F7FA),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    prefixIcon:
                        Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
                  ),
                  style: TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black),
                  controller: TextEditingController(text: departureDateText),
                  onTap: onDepartureDateTap,
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Departure Date',
                    labelStyle:
                        TextStyle(fontFamily: 'Lato', color: Color(0xFF444444)),
                    filled: true,
                    fillColor: Color(0xFFF7F7FA),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    prefixIcon:
                        Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
                  ),
                  style: TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black),
                  controller: TextEditingController(text: departureDateText),
                  onTap: onDepartureDateTap,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Return Date',
                    labelStyle:
                        TextStyle(fontFamily: 'Lato', color: Color(0xFF444444)),
                    filled: true,
                    fillColor: Color(0xFFF7F7FA),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    prefixIcon:
                        Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
                  ),
                  style: TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black),
                  controller: TextEditingController(text: returnDateText),
                  onTap: onReturnDateTap,
                ),
              ),
            ],
            // Passengers field as a textbox
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: onPassengersTap,
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Passengers',
                    labelStyle:
                        TextStyle(fontFamily: 'Lato', color: Color(0xFF444444)),
                    filled: true,
                    fillColor: Color(0xFFF7F7FA),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline,
                              color: Color(0xFF7C3AED)),
                          onPressed: () => onPassengersChanged != null
                              ? onPassengersChanged!(false)
                              : null,
                        ),
                        Text('$passengers',
                            style: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF7C3AED))),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline,
                              color: Color(0xFF7C3AED)),
                          onPressed: () => onPassengersChanged != null
                              ? onPassengersChanged!(true)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  controller: TextEditingController(
                      text: '$passengers Adult${passengers > 1 ? 's' : ''}'),
                  style: const TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black),
                  onTap: onPassengersTap,
                ),
              ),
            ),
            // Train class dropdown styled as textbox
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: DropdownButtonFormField<String>(
                value: trainClass,
                decoration: InputDecoration(
                  labelText: 'Class',
                  labelStyle:
                      TextStyle(fontFamily: 'Lato', color: Color(0xFF444444)),
                  filled: true,
                  fillColor: Color(0xFFF7F7FA),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                dropdownColor: Colors.white,
                items: trainClasses
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: MouseRegion(
                            onHover: (event) {},
                            child: StatefulBuilder(
                              builder: (context, setState) {
                                return Container(
                                  decoration: BoxDecoration(),
                                  child: Text(
                                    c,
                                    style: const TextStyle(
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black),
                                  ),
                                );
                              },
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: onTrainClassChanged,
                style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
                icon: Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
              ),
            ),
            // Search Trains Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onSearch,
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
                    child: Text('Search Trains',
                        style: TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
