import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../api_constants.dart';

class TrainSelectionPopup extends StatefulWidget {
  final String originCode;
  final String destinationCode;
  final String journeyDate;
  final Function(Map<String, dynamic>?) onTrainSelected;
  final Function() onSkip;

  const TrainSelectionPopup({
    Key? key,
    required this.originCode,
    required this.destinationCode,
    required this.journeyDate,
    required this.onTrainSelected,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<TrainSelectionPopup> createState() => _TrainSelectionPopupState();
}

class _TrainSelectionPopupState extends State<TrainSelectionPopup> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _trains = [];
  int? _selectedTrainIndex;
  bool _skipSelection = false;

  @override
  void initState() {
    super.initState();
    _searchTrains();
  }

  Future<void> _searchTrains() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Use Dio for API call like in search_tab.dart
      final dio = Dio();
      final response = await dio.get(
        '${ApiConstants.baseUrl}/api/v1/trains/search'
            .replaceAll(RegExp(r'\/$'), ''),
        queryParameters: {
          'origin': widget.originCode,
          'destination': widget.destinationCode,
          'date': widget.journeyDate,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> trainData = response.data;
        setState(() {
          _trains = List<Map<String, dynamic>>.from(trainData.map((train) => Map<String, dynamic>.from(train)));
          _isLoading = false;
        });
        
        if (_trains.isEmpty) {
          setState(() {
            _hasError = true;
            _errorMessage = 'No trains found for this route and date';
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load trains. Server returned ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error searching trains: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // Make dialog cover 90% of screen width and height
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.05,
        vertical: screenSize.height * 0.05,
      ),
      backgroundColor: Colors.white,
      child: Container(
        width: screenSize.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _isLoading ? _buildLoadingIndicator() : _buildTrainList(),
            const SizedBox(height: 16),
            _buildSkipOption(),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Select Train',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C3AED),
            fontFamily: 'ProductSans',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF7C3AED)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
          ),
          SizedBox(height: 16),
          Text(
            'Searching for trains...',
            style: TextStyle(
              fontFamily: 'ProductSans',
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainList() {
    if (_hasError) {
      return Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: _searchTrains,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_trains.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(
              Icons.train,
              color: Colors.grey,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No trains found for this route and date.',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _trains.length,
        itemBuilder: (context, index) {
          final train = _trains[index];
          final trainNumber = train['train_number'] ?? 'Unknown';
          final trainName = train['train_name'] ?? 'Unknown';
          
          // Extract schedule information
          List<dynamic> schedule = train['schedule'] ?? [];
          String departureTime = 'Unknown';
          String arrivalTime = 'Unknown';
          
          if (schedule.isNotEmpty) {
            // First station departure
            departureTime = schedule.first['departure'] ?? 'Unknown';
            // Last station arrival
            arrivalTime = schedule.last['arrival'] ?? 'Unknown';
          }
          
          // Extract seat availability
          Map<String, dynamic> seatAvailability = 
              train['seat_availability'] as Map<String, dynamic>? ?? {};
          
          // Get available classes
          List<dynamic> classesAvailable = 
              train['classes_available'] as List<dynamic>? ?? [];
          
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _selectedTrainIndex == index
                    ? const Color(0xFF7C3AED)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTrainIndex = index;
                  _skipSelection = false;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Train number and name with waitlist tag
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$trainNumber - $trainName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'ProductSans',
                              color: Color(0xFF7C3AED)
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Waitlist',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ProductSans',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Departure, Duration, Arrival
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Departure',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontFamily: 'ProductSans',
                              ),
                            ),
                            Text(
                              departureTime,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ProductSans',
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(
                              Icons.train,
                              size: 16,
                              color: Color(0xFF7C3AED),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 60,
                              height: 1,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Arrival',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontFamily: 'ProductSans',
                              ),
                            ),
                            Text(
                              arrivalTime,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ProductSans',
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Seat availability
                    if (classesAvailable.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: classesAvailable.map((classCode) {
                          final seatCount = seatAvailability[classCode] ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, 
                              vertical: 4
                            ),
                            decoration: BoxDecoration(
                              color: seatCount > 0 
                                  ? Colors.green.shade50 
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: seatCount > 0 
                                    ? Colors.green.shade300 
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              '$classCode: $seatCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ProductSans',
                                color: seatCount > 0 
                                    ? Colors.green.shade700 
                                    : Colors.grey.shade700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    
                    // Radio button for selection
                    Radio<int>(
                      value: index,
                      groupValue: _selectedTrainIndex,
                      activeColor: const Color(0xFF7C3AED),
                      onChanged: (value) {
                        setState(() {
                          _selectedTrainIndex = value;
                          _skipSelection = false;
                        });
                      },
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

  Widget _buildSkipOption() {
    return CheckboxListTile(
      value: _skipSelection,
      onChanged: (value) {
        setState(() {
          _skipSelection = value ?? false;
          if (_skipSelection) {
            _selectedTrainIndex = null;
          }
        });
      },
      title: const Text(
        'Skip train selection (book any available train)',
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'ProductSans',
          color: Colors.black,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: const Color(0xFF7C3AED),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'ProductSans',
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_skipSelection) {
                    widget.onSkip();
                    Navigator.of(context).pop();
                  } else if (_selectedTrainIndex != null) {
                    final selectedTrain = _trains[_selectedTrainIndex!];
                    widget.onTrainSelected(selectedTrain);
                    Navigator.of(context).pop();
                  } else {
                    // Show error if neither skip is checked nor train is selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select a train or check the skip option',
                          style: TextStyle(fontFamily: 'ProductSans'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return; // Don't close dialog if validation fails
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
            ),
          ),
        ),
      ],
    );
  }
}
