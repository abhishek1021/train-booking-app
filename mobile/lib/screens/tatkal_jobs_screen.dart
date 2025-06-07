import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'booking_details_screen.dart';
import 'tatkal_mode_screen.dart';
import 'job_logs_screen.dart';
import 'job_details_screen.dart';
import 'job_edit_screen.dart';
import '../services/job_service.dart';

class TatkalJobsScreen extends StatefulWidget {
  const TatkalJobsScreen({Key? key}) : super(key: key);

  @override
  State<TatkalJobsScreen> createState() => _TatkalJobsScreenState();
}

class _TatkalJobsScreenState extends State<TatkalJobsScreen> {
  final JobService _jobService = JobService();
  List<Map<String, dynamic>> _tatkalJobs = [];
  bool _isLoading = true;
  String _userId = '';
  String _errorMessage = '';

  // Example jobs for fallback if API fails
  final List<Map<String, dynamic>> _exampleJobs = [
    {
      'id': 'TKL-A7B9C3D2',
      'status': 'Scheduled',
      'origin': 'NDLS',
      'originName': 'New Delhi',
      'destination': 'CSTM',
      'destinationName': 'Mumbai CST',
      'date': '2025-06-15',
      'time': '10:00 AM',
      'class': 'SL',
      'passengers': 2,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': 'TKL-X5Y7Z9W1',
      'status': 'In Progress',
      'origin': 'HWH',
      'originName': 'Howrah',
      'destination': 'MAS',
      'destinationName': 'Chennai Central',
      'date': '2025-06-10',
      'time': '08:30 AM',
      'class': '3A',
      'passengers': 1,
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'id': 'TKL-P4Q6R8S0',
      'status': 'Completed',
      'origin': 'PUNE',
      'originName': 'Pune Junction',
      'destination': 'BZA',
      'destinationName': 'Vijayawada',
      'date': '2025-06-05',
      'time': '11:45 AM',
      'class': '2A',
      'passengers': 3,
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      'completedAt': DateTime.now().subtract(const Duration(days: 4)),
      'bookingId': 'BK-78901234',
      'pnr': 'PNR2505123456',
    },
    {
      'id': 'TKL-E2F4G6H8',
      'status': 'Failed',
      'origin': 'NDLS',
      'originName': 'New Delhi',
      'destination': 'LKO',
      'destinationName': 'Lucknow',
      'date': '2025-06-02',
      'time': '06:15 AM',
      'class': 'SL',
      'passengers': 2,
      'createdAt': DateTime.now().subtract(const Duration(days: 7)),
      'failedAt': DateTime.now().subtract(const Duration(days: 6)),
      'failureReason': 'No seats available in the requested class',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserIdAndJobs();
  }

  // Load user ID and then fetch jobs
  Future<void> _loadUserIdAndJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileString = prefs.getString('user_profile');

      if (userProfileString != null && userProfileString.isNotEmpty) {
        final userData = json.decode(userProfileString) as Map<String, dynamic>;
        _userId = userData['UserID'] ?? '';

        if (_userId.isNotEmpty) {
          await _fetchJobs();
        } else {
          setState(() {
            _errorMessage = 'User ID not found. Please log in again.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'User profile not found. Please log in again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }

  // Fetch jobs from API
  Future<void> _fetchJobs() async {
    try {
      final jobs = await _jobService.getUserJobs(userId: _userId);
      setState(() {
        _tatkalJobs = jobs;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      print('Error fetching jobs: $e');
      setState(() {
        _errorMessage = 'Failed to load jobs. Please try again.';
        _isLoading = false;
        // Use example jobs as fallback if needed
        if (_tatkalJobs.isEmpty) {
          _tatkalJobs = _exampleJobs;
        }
      });
    }
  }

  // Refresh jobs
  Future<void> _refreshJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await _fetchJobs();
  }

  // Filter options
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Scheduled',
    'In Progress',
    'Completed',
    'Failed'
  ];

  // Get filtered jobs based on selected filter
  List<Map<String, dynamic>> get _filteredJobs {
    if (_selectedFilter == 'All') {
      return _tatkalJobs;
    } else {
      return _tatkalJobs
          .where((job) => job['status'] == _selectedFilter)
          .toList();
    }
  }

  // Get color based on job status with null safety
  Color _getStatusColor(String? status) {
    if (status == null) {
      return Colors.grey;
    }

    // Normalize status to handle case variations
    final normalizedStatus = status.toLowerCase();

    if (normalizedStatus.contains('schedule')) {
      return Colors.blue;
    } else if (normalizedStatus.contains('progress') ||
        normalizedStatus.contains('in-progress')) {
      return Colors.orange;
    } else if (normalizedStatus.contains('complete')) {
      return Colors.green;
    } else if (normalizedStatus.contains('fail')) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  // Format date with null safety
  String _formatDate(String dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'N/A') {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      // Handle invalid date format
      return dateString;
    }
  }

  // Format datetime with null safety
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/A';
    }
    return DateFormat('dd MMM yyyy, h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Tatkal Jobs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
          ),
        ),
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshJobs,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              // Show help dialog
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _refreshJobs,
                  color: const Color(0xFF7C3AED),
                  child: Column(
                    children: [
                      // Filter chips
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filterOptions.length,
                            itemBuilder: (context, index) {
                              final filter = _filterOptions[index];
                              final isSelected = filter == _selectedFilter;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Color(0xFF7C3AED),
                                      fontFamily: 'ProductSans',
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedFilter = filter;
                                    });
                                  },
                                  backgroundColor: Colors.grey[200],
                                  selectedColor: const Color(0xFF7C3AED),
                                  checkmarkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Jobs list
                      Expanded(
                        child: _filteredJobs.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredJobs.length,
                                itemBuilder: (context, index) {
                                  final job = _filteredJobs[index];
                                  return _buildJobCard(job);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TatkalModeScreen()),
          );
        },
        backgroundColor: const Color(0xFF7C3AED),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Tatkal Jobs Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontFamily: 'ProductSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new job to automate your Tatkal booking',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'ProductSans',
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 220,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TatkalModeScreen()),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create New Job',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Loading state widget
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your Tatkal jobs...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontFamily: 'ProductSans',
            ),
          ),
        ],
      ),
    );
  }

  // Error state widget
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontFamily: 'ProductSans',
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'ProductSans',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 180,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: _refreshJobs,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get job execution status label based on next execution time
  String _getJobExecutionStatus(Map<String, dynamic> job) {
    // If job is not scheduled, return empty string
    final String status =
        job['job_status']?.toString() ?? job['status']?.toString() ?? 'Unknown';
    if (status.toLowerCase() != 'scheduled') {
      return '';
    }

    // Try to parse next execution time
    DateTime? nextExecution;
    if (job['next_execution_time'] != null) {
      try {
        nextExecution = DateTime.parse(job['next_execution_time']);
      } catch (e) {
        // Handle parsing error
        return '';
      }
    } else {
      return '';
    }

    // Get current time
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextExecutionDate =
        DateTime(nextExecution.year, nextExecution.month, nextExecution.day);

    // Determine execution status
    if (nextExecutionDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (nextExecutionDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else {
      // Calculate days difference
      final difference = nextExecutionDate.difference(today).inDays;
      if (difference > 0) {
        return 'In $difference days';
      } else {
        return 'Pending';
      }
    }
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    // Extract job data with null safety
    final String jobId =
        job['job_id']?.toString() ?? job['id']?.toString() ?? 'Unknown ID';
    final String status =
        job['job_status']?.toString() ?? job['status']?.toString() ?? 'Unknown';

    // Station codes and names
    final String originCode = job['origin_station_code']?.toString() ??
        job['origin']?.toString() ??
        'N/A';
    final String destCode = job['destination_station_code']?.toString() ??
        job['destination']?.toString() ??
        'N/A';

    // For station names, use the station code as a fallback if name is null or empty
    String originName = job['origin_station_name']?.toString() ?? '';
    if (originName.isEmpty || originName == 'null') {
      originName = originCode;
    }

    String destName = job['destination_station_name']?.toString() ?? '';
    if (destName.isEmpty || destName == 'null') {
      destName = destCode;
    }

    final String journeyDate =
        job['journey_date']?.toString() ?? job['date']?.toString() ?? 'N/A';
    final String travelClass =
        job['travel_class']?.toString() ?? job['class']?.toString() ?? 'N/A';
    final String bookingTime =
        job['booking_time']?.toString() ?? job['time']?.toString() ?? 'N/A';

    // Get job execution status
    final String executionStatus = _getJobExecutionStatus(job);

    // Get passenger count
    int passengerCount = 0;
    if (job['passengers'] is List) {
      passengerCount = (job['passengers'] as List).length;
    } else if (job['passengers'] is int) {
      passengerCount = job['passengers'];
    }

    // Get created time
    DateTime? createdAt;
    if (job['created_at'] != null) {
      try {
        createdAt = DateTime.parse(job['created_at']);
      } catch (e) {
        // Handle parsing error
      }
    } else if (job['createdAt'] is DateTime) {
      createdAt = job['createdAt'];
    }

    // Get status color
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to job details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsScreen(jobId: jobId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with job ID and status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          jobId,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontFamily: 'ProductSans',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          // Removed top edit button as per requirements
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'ProductSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Show execution status if available
                  if (executionStatus.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Executes: $executionStatus',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ProductSans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Journey details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Origin to destination
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              originCode,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                                fontFamily: 'ProductSans',
                              ),
                            ),
                            // Only show origin name if it's different from code
                            if (originName != originCode)
                              Text(
                                originName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: 'ProductSans',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF7C3AED),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              destCode,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                                fontFamily: 'ProductSans',
                              ),
                            ),
                            // Only show destination name if it's different from code
                            if (destName != destCode)
                              Text(
                                destName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: 'ProductSans',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Journey date and other details
                  Row(
                    children: [
                      _buildDetailItem(
                          Icons.calendar_today, _formatDate(journeyDate)),
                      _buildDetailItem(Icons.access_time, bookingTime),
                      _buildDetailItem(
                          Icons.airline_seat_recline_normal, travelClass),
                      _buildDetailItem(Icons.people, '$passengerCount Pax'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Created at
                  Text(
                    'Created: ${createdAt != null ? _formatDateTime(createdAt) : 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'ProductSans',
                    ),
                  ),

                  // Status-specific information
                  if (status == 'Completed') ...[
                    const SizedBox(height: 8),

                    // Handle completed time

                    if (job['completed_at'] != null ||
                        job['completedAt'] != null) ...[
                      Text(
                        'Completed: ${job['completed_at'] != null ? _formatDateTime(DateTime.parse(job['completed_at'])) : job['completedAt'] is DateTime ? _formatDateTime(job['completedAt']) : 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Booking ID: ${job['booking_id']?.toString() ?? job['bookingId']?.toString() ?? 'N/A'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                    fontFamily: 'ProductSans',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'PNR: ${job['pnr']?.toString() ?? 'N/A'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                    fontFamily: 'ProductSans',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (status == 'Failed') ...[
                    const SizedBox(height: 8),

                    // Handle failed time

                    if (job['failed_at'] != null ||
                        job['failedAt'] != null) ...[
                      Text(
                        'Failed: ${job['failed_at'] != null ? _formatDateTime(DateTime.parse(job['failed_at'])) : job['failedAt'] is DateTime ? _formatDateTime(job['failedAt']) : 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[800],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              job['failure_reason']?.toString() ??
                                  job['failureReason']?.toString() ??
                                  'Unknown error',
                              style: TextStyle(
                                color: Colors.red[800],
                                fontFamily: 'ProductSans',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // View Logs button for all job statuses
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to job logs screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobLogsScreen(
                            jobId: jobId,
                            jobStatus: status,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('View Logs'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      textStyle: const TextStyle(
                        fontFamily: 'ProductSans',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  if (status == 'Scheduled' || status == 'In Progress') ...[
                    TextButton.icon(
                      onPressed: () {
                        // Cancel job
                        // TODO: Implement job cancellation
                      },
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        textStyle: const TextStyle(
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (status == 'Scheduled') ...[
                    TextButton.icon(
                      onPressed: () async {
                        // Navigate to edit screen
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobEditScreen(
                              jobId: jobId,
                              jobData: job,
                            ),
                          ),
                        );

                        // If changes were made, refresh the jobs list
                        if (result == true) {
                          _refreshJobs();
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        textStyle: const TextStyle(
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ),
                  ],
                  if (status == 'Completed' && job['booking_id'] != null) ...[
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to booking details screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailsScreen(
                              bookingId: job['booking_id'],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt, size: 18),
                      label: const Text('View Booking'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        textStyle: const TextStyle(
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ),
                  ],
                  if (status == 'Failed') ...[
                    TextButton.icon(
                      onPressed: () {
                        // Retry job
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        textStyle: const TextStyle(
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                fontFamily: 'ProductSans',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'About Tatkal Jobs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C3AED),
            fontFamily: 'ProductSans',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              'Scheduled',
              'Job is scheduled and waiting for the Tatkal booking window to open',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              'In Progress',
              'Job is currently running and attempting to book tickets',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              'Completed',
              'Job has successfully booked tickets',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              'Failed',
              'Job failed to book tickets',
              Colors.red,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontFamily: 'ProductSans',
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'ProductSans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'ProductSans',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
