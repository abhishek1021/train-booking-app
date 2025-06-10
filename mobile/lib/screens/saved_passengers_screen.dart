import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/passenger_service.dart';
import '../api_constants.dart';

class SavedPassengersScreen extends StatefulWidget {
  const SavedPassengersScreen({Key? key}) : super(key: key);

  @override
  _SavedPassengersScreenState createState() => _SavedPassengersScreenState();
}

class _SavedPassengersScreenState extends State<SavedPassengersScreen> {
  late PassengerService _passengerService;
  List<dynamic> _passengers = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePassengerService();
  }

  Future<void> _initializePassengerService() async {
    final prefs = await SharedPreferences.getInstance();
    _passengerService = PassengerService(prefs);
    _loadPassengers();
  }

  Future<void> _loadPassengers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final passengers = await _passengerService.getFavoritePassengers();
      setState(() {
        _passengers = passengers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load passengers: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC), // Slightly purple tinted background
      extendBody: true,
      body: Column(
        children: [
          // Header with purple gradient
          _buildHeader(),
          
          // Main content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Add new passenger
            _showAddEditPassengerDialog(context);
          },
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person_add, size: 26),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 48, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Small decorative circles
          Positioned(
            top: 20,
            right: 60,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 80,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          // Header content with improved layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.people, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Saved Passengers',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading passengers...',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontSize: 16,
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontFamily: 'ProductSans',
                  color: Colors.black54,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPassengers,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_passengers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPassengers,
      color: const Color(0xFF7C3AED),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _passengers.length,
        itemBuilder: (context, index) {
          final passenger = _passengers[index];
          return _buildPassengerCard(passenger);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                color: Color(0xFF7C3AED),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Passengers Yet',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Add your first passenger by tapping the button below',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddEditPassengerDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Passenger'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCard(dynamic passenger) {
    final name = passenger['name'] ?? 'Unknown';
    final age = passenger['age']?.toString() ?? '';
    final gender = passenger['gender'] ?? '';
    final idType = passenger['id_type'] ?? '';
    final idNumber = passenger['id_number'] ?? '';
    final isSenior = passenger['is_senior'] == true;
    final passengerId = passenger['id'] ?? passenger['_id'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Avatar with initials
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(name),
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name and gender/age
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$gender · $age years',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  elevation: 3,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddEditPassengerDialog(context, passenger: passenger);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(passengerId);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, color: Color(0xFF7C3AED), size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Edit Passenger',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Delete Passenger',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Passenger details
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID type and number in a card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            color: Color(0xFF7C3AED),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Identification',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('ID Type', idType),
                      const SizedBox(height: 12),
                      _buildDetailRow('ID Number', idNumber),
                    ],
                  ),
                ),
                
                // Senior citizen badge if applicable
                if (isSenior) ...[  
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Senior Citizen',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Empty state is implemented above

  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Value
        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 15,
              color: value.isEmpty ? Colors.black38 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    
    return '';
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(String passengerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Passenger'),
        content: const Text('Are you sure you want to delete this passenger? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deletePassenger(passengerId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Delete passenger
  Future<void> _deletePassenger(String passengerId) async {
    setState(() => _isLoading = true);
    
    try {
      await _passengerService.deleteFavoritePassenger(passengerId);
      _showCustomSnackBar(
        message: 'Passenger deleted successfully',
        icon: Icons.check_circle,
        backgroundColor: Colors.green,
      );
      _loadPassengers(); // Refresh the list
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to delete passenger: $e';
      });
      _showCustomSnackBar(
        message: 'Failed to delete passenger',
        icon: Icons.error,
        backgroundColor: Colors.redAccent,
      );
    }
  }

  // Show custom snackbar
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
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
      margin: const EdgeInsets.all(10),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  // Add new passenger
  Future<void> _addPassenger(Map<String, dynamic> passengerData) async {
    setState(() => _isLoading = true);
    
    try {
      await _passengerService.addFavoritePassenger(passengerData);
      _showCustomSnackBar(
        message: 'Passenger added successfully',
        icon: Icons.check_circle,
        backgroundColor: Colors.green,
      );
      _loadPassengers(); // Refresh the list
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to add passenger: $e';
      });
      _showCustomSnackBar(
        message: 'Failed to add passenger',
        icon: Icons.error,
        backgroundColor: Colors.redAccent,
      );
    }
  }
  
  // Update existing passenger
  Future<void> _updatePassenger(String passengerId, Map<String, dynamic> passengerData) async {
    setState(() => _isLoading = true);
    
    try {
      await _passengerService.updateFavoritePassenger(passengerId, passengerData);
      _showCustomSnackBar(
        message: 'Passenger updated successfully',
        icon: Icons.check_circle,
        backgroundColor: Colors.green,
      );
      _loadPassengers(); // Refresh the list
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to update passenger: $e';
      });
      _showCustomSnackBar(
        message: 'Failed to update passenger',
        icon: Icons.error,
        backgroundColor: Colors.redAccent,
      );
    }
  }
  
  // Show add/edit passenger dialog
  void _showAddEditPassengerDialog(BuildContext context, {dynamic passenger}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = passenger != null;
    
    // Form controllers
    final nameController = TextEditingController(text: passenger?['name'] ?? '');
    final ageController = TextEditingController(text: passenger?['age']?.toString() ?? '');
    String gender = passenger?['gender'] ?? 'Male';
    String idType = passenger?['id_type'] ?? 'Aadhar';
    final idNumberController = TextEditingController(text: passenger?['id_number'] ?? '');
    bool isSenior = passenger?['is_senior'] == true;
    final passengerId = passenger?['id'] ?? passenger?['_id'] ?? '';
    
    // Gender and ID type options
    final genderOptions = ['Male', 'Female', 'Other'];
    final idTypeOptions = ['Aadhar', 'PAN', 'Passport', 'Driving License', 'Voter ID'];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Passenger' : 'Add New Passenger',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name field
                        const Text(
                          'Full Name',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter full name',
                            hintStyle: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.black38,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF3EEFF),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                            ),
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7C3AED)),
                            suffixIcon: nameController.text.isNotEmpty ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.black45),
                              onPressed: () => nameController.clear(),
                            ) : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Age field
                        const Text(
                          'Age',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter age',
                            hintStyle: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.black38,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF3EEFF),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF7C3AED)),
                            suffixIcon: ageController.text.isNotEmpty ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.black45),
                              onPressed: () => ageController.clear(),
                            ) : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter age';
                            }
                            final age = int.tryParse(value);
                            if (age == null || age <= 0 || age > 120) {
                              return 'Please enter a valid age';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Gender dropdown
                        const Text(
                          'Gender',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EEFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: gender,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                              iconSize: 28,
                              elevation: 2,
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              dropdownColor: Colors.white,
                              items: genderOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      Icon(
                                        value == 'Male' ? Icons.male : 
                                        value == 'Female' ? Icons.female : 
                                        Icons.person,
                                        color: const Color(0xFF7C3AED),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(value),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  gender = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // ID Type dropdown
                        const Text(
                          'ID Type',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EEFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: idType,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7C3AED)),
                              iconSize: 28,
                              elevation: 2,
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              dropdownColor: Colors.white,
                              items: idTypeOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      Icon(
                                        value == 'Aadhar' ? Icons.badge_outlined : 
                                        value == 'PAN' ? Icons.article_outlined : 
                                        value == 'Passport' ? Icons.book_outlined : 
                                        value == 'Driving License' ? Icons.directions_car_outlined : 
                                        Icons.how_to_vote_outlined,
                                        color: const Color(0xFF7C3AED),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(value),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  idType = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // ID Number field
                        const Text(
                          'ID Number',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: idNumberController,
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter ID number',
                            hintStyle: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.black38,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF3EEFF),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                            ),
                            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF7C3AED)),
                            suffixIcon: idNumberController.text.isNotEmpty ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.black45),
                              onPressed: () => idNumberController.clear(),
                            ) : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter ID number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Senior citizen checkbox
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EEFF),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.05),
                                blurRadius: 4,
                                spreadRadius: 0,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: isSenior,
                                  activeColor: const Color(0xFF7C3AED),
                                  checkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  side: BorderSide(
                                    color: const Color(0xFF7C3AED).withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      isSenior = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.elderly_outlined,
                                    color: Color(0xFF7C3AED),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Senior Citizen',
                                    style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
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
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF7C3AED),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            
                            setState(() {
                              _isLoading = true;
                              _hasError = false;
                              _errorMessage = '';
                            });
                            
                            try {
                              final Map<String, dynamic> passengerData = {
                                'name': nameController.text,
                                'age': int.parse(ageController.text),
                                'gender': gender,
                                'id_type': idType,
                                'id_number': idNumberController.text,
                                'is_senior': isSenior,
                              };
                              
                              if (isEditing) {
                                // Update existing passenger
                                // Since there's no direct update method, we'll delete and re-add
                                await _passengerService.deleteFavoritePassenger(passengerId);
                                await _passengerService.addFavoritePassenger(passengerData);
                              } else {
                                // Add new passenger
                                await _passengerService.addFavoritePassenger(passengerData);
                              }
                              
                              // Reload passengers list
                              _loadPassengers();
                            } catch (e) {
                              setState(() {
                                _hasError = true;
                                _errorMessage = 'Error: ${e.toString()}';
                              });
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        icon: Icon(
                          isEditing ? Icons.check : Icons.save_outlined,
                          size: 18,
                        ),
                        label: Text(
                          isEditing ? 'Update' : 'Save',
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: const Color(0xFF7C3AED).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
