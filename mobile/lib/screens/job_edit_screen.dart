import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/job_service.dart';
import '../api_constants.dart';
import 'city_search_screen.dart';
import '../widgets/success_animation_dialog.dart';
import '../widgets/failure_animation_dialog.dart';
import '../services/passenger_service.dart';
import '../utils/validators.dart';

class JobEditScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const JobEditScreen({
    Key? key,
    required this.jobId,
    required this.jobData,
  }) : super(key: key);

  @override
  _JobEditScreenState createState() => _JobEditScreenState();
}

class _JobEditScreenState extends State<JobEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final JobService _jobService = JobService();
  
  // Form controllers
  late TextEditingController _jobIdController;
  late TextEditingController _originController;
  late TextEditingController _destinationController;
  late TextEditingController _journeyDateController;
  late TextEditingController _bookingTimeController;
  late String _selectedTravelClass; // Changed to String for dropdown
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  
  // Job scheduling controllers
  late TextEditingController _jobDateController;
  late TextEditingController _jobExecutionTimeController;
  
  // Optional values controllers
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _gstCompanyNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _autoUpgrade = false;
  bool _autoBookAlternateDate = false;
  bool _optForInsurance = false;
  bool _showGstDetails = false;
  bool _showTravelInsurance = false;
  
  // Passenger service and related state
  late SharedPreferences _prefs;
  PassengerService? _passengerService;
  List<dynamic> _savedPassengers = [];
  bool _isLoadingSavedPassengers = false;
  Map<String, bool> _usedSavedPassengers = {};
  
  // Passengers for this job
  List<Map<String, dynamic>> _passengers = [];
  
  @override
  void initState() {
    super.initState();
    _initControllers();
    _initPassengerService();
  }
  
  void _initControllers() {
    final jobData = widget.jobData;
    
    // Initialize job ID controller
    _jobIdController = TextEditingController(text: jobData['job_id'] ?? widget.jobId);
    
    // Initialize station codes with proper field names
    _originController = TextEditingController(text: jobData['origin_station_code'] ?? jobData['origin'] ?? '');
    _destinationController = TextEditingController(text: jobData['destination_station_code'] ?? jobData['destination'] ?? '');
    
    // Initialize other journey details
    _journeyDateController = TextEditingController(text: jobData['journey_date'] ?? '');
    _bookingTimeController = TextEditingController(text: jobData['booking_time'] ?? '');
    _selectedTravelClass = jobData['travel_class'] ?? 'SL'; // Default to Sleeper class if not specified
    
    // Initialize job scheduling details
    _jobDateController = TextEditingController(text: jobData['job_date'] ?? jobData['journey_date'] ?? '');
    _jobExecutionTimeController = TextEditingController(text: jobData['job_execution_time'] ?? jobData['booking_time'] ?? '');
    
    // Initialize contact information with proper field names
    _emailController = TextEditingController(text: jobData['booking_email'] ?? jobData['email'] ?? '');
    _phoneController = TextEditingController(text: jobData['booking_phone'] ?? jobData['phone'] ?? '');
    _notesController = TextEditingController(text: jobData['notes'] ?? '');
    
    // Initialize optional values
    _autoUpgrade = jobData['auto_upgrade'] ?? false;
    _autoBookAlternateDate = jobData['auto_book_alternate_date'] ?? false;
    _optForInsurance = jobData['opt_for_insurance'] ?? false;
    
    // Initialize GST details if available
    if (jobData['gst_number'] != null && jobData['gst_number'].isNotEmpty) {
      _showGstDetails = true;
      _gstNumberController.text = jobData['gst_number'];
      _gstCompanyNameController.text = jobData['gst_company_name'] ?? '';
    }
    
    // Initialize passengers if available
    if (jobData['passengers'] != null && jobData['passengers'] is List) {
      _passengers = List<Map<String, dynamic>>.from(jobData['passengers']);
    }
  }
  
  Future<void> _initPassengerService() async {
    _isLoadingSavedPassengers = true;
    if (mounted) setState(() {});
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _passengerService = PassengerService(_prefs);
      await _loadSavedPassengers();
    } catch (e) {
      print('Error initializing passenger service: $e');
    } finally {
      _isLoadingSavedPassengers = false;
      if (mounted) setState(() {});
    }
  }
  
  Future<void> _loadSavedPassengers() async {
    _isLoadingSavedPassengers = true;
    if (mounted) setState(() {});
    
    try {
      _savedPassengers = await _passengerService?.getFavoritePassengers() ?? [];
      
      // Reset the used passengers map
      _usedSavedPassengers = {};
      
      // Mark passengers that are already used in this job
      for (final passenger in _passengers) {
        final idNumber = passenger['id_number'];
        if (idNumber != null && idNumber.isNotEmpty) {
          _usedSavedPassengers[idNumber] = true;
        }
      }
    } catch (e) {
      print('Error loading saved passengers: $e');
    } finally {
      _isLoadingSavedPassengers = false;
      if (mounted) setState(() {});
    }
  }
  
  void _useSavedPassenger(Map<String, dynamic> savedPassenger) {
    // Create a copy of the saved passenger
    final passenger = Map<String, dynamic>.from(savedPassenger);
    
    // Add to passengers list
    setState(() {
      _passengers.add(passenger);
      
      // Mark as used
      final idNumber = passenger['id_number'];
      if (idNumber != null && idNumber.isNotEmpty) {
        _usedSavedPassengers[idNumber] = true;
      }
    });
  }
  
  void _removePassenger(int index) {
    if (index >= 0 && index < _passengers.length) {
      final passenger = _passengers[index];
      final idNumber = passenger['id_number'];
      
      setState(() {
        _passengers.removeAt(index);
        
        // Mark as unused if it was a saved passenger
        if (idNumber != null && idNumber.isNotEmpty) {
          _usedSavedPassengers[idNumber] = false;
        }
      });
    }
  }
  
  @override
  void dispose() {
    // Dispose controllers
    _jobIdController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _journeyDateController.dispose();
    _bookingTimeController.dispose();
    // No need to dispose _selectedTravelClass as it's a String
    _jobDateController.dispose();
    _jobExecutionTimeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _gstNumberController.dispose();
    _gstCompanyNameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Job',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF7C3AED)),
      ),
      backgroundColor: Color(0xFFF9FAFB),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : Form(
              key: _formKey,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Journey Details'),
                        SizedBox(height: 8),
                        _buildJourneySection(),
                        SizedBox(height: 24),
                        _buildSectionTitle('Job Scheduling'),
                        SizedBox(height: 8),
                        _buildJobSchedulingSection(),
                        SizedBox(height: 24),
                        _buildSectionTitle('Contact Information'),
                        SizedBox(height: 8),
                        _buildContactSection(),
                        SizedBox(height: 24),
                        _buildSectionTitle('Job Configuration'),
                        SizedBox(height: 8),
                        _buildJobConfigSection(),
                        SizedBox(height: 24),
                        _buildSectionTitle('Saved Passengers'),
                        SizedBox(height: 8),
                        _buildSavedPassengersSection(),
                        SizedBox(height: 24),
                        _buildSectionTitle('Passengers'),
                        SizedBox(height: 8),
                        _buildPassengersSection(),
                        SizedBox(height: 24),
                        _buildSectionTitle('Additional Preferences'),
                        SizedBox(height: 8),
                        _buildAdditionalPreferencesSection(),
                        SizedBox(height: 24),
                        _buildSectionTitle('Notes'),
                        SizedBox(height: 8),
                        _buildNotesSection(),
                        SizedBox(height: 80), // Extra space for the save button
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: _buildSaveButton(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  // Build save button with gradient style according to app design guidelines
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: _isSaving 
              ? [Colors.grey.shade400, Colors.grey.shade300]
              : [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
        ),
        child: _isSaving
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Save Changes',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'ProductSans',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
  
  Widget _buildJourneySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job ID field (disabled/read-only)
          _buildTextField(
            controller: _jobIdController,
            label: 'Job ID',
            prefixIcon: Icons.numbers,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildStationSearchField(
            controller: _originController,
            label: 'Origin Station Code',
            prefixIcon: Icons.train,
            isOrigin: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter origin station code';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildStationSearchField(
            controller: _destinationController,
            label: 'Destination Station Code',
            prefixIcon: Icons.location_on,
            isOrigin: false,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter destination station code';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildDateField(
            controller: _journeyDateController,
            label: 'Journey Date',
            prefixIcon: Icons.calendar_today,
          ),
          const SizedBox(height: 16),
          _buildTimeField(
            controller: _bookingTimeController,
            label: 'Booking Time',
            prefixIcon: Icons.access_time,
          ),
          const SizedBox(height: 16),
          _buildTravelClassDropdown(),
        ],
      ),
    );
  }
  
  // Build travel class dropdown with available train classes
  Widget _buildTravelClassDropdown() {
    // List of available train classes based on Indian Railways
    final List<Map<String, String>> travelClasses = [
      {'code': 'SL', 'name': 'Sleeper Class (SL)'},
      {'code': '3A', 'name': 'AC 3 Tier (3A)'},
      {'code': '2A', 'name': 'AC 2 Tier (2A)'},
      {'code': '1A', 'name': 'AC First Class (1A)'},
      {'code': 'CC', 'name': 'AC Chair Car (CC)'},
      {'code': '2S', 'name': 'Second Sitting (2S)'},
      {'code': 'EC', 'name': 'Executive Class (EC)'},
      {'code': 'FC', 'name': 'First Class (FC)'},
      {'code': '3E', 'name': 'AC 3 Tier Economy (3E)'},
      {'code': 'GN', 'name': 'General (GN)'}
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFD1D5DB)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.airline_seat_recline_normal, color: Color(0xFF6B7280)),
          SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedTravelClass,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Travel Class',
                  contentPadding: EdgeInsets.zero,
                ),
                items: travelClasses.map((Map<String, String> classItem) {
                  return DropdownMenuItem<String>(
                    value: classItem['code'],
                    child: Text(classItem['name']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTravelClass = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a travel class';
                  }
                  return null;
                },
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
                dropdownColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildJobSchedulingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When should the system execute this job?',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          // Job Date Field with enhanced validation
          _buildDateField(
            controller: _jobDateController,
            label: 'Job Date',
            prefixIcon: Icons.calendar_today,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter job execution date';
              }
              // Validate date format (YYYY-MM-DD)
              try {
                final parts = value.split('-');
                if (parts.length != 3 || parts[0].length != 4 || parts[1].length != 2 || parts[2].length != 2) {
                  return 'Please use YYYY-MM-DD format';
                }
                // Validate that it's a valid date
                DateTime.parse(value);
              } catch (e) {
                return 'Please enter a valid date in YYYY-MM-DD format';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Job Execution Time Field with enhanced validation
          _buildTimeField(
            controller: _jobExecutionTimeController,
            label: 'Job Execution Time',
            prefixIcon: Icons.access_time,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter job execution time';
              }
              // Validate time format (HH:MM)
              final pattern = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
              if (!pattern.hasMatch(value)) {
                return 'Please enter a valid time in HH:MM format';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
      
  
  Widget _buildJobConfigSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Auto Upgrade',
            subtitle: 'Automatically upgrade to higher class if available',
            value: _autoUpgrade,
            onChanged: (value) {
              setState(() {
                _autoUpgrade = value;
              });
            },
          ),
          Divider(),
          _buildSwitchTile(
            title: 'Auto Book Alternate Date',
            subtitle: 'Book on alternate date if seats not available',
            value: _autoBookAlternateDate,
            onChanged: (value) {
              setState(() {
                _autoBookAlternateDate = value;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: _buildTextField(
        controller: _notesController,
        label: 'Additional Notes',
        prefixIcon: Icons.note,
        maxLines: 3,
      ),
    );
  }
  
  Widget _buildSavedPassengersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tap to add passenger',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (!_isLoadingSavedPassengers)
                  IconButton(
                    icon: Icon(Icons.refresh, color: Color(0xFF7C3AED)),
                    onPressed: _loadSavedPassengers,
                    tooltip: 'Refresh saved passengers',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    splashRadius: 20,
                  ),
              ],
            ),
          ),
          _isLoadingSavedPassengers
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                        color: Color(0xFF7C3AED)),
                  ),
                )
              : _savedPassengers.isEmpty
                  ? Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.0),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'No saved passengers found',
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
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, index) {
                          final passenger = _savedPassengers[index];
                          // Check if this passenger is already used
                          final idNumber = passenger['id_number'] ?? '';
                          final isUsed = _usedSavedPassengers.containsKey(idNumber) &&
                              _usedSavedPassengers[idNumber] == true;

                          return GestureDetector(
                            // Only allow tapping if the passenger is not already used
                            onTap: isUsed ? null : () => _useSavedPassenger(passenger),
                            child: Container(
                              width: 200,
                              margin: EdgeInsets.symmetric(
                                  horizontal: 4.0, vertical: 4.0),
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                // Gray out the card if already used
                                color: isUsed ? Color(0xFFF7F7FA) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isUsed
                                        ? Color(0xFFD1D5DB)
                                        : Color(0xFFE5E7EB)),
                                boxShadow: isUsed
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isUsed ? 'Already used' : 'Tap to use',
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
    );
  }
  
  // Map to track expanded state of each passenger accordion
  final Map<int, bool> _customTileExpanded = {};
  
  // Helper method to build passenger detail item with full width
  Widget _buildPassengerDetailItem(String label, dynamic value) {
    final displayValue = value?.toString() ?? 'Not specified';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: const TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 14,
              color: Color(0xFF222222),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Individual Passenger Accordions
        _passengers.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      'No passengers added yet',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _passengers.length,
                itemBuilder: (context, index) {
                  final passenger = _passengers[index];
                  // Initialize expansion state if not already set
                  _customTileExpanded.putIfAbsent(index, () => false);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          childrenPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                          collapsedBackgroundColor: Colors.white,
                          title: Row(
                            children: [
                              Text(
                                'Passenger ${index + 1}',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7C3AED),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  // Remove passenger
                                  setState(() {
                                    _passengers.removeAt(index);
                                  });
                                },
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                _customTileExpanded[index] == true
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Color(0xFF7C3AED),
                              ),
                            ],
                          ),
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _customTileExpanded[index] = expanded;
                            });
                          },
                          initiallyExpanded: _customTileExpanded[index] ?? false,
                          children: [
                            // Passenger details
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildPassengerDetailItem('Name', passenger['name']),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildPassengerDetailItem('Age', passenger['age']),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildPassengerDetailItem('Gender', passenger['gender']),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildPassengerDetailItem('ID Type', passenger['id_type']),
                                  const SizedBox(height: 8),
                                  _buildPassengerDetailItem('ID Number', passenger['id_number']),
                                  if (passenger['berth_preference'] != null) ...[
                                    const SizedBox(height: 8),
                                    _buildPassengerDetailItem('Berth Preference', passenger['berth_preference']),
                                  ],
                                  if (passenger['is_senior_citizen'] != null) ...[
                                    const SizedBox(height: 8),
                                    _buildPassengerDetailItem('Senior Citizen', passenger['is_senior_citizen'] ? 'Yes' : 'No'),
                                  ],
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
        
        // Add Passenger Button
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () {
              _showAddPassengerDialog(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: Row(
                children: [
                  Icon(Icons.add, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text(
                    'Add Passenger',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAdditionalPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Travel Insurance
          _buildSwitchTile(
            title: 'Travel Insurance',
            subtitle: 'Opt for travel insurance for all passengers',
            value: _optForInsurance,
            onChanged: (value) {
              setState(() {
                _optForInsurance = value;
                _showTravelInsurance = value;
              });
            },
          ),
          
          // GST Details
          Divider(),
          _buildSwitchTile(
            title: 'GST Details',
            subtitle: 'Add GST details for invoice',
            value: _showGstDetails,
            onChanged: (value) {
              setState(() {
                _showGstDetails = value;
              });
            },
          ),
          
          // GST Fields
          if (_showGstDetails) ...[  
            SizedBox(height: 16),
            _buildTextField(
              controller: _gstNumberController,
              label: 'GST Number',
              prefixIcon: Icons.receipt,
              validator: (value) {
                if (_showGstDetails && (value == null || value.isEmpty)) {
                  return 'Please enter GST number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _gstCompanyNameController,
              label: 'Company Name',
              prefixIcon: Icons.business,
              validator: (value) {
                if (_showGstDetails && (value == null || value.isEmpty)) {
                  return 'Please enter company name';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF7C3AED),
            activeTrackColor: Color(0xFFE9D5FF),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Debug log the values being sent
        print('Saving job with job_date: ${_jobDateController.text}');
        print('Saving job with job_execution_time: ${_jobExecutionTimeController.text}');
        
        // Validate job_date format (YYYY-MM-DD)
        if (_jobDateController.text.isNotEmpty) {
          try {
            final parts = _jobDateController.text.split('-');
            if (parts.length != 3 || parts[0].length != 4 || parts[1].length != 2 || parts[2].length != 2) {
              throw FormatException('Invalid date format');
            }
            // Validate that it's a valid date
            DateTime.parse(_jobDateController.text);
          } catch (e) {
            throw Exception('Invalid job date format. Please use YYYY-MM-DD format.');
          }
        }
        
        // Validate job_execution_time format (HH:MM)
        if (_jobExecutionTimeController.text.isNotEmpty) {
          try {
            final parts = _jobExecutionTimeController.text.split(':');
            if (parts.length != 2 || int.parse(parts[0]) > 23 || int.parse(parts[1]) > 59) {
              throw FormatException('Invalid time format');
            }
          } catch (e) {
            throw Exception('Invalid job execution time format. Please use HH:MM format.');
          }
        }
        
        // Prepare job data
        final Map<String, dynamic> jobData = {
          'id': widget.jobId,  // Include job ID in the update data
          'origin_station_code': _originController.text,
          'destination_station_code': _destinationController.text,
          'journey_date': _journeyDateController.text,
          'booking_time': _bookingTimeController.text,
          'travel_class': _selectedTravelClass,
          'booking_email': _emailController.text,
          'booking_phone': _phoneController.text,
          'notes': _notesController.text,
          'passengers': _passengers,
          'auto_upgrade': _autoUpgrade,
          'auto_book_alternate_date': _autoBookAlternateDate,
          'job_date': _jobDateController.text,
          'job_execution_time': _jobExecutionTimeController.text,
          'payment_method': widget.jobData['payment_method'], // Preserve existing payment method
        };

        // Add optional fields if enabled
        if (_showGstDetails) {
          jobData['gst_number'] = _gstNumberController.text;
          jobData['gst_company_name'] = _gstCompanyNameController.text;
        }

        if (_optForInsurance) {
          jobData['opt_for_insurance'] = true;
        }

        // Check if this is a failed job that needs to be reset
        final currentStatus = widget.jobData['job_status']?.toString().toLowerCase() ?? 
                            widget.jobData['status']?.toString().toLowerCase() ?? '';
      
        if (currentStatus.contains('fail')) {
          // Reset job status to Scheduled when editing a failed job
          // The backend will handle clearing the failure-related fields
          jobData['job_status'] = 'Scheduled';
          
          print('Setting failed job status to Scheduled - backend will reset failure fields');
        }

        // Call API to update job using the map-based update method
        final response = await _jobService.updateJob(
          jobId: widget.jobId,
          updateData: jobData,
        );

        if (response['success'] == true) {
          // Show success animation dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return SuccessAnimationDialog(
                message: 'Job updated successfully',
                onAnimationComplete: () {
                  // Navigate back after animation completes
                  Navigator.pop(context, true);
                },
              );
            },
          );
        } else {
          // Show failure animation dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return FailureAnimationDialog(
                message: response['message'] ?? 'Failed to update job',
                onAnimationComplete: () {},
              );
            },
          );
        }
      } catch (e) {
        // Show failure animation dialog with error message
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return FailureAnimationDialog(
              message: 'Error: ${e.toString()}',
              onAnimationComplete: () {},
            );
          },
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
      // Show validation error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showAddPassengerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String selectedGender = 'Male';
    String selectedIdType = 'Aadhar';
    String selectedBerthPreference = 'No Preference';
    bool isSeniorCitizen = false;
    bool addToPassengerList = true; // Default to checked
    final idNumberController = TextEditingController();
    
    final formKey = GlobalKey<FormState>();
    
    // Get SharedPreferences instance
    SharedPreferences? prefs;
    
    // Use Navigator to push a full-screen modal instead of dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF7C3AED),
            elevation: 0,
            title: const Padding(
              padding: EdgeInsets.only(top: 50.0), // 50px top padding as per design guidelines
              child: Text(
                'Add Passenger',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(top: 50.0), // Match the title padding
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            toolbarHeight: 100, // Increased height for better visual appeal
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                height: 20,
              ),
            ),
          ),
          body: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Section title
                    const Text(
                      'Passenger Details',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Name field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Full Name',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF7F7FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter full name',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            style : TextStyle(
                            color: Colors.black,  
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter passenger name';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Age field
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  'Age',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF7F7FA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextFormField(
                                  controller: ageController,
                                  decoration: InputDecoration(
                                    hintText: 'Age',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  style : TextStyle(
                                    color: Colors.black,  
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter age';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        // ID Type field will be added in the next update
                        Expanded(
                          child: Container(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Gender and ID Type row
                    Row(
                      children: [
                        // Gender dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  'Gender',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF7F7FA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: selectedGender,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  dropdownColor: Colors.white,
                                  items: ['Male', 'Female', 'Other']
                                      .map((gender) => DropdownMenuItem(
                                            value: gender,
                                            child: Text(gender),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    selectedGender = value!;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        // ID Type dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  'ID Type',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF7F7FA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: selectedIdType,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  dropdownColor: Colors.white,
                                  items: ['Aadhar', 'PAN', 'Passport', 'Driving License']
                                      .map((idType) => DropdownMenuItem(
                                            value: idType,
                                            child: Text(idType),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    selectedIdType = value!;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // ID Number field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'ID Number',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF7F7FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextFormField(
                            controller: idNumberController,
                            decoration: InputDecoration(
                              hintText: 'Enter ID number',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            style : TextStyle(
                              color: Colors.black,  
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter ID number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Senior citizen checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: isSeniorCitizen,
                          onChanged: (value) {
                            setState(() {
                              isSeniorCitizen = value ?? false;
                            });
                          },
                          activeColor: Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          'Senior Citizen (60+)',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                                        // Add to passenger list checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: addToPassengerList, // Use the state variable
                          onChanged: (value) {
                            setState(() {
                              addToPassengerList = value ?? false;
                            });
                          },
                          activeColor: Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Add to Passenger List - For Tatkal Mode',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final passenger = {
                          'name': nameController.text,
                          'age': int.tryParse(ageController.text) ?? 0,
                          'gender': selectedGender,
                          'id_type': selectedIdType,
                          'id_number': idNumberController.text,
                          'berth_preference': selectedBerthPreference,
                          'is_senior_citizen': isSeniorCitizen || (int.tryParse(ageController.text) ?? 0) >= 60,
                          'carriage': '-', // Placeholder
                          'seat': '-', // Placeholder
                        };
                        
                        // Save to passenger list if checkbox is checked
                        if (addToPassengerList) {
                          try {
                            // Show loading indicator
                            _showCustomSnackBar(
                              message: 'Saving passenger to your list...',
                              icon: Icons.save,
                              backgroundColor: Color(0xFF7C3AED),
                            );
                            
                            // Get user ID from shared preferences
                            prefs ??= await SharedPreferences.getInstance();
                            String userId = '';
                            final userProfileJson = prefs!.getString('user_profile');
                            if (userProfileJson != null && userProfileJson.isNotEmpty) {
                              try {
                                final userProfile = jsonDecode(userProfileJson);
                                userId = userProfile['UserID'] ?? '';
                              } catch (e) {
                                print('Error parsing user profile: $e');
                              }
                            }
                            
                            if (userId.isNotEmpty) {
                              final passengerToSave = {
                                ...passenger,
                                'user_id': userId,
                              };
                              
                              // Save passenger to database
                              final baseUrl = ApiConstants.baseUrl;
                              final response = await http.post(
                                Uri.parse('$baseUrl/api/v1/passengers'),
                                headers: {
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode(passengerToSave),
                              );
                              
                              if (response.statusCode >= 200 && response.statusCode < 300) {
                                // Show success message
                                _showCustomSnackBar(
                                  message: 'Passenger saved to your list!',
                                  icon: Icons.check_circle,
                                  backgroundColor: Colors.green,
                                );
                              } else {
                                print('Failed to save passenger: ${response.statusCode} - ${response.body}');
                              }
                            }
                          } catch (e) {
                            print('Error saving passenger: $e');
                            _showCustomSnackBar(
                              message: 'Failed to save passenger to your list',
                              icon: Icons.error_outline,
                              backgroundColor: Colors.red,
                            );
                          }
                        }
                        
                        setState(() {
                          _passengers.add(passenger);
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Add Passenger',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
  
  // Helper method to build station search fields that open city search screen
  Widget _buildStationSearchField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required bool isOrigin,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true, // Always read-only as we'll open search screen
      style: const TextStyle(
        color: Colors.black, // Make input text black
        fontFamily: 'ProductSans',
        fontSize: 16,
      ),
      onTap: () async {
        // Navigate to city search screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CitySearchScreen(
              searchType: 'station',
              isOrigin: isOrigin,
              sourceScreen: 'job_edit',
            ),
          ),
        );
        
        // Handle the selected city/station
        if (result != null && result is Map<String, dynamic>) {
          setState(() {
            // Display the station name instead of just the code
            String stationName = result['station_name'] ?? '';
            String stationCode = result['station_code'] ?? '';
            controller.text = stationCode.isNotEmpty ? "$stationName ($stationCode)" : '';
          });
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: controller.text.isEmpty ? Colors.grey.shade500 : Colors.grey.shade700),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF7C3AED)),
        suffixIcon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        // Make hint text darker
        hintStyle: const TextStyle(color: Colors.black87),
      ),
      validator: validator,
    );
  }
  
  // Helper method to build text fields with consistent styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Color(0xFF7C3AED)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(
        fontFamily: 'ProductSans',
        fontSize: 16,
        color: Color(0xFF111827),
      ),
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
    );
  }

  // Helper method to build date fields with date picker
  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return _buildTextField(
      controller: controller,
      label: label,
      prefixIcon: prefixIcon,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a date';
        }
        return null;
      },
      readOnly: true,
      onTap: () async {
        // Get current date for comparison and defaults
        final now = DateTime.now();
        DateTime initialDate;
        
        try {
          // Try to parse the existing date, if any
          if (controller.text.isNotEmpty) {
            initialDate = DateFormat('yyyy-MM-dd').parse(controller.text);
            // Ensure initialDate is not before firstDate
            if (initialDate.isBefore(now)) {
              initialDate = now;
            }
          } else {
            initialDate = now;
          }
        } catch (e) {
          // If parsing fails, use current date
          initialDate = now;
        }
        
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: now,
          lastDate: now.add(Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF7C3AED),
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF111827),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF7C3AED),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      },
    );
  }

  // Custom SnackBar to show messages with icons
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

  // Helper method to build time fields with time picker
  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return _buildTextField(
      controller: controller,
      label: label,
      prefixIcon: prefixIcon,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a time';
        }
        return null;
      },
      readOnly: true,
      onTap: () async {
        TimeOfDay initialTime;
        
        try {
          // Try to parse the existing time, if any
          if (controller.text.isNotEmpty) {
            // Handle different time formats
            if (controller.text.contains('AM') || controller.text.contains('PM')) {
              initialTime = TimeOfDay.fromDateTime(DateFormat('hh:mm a').parse(controller.text));
            } else {
              // Assume 24-hour format
              final timeParts = controller.text.split(':');
              initialTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
            }
          } else {
            initialTime = TimeOfDay.now();
          }
        } catch (e) {
          // If parsing fails, use current time
          initialTime = TimeOfDay.now();
        }
        
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF7C3AED),
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF111827),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF7C3AED),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          final now = DateTime.now();
          final dateTime = DateTime(
            now.year,
            now.month,
            now.day,
            picked.hour,
            picked.minute,
          );
          // Format as 24-hour time (HH:MM)
          controller.text = DateFormat('HH:mm').format(dateTime);
        }
      },
    );
  }
}