import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/job_service.dart';
import '../services/passenger_service.dart';
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
  PassengerService? _passengerService;
  SharedPreferences? _prefs;

  // Saved passengers
  List<Map<String, dynamic>> _savedPassengers = [];
  bool _isLoadingSavedPassengers = false;
  Map<String, bool> _usedSavedPassengers = {};

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
      'idType': 'Aadhar',
      'idNumber': TextEditingController(),
      'isExpanded': true, // Track accordion expansion state
    }
  ];

  // Contact Details
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _gstNameController = TextEditingController();
  final _gstAddressController = TextEditingController();
  bool _showGstDetails = false;
  bool _optForInsurance = false;

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
    _initSharedPreferences();
  }

  // Initialize shared preferences
  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _initPassengerService();
    await _loadSavedPassengers();
  }

  // Initialize passenger service
  Future<void> _initPassengerService() async {
    if (_prefs != null) {
      // Use non-nullable SharedPreferences with the ! operator since we've checked it's not null
      _passengerService = PassengerService(_prefs!);
      if (mounted) {
        setState(() {
          _isLoadingSavedPassengers = true;
        });
      }
    } else {
      print('Error: SharedPreferences not initialized');
    }
  }

  // Load saved passengers from database
  Future<void> _loadSavedPassengers() async {
    if (_passengerService == null) return;

    // Set loading state
    setState(() {
      _isLoadingSavedPassengers = true;
    });

    try {
      final passengers = await _passengerService!.getFavoritePassengers();
      print('Loaded ${passengers.length} saved passengers');

      if (mounted) {
        setState(() {
          // Cast the List<dynamic> to List<Map<String, dynamic>> using map function
          _savedPassengers = passengers
              .map((passenger) => Map<String, dynamic>.from(passenger as Map))
              .toList();
          _isLoadingSavedPassengers = false;
        });
      }
    } catch (e) {
      print('Error loading saved passengers: $e');
      if (mounted) {
        setState(() {
          _isLoadingSavedPassengers = false;
        });
      }
    }
  }

  // Use a saved passenger
  void _useSavedPassenger(Map<String, dynamic> passenger) {
    if (_passengers.length >= 6) {
      _showCustomSnackBar(
        message: 'Maximum 6 passengers allowed',
        icon: Icons.error,
        backgroundColor: Colors.red,
      );
      return;
    }

    final name = passenger['name'] ?? '';
    final age = passenger['age']?.toString() ?? '';
    final gender = passenger['gender'] ?? 'Male';
    final idType = passenger['id_type'] ?? 'Aadhar';
    final idNumber = passenger['id_number'] ?? '';

    // Check if this passenger is already in use
    if (_usedSavedPassengers.containsKey(idNumber) &&
        _usedSavedPassengers[idNumber] == true) {
      _showCustomSnackBar(
        message: 'This passenger is already in your list',
        icon: Icons.warning,
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      // Add the passenger to the list
      _passengers.add({
        'name': TextEditingController(text: name),
        'age': TextEditingController(text: age),
        'gender': gender,
        'berth': 'No Preference',
        'isSenior': (int.tryParse(age) ?? 0) >= 60,
        'idType': idType,
        'idNumber': TextEditingController(text: idNumber),
        'isExpanded': true, // Expand the new passenger accordion
        'fromSavedList': true, // Mark that this passenger came from saved list
      });

      // Mark this passenger as used
      _usedSavedPassengers[idNumber] = true;
    });

    // Show a custom confirmation message
    _showCustomSnackBar(
      message: 'Passenger ${name} added as Passenger ${_passengers.length}',
      icon: Icons.person_add,
      backgroundColor: Color(0xFF7C3AED),
    );
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

    // GST controllers
    _gstNumberController.dispose();
    _gstNameController.dispose();
    _gstAddressController.dispose();

    // Passenger controllers
    for (var passenger in _passengers) {
      passenger['name'].dispose();
      passenger['age'].dispose();
      passenger['idNumber'].dispose();
    }

    super.dispose();
  }

  // Custom SnackBar for better user feedback
  void _showCustomSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.all(10),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Navigate to next step
  void _nextStep() {
    bool isValid = false;

    // Validate current step
    switch (_currentStep) {
      case 0: // Journey Details
        isValid = _journeyFormKey.currentState?.validate() ?? false;

        // Additional validation for journey details
        if (isValid) {
          // Check if origin and destination are selected
          if (_selectedOriginCode == null || _selectedOriginCode!.isEmpty) {
            isValid = false;
            _showCustomSnackBar(
              message: 'Please select a valid origin station',
              icon: Icons.error,
              backgroundColor: Colors.red,
            );
          } else if (_selectedDestinationCode == null ||
              _selectedDestinationCode!.isEmpty) {
            isValid = false;
            _showCustomSnackBar(
              message: 'Please select a valid destination station',
              icon: Icons.error,
              backgroundColor: Colors.red,
            );
          } else if (_selectedOriginCode == _selectedDestinationCode) {
            isValid = false;
            _showCustomSnackBar(
              message: 'Origin and destination cannot be the same',
              icon: Icons.error,
              backgroundColor: Colors.red,
            );
          }

          // Check if date and time are selected
          if (_selectedDate == null) {
            isValid = false;
            _showCustomSnackBar(
              message: 'Please select a journey date',
              icon: Icons.calendar_today,
              backgroundColor: Colors.red,
            );
          } else if (_selectedTime == null) {
            isValid = false;
            _showCustomSnackBar(
              message: 'Please select a journey time',
              icon: Icons.access_time,
              backgroundColor: Colors.red,
            );
          }
        }
        break;

      case 1: // Passenger Details
        isValid = _passengerFormKey.currentState?.validate() ?? false;

        // Additional validation for passenger details
        if (isValid) {
          for (var passenger in _passengers) {
            final name = passenger['name'].text;
            final age = passenger['age'].text;
            final idNumber = passenger['idNumber'].text;
            final idType = passenger['idType'];

            // Name validation
            if (name.isEmpty) {
              isValid = false;
              _showCustomSnackBar(
                message: 'Please enter name for all passengers',
                icon: Icons.person,
                backgroundColor: Colors.red,
              );
              break;
            }

            // Age validation
            if (age.isEmpty) {
              isValid = false;
              _showCustomSnackBar(
                message: 'Please enter age for all passengers',
                icon: Icons.cake,
                backgroundColor: Colors.red,
              );
              break;
            }

            final ageValue = int.tryParse(age);
            if (ageValue == null || ageValue <= 0 || ageValue > 120) {
              isValid = false;
              _showCustomSnackBar(
                message: 'Please enter a valid age between 1 and 120',
                icon: Icons.error,
                backgroundColor: Colors.red,
              );
              break;
            }

            // ID validation
            if (idNumber.isEmpty) {
              isValid = false;
              _showCustomSnackBar(
                message: 'Please enter ID Number for all passengers',
                icon: Icons.badge,
                backgroundColor: Colors.red,
              );
              break;
            }

            if (idType == 'Aadhar' &&
                (idNumber.length != 12 ||
                    !RegExp(r'^\d{12}$').hasMatch(idNumber))) {
              isValid = false;
              _showCustomSnackBar(
                message: 'Please enter a valid 12-digit Aadhar number',
                icon: Icons.numbers,
                backgroundColor: Colors.red,
              );
              break;
            } else if (idType == 'PAN' &&
                (idNumber.length != 10 ||
                    !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
                        .hasMatch(idNumber))) {
              isValid = false;
              _showCustomSnackBar(
                message: 'Please enter a valid 10-character PAN number',
                icon: Icons.credit_card,
                backgroundColor: Colors.red,
              );
              break;
            }
          }
        }
        break;

      case 2: // Contact Details
        isValid = _contactFormKey.currentState?.validate() ?? false;
        if (isValid) {
          // Additional validation for contact details if needed
          // For example, validating phone number format
          final phoneNumber = _phoneController.text;
          if (phoneNumber.length != 10 ||
              !RegExp(r'^[0-9]{10}$').hasMatch(phoneNumber)) {
            isValid = false;
            _showCustomSnackBar(
              message: 'Please enter a valid 10-digit phone number',
              icon: Icons.phone,
              backgroundColor: Colors.red,
            );
          }

          // Email validation
          final email = _emailController.text;
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
            isValid = false;
            _showCustomSnackBar(
              message: 'Please enter a valid email address',
              icon: Icons.email,
              backgroundColor: Colors.red,
            );
          }
        }
        break;

      case 3: // Preferences
        isValid = _preferencesFormKey.currentState?.validate() ?? false;
        // Additional validation for preferences if needed
        break;
    }

    if (isValid && _currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep += 1;
      });

      // Show success message when moving to next step
      _showCustomSnackBar(
        message: 'Step ${_currentStep} completed successfully',
        icon: Icons.check_circle,
        backgroundColor: Color(0xFF7C3AED),
      );
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
        'idType': 'Aadhar',
        'idNumber': TextEditingController(),
        'isExpanded': true, // New passengers start expanded
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
        passenger['idNumber'].dispose();
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
    // Ensure form keys are properly initialized before validation
    if (_journeyFormKey.currentState == null) {
      _showCustomSnackBar(
        message: 'Error: Journey form not initialized properly',
        icon: Icons.error,
        backgroundColor: Colors.red,
      );
      return;
    }

    // Manually validate each required field in the journey form
    bool originValid = _originController.text.isNotEmpty && _selectedOriginCode != null;
    bool destinationValid = _destinationController.text.isNotEmpty && _selectedDestinationCode != null;
    bool dateValid = _dateController.text.isNotEmpty;
    bool timeValid = _timeController.text.isNotEmpty;
    bool classValid = _selectedClass.isNotEmpty;
    
    // Check if origin and destination are different
    bool differentStations = _selectedOriginCode != _selectedDestinationCode;
    
    // Validate journey details manually
    if (!originValid || !destinationValid || !dateValid || !timeValid || !classValid || !differentStations) {
      _showCustomSnackBar(
        message: 'Please fill all journey details correctly',
        icon: Icons.error,
        backgroundColor: Colors.red,
      );
      return;
    }
    
    // Now validate other forms
    bool isPassengersValid =
        _passengerFormKey.currentState?.validate() ?? false;
    bool isContactValid = _contactFormKey.currentState?.validate() ?? false;

    // Only continue if journey details are valid

    if (!isPassengersValid) {
      _showCustomSnackBar(
        message: 'Please fill all passenger details correctly',
        icon: Icons.error,
        backgroundColor: Colors.red,
      );
      return;
    }

    if (!isContactValid) {
      _showCustomSnackBar(
        message: 'Please fill all contact details correctly',
        icon: Icons.error,
        backgroundColor: Colors.red,
      );
      return;
    }

    // Check if at least one passenger is added
    if (_passengers.isEmpty) {
      _showCustomSnackBar(
        message: 'Please add at least one passenger',
        icon: Icons.error,
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare passenger data
      List<Map<String, dynamic>> passengersData = [];
      for (var passenger in _passengers) {
        passengersData.add({
          'name': passenger['name'].text,
          'age': int.parse(passenger['age'].text),
          'gender': passenger['gender'],
          'berth_preference': passenger['berth'],
          'id_type': passenger['idType'],
          'id_number': passenger['idNumber'].text,
          'is_senior': passenger['isSenior'],
        });
      }

      // Prepare contact data
      Map<String, dynamic> contactData = {
        'email': _emailController.text,
        'phone': _phoneController.text,
        'opt_for_insurance': _optForInsurance,
      };

      // Add GST details if available
      if (_showGstDetails) {
        contactData['gst_details'] = {
          'gstin': _gstNumberController.text,
          'company_name': _gstNameController.text,
          'company_address': _gstAddressController.text,
        };
      }

      // Get train details from form
      String trainNumber = _originController.text.isNotEmpty &&
              _destinationController.text.isNotEmpty
          ? 'TRN-${DateTime.now().millisecondsSinceEpoch % 10000}'
          : '';
      String trainName = _originController.text.isNotEmpty &&
              _destinationController.text.isNotEmpty
          ? '${_originController.text.substring(0, min(3, _originController.text.length))}-${_destinationController.text.substring(0, min(3, _destinationController.text.length))} Express'
          : '';
      String selectedQuota = 'Tatkal';

      // Prepare journey data
      Map<String, dynamic> journeyData = {
        'from_station': _originController.text,
        'to_station': _destinationController.text,
        'journey_date': _dateController.text,
        'preferred_time': _timeController.text,
        'train_number': trainNumber,
        'train_name': trainName,
        'class': _selectedClass,
        'quota': selectedQuota,
      };

      // Prepare preferences data
      Map<String, dynamic> preferencesData = {
        'auto_upgrade': _autoUpgrade,
        'auto_book_alternate_date': _autoBookAlternateDate,
        'payment_method': _paymentMethod,
        'notes': _notesController.text,
      };

      // Combine all data
      Map<String, dynamic> jobData = {
        'user_id': _userId,
        'journey': journeyData,
        'passengers': passengersData,
        'contact': contactData,
        'preferences': preferencesData,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      // Save to SharedPreferences for now (in a real app, this would be sent to a server)
      final prefs = await SharedPreferences.getInstance();
      List<String> existingJobs = prefs.getStringList('tatkal_jobs') ?? [];

      // Generate a job ID
      String jobId = 'TJ-${DateTime.now().millisecondsSinceEpoch}';
      jobData['job_id'] = jobId;

      existingJobs.add(jsonEncode(jobData));
      await prefs.setStringList('tatkal_jobs', existingJobs);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _jobId = jobId;
          _isJobCreated = true;
        });
      }

      _showCustomSnackBar(
        message: 'Tatkal job created successfully!',
        icon: Icons.check_circle,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showCustomSnackBar(
          message: 'Error creating job: ${e.toString()}',
          icon: Icons.error,
          backgroundColor: Colors.red,
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
                minHeight: 6,
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
          child: Column(
            children: [
              // Back button row
              if (_currentStep > 0)
                Container(
                  width: double.infinity,
                  height: 52,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: _previousStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7C3AED),
                      elevation: 0,
                      side: const BorderSide(
                          color: Color(0xFF7C3AED), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

              // Next/Submit button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_currentStep == _totalSteps - 1
                          ? _createTatkalJob
                          : _nextStep),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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
                          _currentStep == _totalSteps - 1
                              ? 'Create Job'
                              : 'Next',
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
              _buildCustomStationCard(
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
                    if (result['sourceScreen'] == 'tatkal_mode' ||
                        result['sourceScreen'] == 'default') {
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
              _buildCustomStationCard(
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
                    if (result['sourceScreen'] == 'tatkal_mode' ||
                        result['sourceScreen'] == 'default') {
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
              _buildCustomStationCard(
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
                            surface: Colors.white,
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
                            surface: Colors.white,
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

        // Saved Passengers Section
        Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved Passengers',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              _isLoadingSavedPassengers
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child:
                            CircularProgressIndicator(color: Color(0xFF7C3AED)),
                      ),
                    )
                  : _savedPassengers.isEmpty
                      ? Container(
                          margin: EdgeInsets.symmetric(horizontal: 16.0),
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'No favourite passenger stored',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _savedPassengers.length,
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            itemBuilder: (context, index) {
                              final passenger = _savedPassengers[index];
                              // Check if this passenger is already used in the passenger list
                              final idNumber = passenger['id_number'] ?? '';
                              final isUsed =
                                  _usedSavedPassengers.containsKey(idNumber) &&
                                      _usedSavedPassengers[idNumber] == true;

                              return GestureDetector(
                                // Only allow tapping if the passenger is not already used
                                onTap: isUsed
                                    ? null
                                    : () => _useSavedPassenger(passenger),
                                child: Container(
                                  width: 200,
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 4.0, vertical: 4.0),
                                  padding: EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    // Gray out the card if already used
                                    color: isUsed
                                        ? Color(0xFFF3F4F6)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isUsed
                                            ? Color(0xFFD1D5DB)
                                            : Color(0xFFE5E7EB)),
                                    boxShadow: isUsed
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        passenger['name'] ?? '',
                                        style: TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF111827),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${passenger['age'] ?? ''} yrs • ${passenger['gender'] ?? ''}',
                                        style: TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${passenger['id_type'] ?? ''}: ${passenger['id_number'] ?? ''}',
                                        style: TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isUsed
                                              ? Color(0xFFE5E7EB)
                                              : Color(0xFFF3E8FF),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isUsed
                                              ? 'Already used'
                                              : 'Tap to use',
                                          style: TextStyle(
                                            fontFamily: 'ProductSans',
                                            color: isUsed
                                                ? Color(0xFF6B7280)
                                                : Color(0xFF7C3AED),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ],
          ),
        ),

        Form(
          key: _passengerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _passengers.length; i++) ...[
                Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: _passengers[i]['isExpanded'] ?? true,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _passengers[i]['isExpanded'] = expanded;
                          });
                        },
                        title: Text(
                          'Passenger ${i + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                            fontFamily: 'ProductSans',
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_passengers.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 22,
                                ),
                                onPressed: () => _removePassenger(i),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                splashRadius: 20,
                              ),
                            Icon(
                              _passengers[i]['isExpanded'] ?? true
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Passenger Name
                                  TextFormField(
                                    style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      color: Color(0xFF222222),
                                    ),
                                    controller: _passengers[i]['name'],
                                    decoration: InputDecoration(
                                      labelText: 'Full Name',
                                      labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF7F7FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      errorStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter passenger name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),

                                  // Age and Gender
                                  Row(
                                    children: [
                                      // Age
                                      Expanded(
                                        child: TextFormField(
                                          style: TextStyle(
                                            fontFamily: 'ProductSans',
                                            color: Color(0xFF222222),
                                          ),
                                          controller: _passengers[i]['age'],
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Age',
                                            labelStyle: TextStyle(
                                              fontFamily: 'ProductSans',
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF7C3AED),
                                            ),
                                            filled: true,
                                            fillColor: Color(0xFFF7F7FA),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            errorStyle: TextStyle(
                                              fontFamily: 'ProductSans',
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Required';
                                            }
                                            final age = int.tryParse(value);
                                            if (age == null ||
                                                age <= 0 ||
                                                age > 120) {
                                              return 'Invalid age';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Gender
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _passengers[i]['gender'],
                                          style: TextStyle(
                                            color: Color(0xFF222222),
                                            fontFamily: 'ProductSans',
                                          ),
                                          onChanged: (v) {
                                            setState(() {
                                              _passengers[i]['gender'] =
                                                  v ?? 'Male';
                                            });
                                          },
                                          dropdownColor: Colors.white,
                                          iconEnabledColor: Color(0xFF7C3AED),
                                          items: _genders
                                              .map((g) => DropdownMenuItem(
                                                  value: g, child: Text(g)))
                                              .toList(),
                                          decoration: InputDecoration(
                                            labelText: 'Gender',
                                            labelStyle: TextStyle(
                                              fontFamily: 'ProductSans',
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF7C3AED),
                                            ),
                                            filled: true,
                                            fillColor: Color(0xFFF7F7FA),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // ID Type and Number
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _passengers[i]['idType'],
                                          style: TextStyle(
                                            color: Color(0xFF222222),
                                            fontFamily: 'ProductSans',
                                          ),
                                          onChanged: (v) {
                                            setState(() {
                                              _passengers[i]['idType'] =
                                                  v ?? 'Aadhar';
                                            });
                                          },
                                          dropdownColor: Colors.white,
                                          iconEnabledColor: Color(0xFF7C3AED),
                                          items: [
                                            'Aadhar',
                                            'PAN',
                                            'Driving License'
                                          ]
                                              .map((id) => DropdownMenuItem(
                                                  value: id, child: Text(id)))
                                              .toList(),
                                          decoration: InputDecoration(
                                            labelText: 'ID Type',
                                            labelStyle: TextStyle(
                                              fontFamily: 'ProductSans',
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF7C3AED),
                                            ),
                                            filled: true,
                                            fillColor: Color(0xFFF7F7FA),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // ID Number
                                  TextFormField(
                                    controller: _passengers[i]['idNumber'],
                                    style: TextStyle(
                                      color: Color(0xFF222222),
                                      fontFamily: 'ProductSans',
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'ID Number',
                                      labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF7F7FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      errorStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      hintText: _passengers[i]['idType'] ==
                                              'Aadhar'
                                          ? '12-digit Aadhar number'
                                          : _passengers[i]['idType'] == 'PAN'
                                              ? '10-character PAN number'
                                              : 'Driving License number',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter ID number';
                                      }

                                      // Validate based on ID type
                                      if (_passengers[i]['idType'] ==
                                          'Aadhar') {
                                        if (value.length != 12 ||
                                            !RegExp(r'^\d{12}$')
                                                .hasMatch(value)) {
                                          return 'Enter valid 12-digit Aadhar';
                                        }
                                      } else if (_passengers[i]['idType'] ==
                                          'PAN') {
                                        if (value.length != 10 ||
                                            !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
                                                .hasMatch(value)) {
                                          return 'Enter valid 10-char PAN';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),

                                  // Berth Preference
                                  DropdownButtonFormField<String>(
                                    value: _passengers[i]['berth'],
                                    style: TextStyle(
                                      color: Color(0xFF222222),
                                      fontFamily: 'ProductSans',
                                    ),
                                    onChanged: (v) {
                                      setState(() {
                                        _passengers[i]['berth'] =
                                            v ?? 'No Preference';
                                      });
                                    },
                                    dropdownColor: Colors.white,
                                    iconEnabledColor: Color(0xFF7C3AED),
                                    items: _berthPreferences
                                        .map((b) => DropdownMenuItem(
                                            value: b, child: Text(b)))
                                        .toList(),
                                    decoration: InputDecoration(
                                      labelText: 'Berth Preference',
                                      labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF7F7FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Senior Citizen
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _passengers[i]['isSenior'],
                                        activeColor: const Color(0xFF7C3AED),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _passengers[i]['isSenior'] =
                                                value ?? false;
                                          });
                                        },
                                      ),
                                      const Text(
                                        'Senior Citizen',
                                        style: TextStyle(
                                          fontFamily: 'ProductSans',
                                          color: Color(0xFF222222),
                                        ),
                                      ),
                                    ],
                                  ),
                                ]),
                          ),
                        ],
                      ),
                    )),
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

  // Variables for travel insurance
  bool _showTravelInsurance = false;

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
              // Contact Information Card
              Container(
                margin: EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
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
                        style: TextStyle(
                          color: Color(0xFF222222),
                          fontFamily: 'ProductSans',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email (for ticket & alerts)',
                          labelStyle: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF7F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
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
                        style: TextStyle(
                          color: Color(0xFF222222),
                          fontFamily: 'ProductSans',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          labelStyle: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF7F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          prefixIcon:
                              Icon(Icons.phone, color: Color(0xFF7C3AED)),
                          errorStyle: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
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

              // Additional Preferences Section
              Container(
                margin: EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    childrenPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.white,
                    title: Text(
                      'Additional Preferences',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                        fontSize: 16,
                      ),
                    ),
                    children: [
                      // Travel Insurance Option
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            childrenPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            title: Text(
                              'Travel Insurance',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF222222),
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              _optForInsurance ? 'Selected: Yes' : 'Optional',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                color: _optForInsurance
                                    ? Color(0xFF7C3AED)
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(
                              _showTravelInsurance
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Color(0xFF7C3AED),
                            ),
                            onExpansionChanged: (bool expanded) {
                              setState(() {
                                _showTravelInsurance = expanded;
                              });
                            },
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IRCTC Travel Insurance provides coverage for journey-related risks. Premium: ₹10 per passenger (inclusive of taxes).',
                                    style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _optForInsurance = true;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _optForInsurance
                                                ? Color(0xFF7C3AED)
                                                : Color(0xFFF7F7FA),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              side: BorderSide(
                                                color: _optForInsurance
                                                    ? Color(0xFF7C3AED)
                                                    : Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10),
                                          ),
                                          child: Text(
                                            'Yes, I want insurance',
                                            style: TextStyle(
                                              color: _optForInsurance
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                              fontFamily: 'ProductSans',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _optForInsurance = false;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: !_optForInsurance
                                                ? Color(0xFF7C3AED)
                                                : Color(0xFFF7F7FA),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              side: BorderSide(
                                                color: !_optForInsurance
                                                    ? Color(0xFF7C3AED)
                                                    : Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10),
                                          ),
                                          child: Text(
                                            'No, thanks',
                                            style: TextStyle(
                                              color: !_optForInsurance
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                              fontFamily: 'ProductSans',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // GST Details Option
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            childrenPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            title: Text(
                              'GST Details (Optional)',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF222222),
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              _gstNumberController.text.isNotEmpty
                                  ? 'GSTIN: ${_gstNumberController.text}'
                                  : 'Add GST details for business travel',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                color: _gstNumberController.text.isNotEmpty
                                    ? Color(0xFF7C3AED)
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(
                              _showGstDetails
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Color(0xFF7C3AED),
                            ),
                            onExpansionChanged: (bool expanded) {
                              setState(() {
                                _showGstDetails = expanded;
                              });
                            },
                            children: [
                              Column(
                                children: [
                                  TextFormField(
                                    controller: _gstNumberController,
                                    style: TextStyle(
                                      color: Color(0xFF222222),
                                      fontFamily: 'ProductSans',
                                    ),
                                    // GST fields are optional even when expanded
                                    validator: (value) => null,
                                    decoration: InputDecoration(
                                      labelText: 'GSTIN',
                                      hintText: '22AAAAA0000A1Z5',
                                      labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED),
                                        fontSize: 12,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]!, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]!, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Color(0xFF7C3AED),
                                            width: 1.5),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _gstNameController,
                                    style: TextStyle(
                                      color: Color(0xFF222222),
                                      fontFamily: 'ProductSans',
                                    ),
                                    // Company name is optional
                                    validator: (value) => null,
                                    decoration: InputDecoration(
                                      labelText: 'Company Name',
                                      labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED),
                                        fontSize: 12,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]!, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]!, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Color(0xFF7C3AED),
                                            width: 1.5),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _gstAddressController,
                                    style: TextStyle(
                                      color: Color(0xFF222222),
                                      fontFamily: 'ProductSans',
                                    ),
                                    maxLines: 2,
                                    // Company address is optional
                                    validator: (value) => null,
                                    decoration: InputDecoration(
                                      labelText: 'Company Address',
                                      labelStyle: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED),
                                        fontSize: 12,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]!, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]!, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Color(0xFF7C3AED),
                                            width: 1.5),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildPreferencesStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Booking Preferences (Optional)'),
      const SizedBox(height: 16),
      // No Form validation needed for preferences as they're optional
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
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
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF7F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.only(bottom: 12),
                    child: SwitchListTile(
                      title: const Text(
                        'Auto Upgrade Class',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                          fontSize: 14,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                  ),

                  // Auto Book Alternate Date
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF7F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.only(bottom: 16),
                    child: SwitchListTile(
                      title: const Text(
                        'Auto Book Alternate Date',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                          fontSize: 14,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                  ),

                  // Payment Method
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Color(0xFFF7F7FA),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            prefixIcon:
                                Icon(Icons.payment, color: Color(0xFF7C3AED)),
                          ),
                          items: _paymentMethods.map((String method) {
                            return DropdownMenuItem<String>(
                              value: method,
                              child: Text(
                                method.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'ProductSans',
                                  color: Color(0xFF222222),
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
                          dropdownColor: Colors.white,
                          icon: Icon(Icons.arrow_drop_down,
                              color: Color(0xFF7C3AED)),
                          isExpanded: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Notes (Optional)',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        style: TextStyle(
                          color: Color(0xFF222222),
                          fontFamily: 'ProductSans',
                        ),
                        // Notes are optional
                        validator: (value) => null,
                        decoration: InputDecoration(
                          hintText:
                              'Enter any additional instructions or notes',
                          filled: true,
                          fillColor: Color(0xFFF7F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ]);
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom station card with explicit white background and purple accents
  Widget _buildCustomStationCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required Function() onTap,
    required String? Function(String?) validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF7C3AED).withOpacity(0.1),
          highlightColor: const Color(0xFF7C3AED).withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: const Color(0xFF7C3AED),
                      size: 20,
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.text.isEmpty
                              ? 'Tap to select'
                              : controller.text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ProductSans',
                            color: controller.text.isEmpty
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (validator(controller.text) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      validator(controller.text) ?? '',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontFamily: 'ProductSans',
                      ),
                    ),
                  ),
              ],
            ),
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
    // Using the custom station card implementation for consistency
    return _buildCustomStationCard(
      title: title,
      controller: controller,
      icon: icon,
      onTap: onTap,
      validator: validator,
    );
  }

  Widget _buildDropdownCard({
    required String title,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                fillColor: Colors.white,
                filled: true,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'ProductSans',
                color: Colors.black,
              ),
              dropdownColor: Colors.white,
              iconEnabledColor: Color(0xFF7C3AED),
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
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            width: double.infinity,
            height: 52,
            alignment: Alignment.center,
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
                    'Create Job',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ProductSans',
                    ),
                  ),
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
