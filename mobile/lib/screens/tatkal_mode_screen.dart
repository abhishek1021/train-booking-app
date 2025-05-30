import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/job_service.dart';
import '../config/api_config.dart';
import '../widgets/success_animation_dialog.dart';
import 'city_search_screen.dart';

class TatkalModeScreen extends StatefulWidget {
  const TatkalModeScreen({Key? key}) : super(key: key);

  @override
  State<TatkalModeScreen> createState() => _TatkalModeScreenState();
}

class _TatkalModeScreenState extends State<TatkalModeScreen> {
  // Services
  final JobService _jobService = JobService();

  // Step tracking
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form keys for validation
  final _journeyFormKey = GlobalKey<FormState>();
  final _passengerFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();
  final _preferencesFormKey = GlobalKey<FormState>();

  // Journey Details
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  String _selectedClass = 'SL';
  String? _selectedOriginCode;
  String? _selectedDestinationCode;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Passenger Details
  List<Map<String, dynamic>> _passengers = [
    {
      'name': TextEditingController(),
      'age': TextEditingController(),
      'gender': 'Male',
      'berth': 'No Preference',
      'isSenior': false,
    }
  ];

  // Contact Details
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Preferences
  bool _autoUpgrade = false;
  bool _autoBookAlternateDate = false;
  String _paymentMethod = 'wallet';
  final _notesController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isJobCreated = false;
  String _jobId = '';
  String _userId = '';

