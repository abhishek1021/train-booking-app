import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/job_service.dart';
import '../services/passenger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late TextEditingController _originController;
  late TextEditingController _destinationController;
  late TextEditingController _journeyDateController;
  late TextEditingController _bookingTimeController;
  late TextEditingController _travelClassController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  
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
    
    _originController = TextEditingController(text: jobData['origin'] ?? '');
    _destinationController = TextEditingController(text: jobData['destination'] ?? '');
    _journeyDateController = TextEditingController(text: jobData['journey_date'] ?? '');
    _bookingTimeController = TextEditingController(text: jobData['booking_time'] ?? '');
    _travelClassController = TextEditingController(text: jobData['travel_class'] ?? '');
    _emailController = TextEditingController(text: jobData['email'] ?? '');
    _phoneController = TextEditingController(text: jobData['phone'] ?? '');
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
    _originController.dispose();
    _destinationController.dispose();
    _journeyDateController.dispose();
    _bookingTimeController.dispose();
    _travelClassController.dispose();
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
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7C3AED),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size(double.infinity, 52),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
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
                    ),
                  ),
                ],
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
          _buildTextField(
            controller: _originController,
            label: 'Origin Station Code',
            prefixIcon: Icons.train,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter origin station code';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _destinationController,
            label: 'Destination Station Code',
            prefixIcon: Icons.location_on,
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
          _buildTextField(
            controller: _travelClassController,
            label: 'Travel Class',
            prefixIcon: Icons.airline_seat_recline_normal,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter travel class';
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
  
  Widget _buildPassengersSection() {
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
          // Add passenger button
          InkWell(
            onTap: () {
              // Show dialog to add passenger
              _showAddPassengerDialog(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFE9D5FF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text(
                    'Add Passenger',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Passengers list
          _passengers.isEmpty
              ? Container(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7F7FA),
                    borderRadius: BorderRadius.circular(12),
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
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _passengers.length,
                  itemBuilder: (context, index) {
                    final passenger = _passengers[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                passenger['name'] ?? '',
                                style: TextStyle(
                                  fontFamily: 'ProductSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removePassenger(index),
                                tooltip: 'Remove passenger',
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                splashRadius: 20,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Age: ${passenger['age'] ?? ''}',
                                      style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Gender: ${passenger['gender'] ?? ''}',
                                      style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID Type: ${passenger['id_type'] ?? ''}',
                                      style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'ID Number: ${passenger['id_number'] ?? ''}',
                                      style: TextStyle(
                                        fontFamily: 'ProductSans',
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
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
        // Prepare job data
        final Map<String, dynamic> jobData = {
          'id': widget.jobId,
          'origin': _originController.text,
          'destination': _destinationController.text,
          'journey_date': _journeyDateController.text,
          'booking_time': _bookingTimeController.text,
          'travel_class': _travelClassController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'notes': _notesController.text,
          'passengers': _passengers,
          'auto_upgrade': _autoUpgrade,
          'auto_book_alternate_date': _autoBookAlternateDate,
        };

        // Add optional fields if enabled
        if (_showGstDetails) {
          jobData['gst_number'] = _gstNumberController.text;
          jobData['gst_company_name'] = _gstCompanyNameController.text;
        }

        if (_optForInsurance) {
          jobData['opt_for_insurance'] = true;
        }

        // Call API to update job
        final response = await _jobService.updateJob(
          jobId: widget.jobId,
          originStationCode: _originController.text,
          destinationStationCode: _destinationController.text,
          journeyDate: _journeyDateController.text,
          bookingTime: _bookingTimeController.text,
          travelClass: _travelClassController.text,
          bookingEmail: _emailController.text,
          bookingPhone: _phoneController.text,
          notes: _notesController.text,
          passengers: _passengers,
          autoUpgrade: _autoUpgrade,
          autoBookAlternateDate: _autoBookAlternateDate,
        );

        if (response['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back
          Navigator.pop(context, true);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to update job'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
    final idNumberController = TextEditingController();
    
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Passenger',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person, color: Color(0xFF7C3AED)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF7C3AED)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter passenger name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                // Age field
                TextFormField(
                  controller: ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake, color: Color(0xFF7C3AED)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF7C3AED)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter passenger age';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                // Gender dropdown
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.people, color: Color(0xFF7C3AED)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF7C3AED)),
                    ),
                  ),
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
                SizedBox(height: 16),
                
                // ID Type dropdown
                DropdownButtonFormField<String>(
                  value: selectedIdType,
                  decoration: InputDecoration(
                    labelText: 'ID Type',
                    prefixIcon: Icon(Icons.badge, color: Color(0xFF7C3AED)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF7C3AED)),
                    ),
                  ),
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
                SizedBox(height: 16),
                
                // ID Number field
                TextFormField(
                  controller: idNumberController,
                  decoration: InputDecoration(
                    labelText: 'ID Number',
                    prefixIcon: Icon(Icons.credit_card, color: Color(0xFF7C3AED)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF7C3AED)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter ID number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final passenger = {
                  'name': nameController.text,
                  'age': ageController.text,
                  'gender': selectedGender,
                  'id_type': selectedIdType,
                  'id_number': idNumberController.text,
                };
                
                setState(() {
                  _passengers.add(passenger);
                });
                
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Add',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
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
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: controller.text.isNotEmpty
              ? DateFormat('yyyy-MM-dd').parse(controller.text)
              : DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 365)),
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
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: controller.text.isNotEmpty
              ? TimeOfDay.fromDateTime(
                  DateFormat.jm().parse(controller.text),
                )
              : TimeOfDay.now(),
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
          controller.text = DateFormat('hh:mm a').format(dateTime);
        }
      },
    );
  }
}