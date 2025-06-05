import 'package:flutter/material.dart';

class SearchCard extends StatelessWidget {
  final int selectedTabIndex;
  final void Function(int) onTabChange;
  final TextEditingController originController;
  final TextEditingController destinationController;
  final VoidCallback onOriginTap;
  final VoidCallback onDestinationTap;
  final Function()? onSwapLocations;
  final Widget? Function(BuildContext, String)? extraFields;
  final int passengers;
  final void Function(bool)? onPassengersChanged;
  final VoidCallback onPassengersTap;
  final VoidCallback onSearch;
  final VoidCallback onDepartureDateTap;
  final VoidCallback onReturnDateTap;
  final String departureDateText;
  final String returnDateText;
  final bool isLoading;

  const SearchCard({
    Key? key,
    required this.selectedTabIndex,
    required this.onTabChange,
    required this.originController,
    required this.destinationController,
    required this.onOriginTap,
    required this.onDestinationTap,
    this.onSwapLocations,
    this.extraFields,
    required this.passengers,
    this.onPassengersChanged,
    required this.onPassengersTap,
    required this.onSearch,
    required this.onDepartureDateTap,
    required this.onReturnDateTap,
    required this.departureDateText,
    required this.returnDateText,
    this.isLoading = false,
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
            // Only One-Way tab (no tab switch)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'One-Way',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF7C3AED),
                ),
                textAlign: TextAlign.left,
              ),
            ),
            // Origin and Destination fields stacked vertically with interchange arrow
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextFormField(
                readOnly: true,
                controller: originController,
                decoration: InputDecoration(
                  labelText: 'Origin',
                  labelStyle: TextStyle(
                      fontFamily: 'ProductSans', color: Color(0xFF7C3AED)),
                  filled: true,
                  fillColor: Color(0xFFF5F5F5), // Light gray background
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
                    fontFamily: 'ProductSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
                onTap: onOriginTap,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Material(
                  color: Colors.white,
                  shape: CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    icon: Icon(Icons.swap_vert, color: Color(0xFF7C3AED)),
                    tooltip: 'Swap Origin & Destination',
                    onPressed: () {
                      final temp = originController.text;
                      originController.text = destinationController.text;
                      destinationController.text = temp;
                      
                      // Call the callback to update parent state
                      if (onSwapLocations != null) {
                        onSwapLocations!();
                      }
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 16),
              child: TextFormField(
                readOnly: true,
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  labelStyle: TextStyle(
                      fontFamily: 'ProductSans', color: Color(0xFF7C3AED)),
                  filled: true,
                  fillColor: Color(0xFFF5F5F5), // Light gray background
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF7C3AED)),
                ),
                style: const TextStyle(
                    fontFamily: 'ProductSans',
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
                    labelStyle: TextStyle(
                        fontFamily: 'ProductSans', color: Color(0xFF7C3AED)),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5), // Light gray background
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    prefixIcon:
                        Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
                  ),
                  style: TextStyle(
                      fontFamily: 'ProductSans',
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
                    labelStyle: TextStyle(
                        fontFamily: 'ProductSans', color: Color(0xFF7C3AED)),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5), // Light gray background
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    prefixIcon:
                        Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
                  ),
                  style: TextStyle(
                      fontFamily: 'ProductSans',
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
                    labelStyle: TextStyle(
                        fontFamily: 'ProductSans', color: Color(0xFF7C3AED)),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5), // Light gray background
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    prefixIcon:
                        Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
                  ),
                  style: TextStyle(
                      fontFamily: 'ProductSans',
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
                    labelStyle: TextStyle(
                        fontFamily: 'ProductSans', color: Color(0xFF7C3AED)),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5), // Light gray background
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
                                fontFamily: 'ProductSans',
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
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black),
                  onTap: onPassengersTap,
                ),
              ),
            ),
            // Search Trains Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSearch,
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
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3.0,
                            ),
                          )
                        : Text('Search Trains',
                            style: TextStyle(
                                fontFamily: 'ProductSans',
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