  // Lists for dropdowns
  final List<String> _trainClasses = ['SL', '3A', '2A', '1A', 'CC', 'EC'];
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _berthPreferences = [
    'No Preference',
    'Lower',
    'Middle',
    'Upper',
    'Side Lower',
    'Side Upper'
  ];
  final List<String> _paymentMethods = ['wallet', 'upi', 'card'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileStr = prefs.getString('user_profile');

      if (userProfileStr != null) {
        final userProfile = jsonDecode(userProfileStr);
        setState(() {
          _userId = userProfile['user_id'] ?? '';
          _emailController.text = userProfile['Email'] ?? '';
          _phoneController.text = userProfile['Phone'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    // Journey controllers
    _originController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _timeController.dispose();

    // Contact controllers
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();

    // Passenger controllers
    for (var passenger in _passengers) {
      passenger['name'].dispose();
      passenger['age'].dispose();
    }

    super.dispose();
  }

  // Navigate to next step
  void _nextStep() {
    bool canProceed = false;

    switch (_currentStep) {
      case 0: // Journey Details
        canProceed = _journeyFormKey.currentState?.validate() ?? false;
        break;
      case 1: // Passenger Details
        canProceed = _passengerFormKey.currentState?.validate() ?? false;
        break;
      case 2: // Contact Details
        canProceed = _contactFormKey.currentState?.validate() ?? false;
        break;
      case 3: // Preferences
        canProceed = _preferencesFormKey.currentState?.validate() ?? false;
        break;
    }

    if (canProceed) {
      setState(() {
        if (_currentStep < _totalSteps - 1) {
          _currentStep++;
        }
      });
    }
  }

  // Go back to previous step
  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  // Add a new passenger
  void _addPassenger() {
    setState(() {
      _passengers.add({
        'name': TextEditingController(),
        'age': TextEditingController(),
        'gender': 'Male',
        'berth': 'No Preference',
        'isSenior': false,
      });
    });
  }

  // Remove a passenger
  void _removePassenger(int index) {
    if (_passengers.length > 1) {
      setState(() {
        final passenger = _passengers.removeAt(index);
        passenger['name'].dispose();
        passenger['age'].dispose();
      });
    }
  }

  // Format date
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Format time
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Create a new Tatkal job
  Future<void> _createTatkalJob() async {
    // Validate all forms
    if (!(_journeyFormKey.currentState?.validate() ?? false) ||
        !(_passengerFormKey.currentState?.validate() ?? false) ||
        !(_contactFormKey.currentState?.validate() ?? false) ||
        !(_preferencesFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare passenger data
      final List<Map<String, dynamic>> passengersData = _passengers
          .map((passenger) => {
                'name': passenger['name'].text,
                'age': int.parse(passenger['age'].text),
                'gender': passenger['gender'],
                'berth_preference': passenger['berth'],
                'is_senior_citizen': passenger['isSenior'],
              })
          .toList();

      // Create job
      final result = await _jobService.createJob(
        userId: _userId,
        originStationCode: _selectedOriginCode!,
        destinationStationCode: _selectedDestinationCode!,
        journeyDate: _formatDate(_selectedDate!),
        bookingTime: _formatTime(_selectedTime!),
        travelClass: _selectedClass,
        passengers: passengersData,
        jobType: 'Tatkal',
        bookingEmail: _emailController.text,
        bookingPhone: _phoneController.text,
        autoUpgrade: _autoUpgrade,
        autoBookAlternateDate: _autoBookAlternateDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      setState(() {
        _isLoading = false;
        _isJobCreated = true;
        _jobId = result['job_id'];
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessAnimationDialog(
            message: 'Tatkal job created successfully!\nJob ID: $_jobId',
            onAnimationComplete: () {
              // Dialog will auto-dismiss after animation
            },
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create job: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tatkal Mode',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
          ),
        ),
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isJobCreated ? _buildSuccessView() : _buildStepperView(),
    );
  }

  Widget _buildStepperView() {
    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of $_totalSteps',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ProductSans',
                    ),
                  ),
                  Text(
                    _getStepTitle(_currentStep),
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ProductSans',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.grey[200],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                borderRadius: BorderRadius.circular(10),
                minHeight: 8,
              ),
            ],
          ),
        ),

        // Step content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildStepContent(_currentStep),
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              _currentStep > 0
                  ? ElevatedButton(
                      onPressed: _previousStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7C3AED),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox(width: 100),

              // Next/Submit button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_currentStep == _totalSteps - 1
                        ? _createTatkalJob
                        : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentStep == _totalSteps - 1 ? 'Create Job' : 'Next',
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Journey Details';
      case 1:
        return 'Passenger Details';
      case 2:
        return 'Contact Details';
      case 3:
        return 'Preferences';
      default:
        return '';
    }
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildJourneyDetailsStep();
      case 1:
        return _buildPassengerDetailsStep();
      case 2:
        return _buildContactDetailsStep();
      case 3:
        return _buildPreferencesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildJourneyDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(),
        const SizedBox(height: 24),
        Form(
          key: _journeyFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Journey Details'),
              // Origin Station Card
              _buildStationCard(
                title: 'From Station',
                controller: _originController,
                icon: Icons.train,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CitySearchScreen(
                        searchType: 'station',
                        isOrigin: true,
                        sourceScreen: 'tatkal_mode',
                      ),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    // Check if the result is intended for this screen
                    if (result['sourceScreen'] == 'tatkal_mode' || result['sourceScreen'] == 'default') {
                      setState(() {
                        _originController.text = result['name'] ?? '';
                        _selectedOriginCode = result['code'] ?? '';
                      });
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select origin station';
                  }
                  if (_selectedOriginCode == null) {
                    return 'Please select a valid station';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Destination Station Card
              _buildStationCard(
                title: 'To Station',
                controller: _destinationController,
                icon: Icons.location_on,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CitySearchScreen(
                        searchType: 'station',
                        isOrigin: false,
                        sourceScreen: 'tatkal_mode',
                      ),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    // Check if the result is intended for this screen
                    if (result['sourceScreen'] == 'tatkal_mode' || result['sourceScreen'] == 'default') {
                      setState(() {
                        _destinationController.text = result['name'] ?? '';
                        _selectedDestinationCode = result['code'] ?? '';
                      });
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select destination station';
                  }
                  if (_selectedDestinationCode == null) {
                    return 'Please select a valid station';
                  }
                  if (_selectedOriginCode == _selectedDestinationCode) {
                    return 'Origin and destination cannot be the same';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Journey Date Card
              _buildDateCard(
                title: 'Journey Date',
                controller: _dateController,
                icon: Icons.calendar_today,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 120)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF7C3AED),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _dateController.text = _formatDate(picked);
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select journey date';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Booking Time Card
              _buildDateCard(
                title: 'Booking Time',
                controller: _timeController,
                icon: Icons.access_time,
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF7C3AED),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    setState(() {
                      _selectedTime = picked;
                      _timeController.text = _formatTime(picked);
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select booking time';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Travel Class Card
              _buildDropdownCard(
                title: 'Travel Class',
                icon: Icons.airline_seat_recline_normal,
                value: _selectedClass,
                items: _trainClasses.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedClass = newValue;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Passenger Details'),
        const SizedBox(height: 16),
        Form(
          key: _passengerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _passengers.length; i++) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Passenger ${i + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                                fontFamily: 'ProductSans',
                              ),
                            ),
                            if (_passengers.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removePassenger(i),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Passenger Name
                        TextFormField(
                          controller: _passengers[i]['name'],
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                            floatingLabelStyle: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontFamily: 'ProductSans',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter passenger name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Age and Gender
                        Row(
                          children: [
                            // Age
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _passengers[i]['age'],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Age',
                                  prefixIcon: Icon(Icons.cake),
                                  border: OutlineInputBorder(),
                                  floatingLabelStyle: TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontFamily: 'ProductSans',
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final age = int.tryParse(value);
                                  if (age == null || age <= 0 || age > 120) {
                                    return 'Invalid age';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Gender
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _passengers[i]['gender'],
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                  prefixIcon: Icon(Icons.people),
                                  border: OutlineInputBorder(),
                                  floatingLabelStyle: TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontFamily: 'ProductSans',
                                  ),
                                ),
                                items: _genders.map((String gender) {
                                  return DropdownMenuItem<String>(
                                    value: gender,
                                    child: Text(
                                      gender,
                                      style: const TextStyle(
                                        fontFamily: 'ProductSans',
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _passengers[i]['gender'] = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Berth Preference
                        DropdownButtonFormField<String>(
                          value: _passengers[i]['berth'],
                          decoration: const InputDecoration(
                            labelText: 'Berth Preference',
                            prefixIcon: Icon(Icons.airline_seat_flat),
                            border: OutlineInputBorder(),
                            floatingLabelStyle: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontFamily: 'ProductSans',
                            ),
                          ),
                          items: _berthPreferences.map((String berth) {
                            return DropdownMenuItem<String>(
                              value: berth,
                              child: Text(
                                berth,
                                style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _passengers[i]['berth'] = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Senior Citizen
                        Row(
                          children: [
                            Checkbox(
                              value: _passengers[i]['isSenior'],
                              activeColor: const Color(0xFF7C3AED),
                              onChanged: (bool? value) {
                                setState(() {
                                  _passengers[i]['isSenior'] = value ?? false;
                                });
                              },
                            ),
                            const Text(
                              'Senior Citizen',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < _passengers.length - 1) const SizedBox(height: 16),
              ],

              // Add Passenger Button
              const SizedBox(height: 16),
              if (_passengers.length < 6) // Maximum 6 passengers
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _addPassenger,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add Passenger',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Contact Details'),
        const SizedBox(height: 16),
        Form(
          key: _contactFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                          fontFamily: 'ProductSans',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                          floatingLabelStyle: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontFamily: 'ProductSans',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          floatingLabelStyle: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontFamily: 'ProductSans',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Booking Preferences'),
        const SizedBox(height: 16),
        Form(
          key: _preferencesFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                          fontFamily: 'ProductSans',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Auto Upgrade
                      SwitchListTile(
                        title: const Text(
                          'Auto Upgrade Class',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                          ),
                        ),
                        subtitle: const Text(
                          'Automatically upgrade to higher class if tickets are not available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'ProductSans',
                          ),
                        ),
                        value: _autoUpgrade,
                        activeColor: const Color(0xFF7C3AED),
                        onChanged: (bool value) {
                          setState(() {
                            _autoUpgrade = value;
                          });
                        },
                      ),

                      // Auto Book Alternate Date
                      SwitchListTile(
                        title: const Text(
                          'Auto Book Alternate Date',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                          ),
                        ),
                        subtitle: const Text(
                          'Try booking for next day if tickets are not available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'ProductSans',
                          ),
                        ),
                        value: _autoBookAlternateDate,
                        activeColor: const Color(0xFF7C3AED),
                        onChanged: (bool value) {
                          setState(() {
                            _autoBookAlternateDate = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Payment Method
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: Icon(Icons.payment),
                          border: OutlineInputBorder(),
                          floatingLabelStyle: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontFamily: 'ProductSans',
                          ),
                        ),
                        items: _paymentMethods.map((String method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(
                              method.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _paymentMethod = newValue;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes (Optional)',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                          floatingLabelStyle: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontFamily: 'ProductSans',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tatkal Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ProductSans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Automate your Tatkal booking process to increase your chances of securing a ticket during the Tatkal booking window.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'ProductSans',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(Icons.speed, 'Fast'),
              _buildInfoItem(Icons.security, 'Secure'),
              _buildInfoItem(Icons.check_circle, 'Reliable'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'ProductSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7C3AED),
          fontFamily: 'ProductSans',
        ),
      ),
    );
  }

  Widget _buildStationCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required Function() onTap,
    required String? Function(String?) validator,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                      fontFamily: 'ProductSans',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller,
                readOnly: true,
                validator: validator,
                decoration: InputDecoration(
                  hintText: 'Tap to select',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'ProductSans',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  errorStyle: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'ProductSans',
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ProductSans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required Function() onTap,
    required String? Function(String?) validator,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                      fontFamily: 'ProductSans',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller,
                readOnly: true,
                validator: validator,
                decoration: InputDecoration(
                  hintText: 'Tap to select',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'ProductSans',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  errorStyle: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'ProductSans',
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ProductSans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownCard({
    required String title,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF7C3AED),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                    fontFamily: 'ProductSans',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'ProductSans',
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF7C3AED),
              ),
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF7C3AED)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'ProductSans',
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontFamily: 'ProductSans',
        ),
      ),
      style: const TextStyle(
        color: Colors.black,
        fontFamily: 'ProductSans',
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontFamily: 'ProductSans',
          ),
        ),
        style: const TextStyle(
          color: Colors.black,
          fontFamily: 'ProductSans',
        ),
        items: items,
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createTatkalJob,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Create Tatkal Job',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ProductSans',
                ),
              ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'Job Created Successfully!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'ProductSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Job ID: $_jobId',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontFamily: 'ProductSans',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'ProductSans',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
