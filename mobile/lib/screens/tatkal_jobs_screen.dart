import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tatkal_mode_screen.dart';

class TatkalJobsScreen extends StatefulWidget {
  const TatkalJobsScreen({Key? key}) : super(key: key);

  @override
  State<TatkalJobsScreen> createState() => _TatkalJobsScreenState();
}

class _TatkalJobsScreenState extends State<TatkalJobsScreen> {
  // Static list of tatkal jobs for display
  final List<Map<String, dynamic>> _tatkalJobs = [
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

  // Filter options
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Scheduled', 'In Progress', 'Completed', 'Failed'];

  // Get filtered jobs based on selected filter
  List<Map<String, dynamic>> get _filteredJobs {
    if (_selectedFilter == 'All') {
      return _tatkalJobs;
    } else {
      return _tatkalJobs.where((job) => job['status'] == _selectedFilter).toList();
    }
  }

  // Get color for job status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Format date
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Format datetime
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
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
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              // Show help dialog
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: Column(
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
                          color: isSelected ? Colors.white : Color(0xFF7C3AED),
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TatkalModeScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text(
              'Create New Job',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final statusColor = _getStatusColor(job['status']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    job['id'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontFamily: 'ProductSans',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                        job['status'],
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
                            job['origin'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                              fontFamily: 'ProductSans',
                            ),
                          ),
                          Text(
                            job['originName'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'ProductSans',
                            ),
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
                            job['destination'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                              fontFamily: 'ProductSans',
                            ),
                          ),
                          Text(
                            job['destinationName'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'ProductSans',
                            ),
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
                    _buildDetailItem(Icons.calendar_today, _formatDate(job['date'])),
                    _buildDetailItem(Icons.access_time, job['time']),
                    _buildDetailItem(Icons.airline_seat_recline_normal, job['class']),
                    _buildDetailItem(Icons.people, '${job['passengers']} Pax'),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Created at
                Text(
                  'Created: ${_formatDateTime(job['createdAt'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'ProductSans',
                  ),
                ),
                
                // Status-specific information
                if (job['status'] == 'Completed') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Completed: ${_formatDateTime(job['completedAt'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'ProductSans',
                    ),
                  ),
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
                                'Booking ID: ${job['bookingId']}',
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
                                'PNR: ${job['pnr']}',
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
                
                if (job['status'] == 'Failed') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Failed: ${_formatDateTime(job['failedAt'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'ProductSans',
                    ),
                  ),
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
                            job['failureReason'],
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
                if (job['status'] == 'Scheduled' || job['status'] == 'In Progress') ...[
                  TextButton.icon(
                    onPressed: () {
                      // Cancel job
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
                
                if (job['status'] == 'Scheduled') ...[
                  TextButton.icon(
                    onPressed: () {
                      // Edit job
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
                
                if (job['status'] == 'Completed') ...[
                  TextButton.icon(
                    onPressed: () {
                      // View booking
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Booking'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      textStyle: const TextStyle(
                        fontFamily: 'ProductSans',
                      ),
                    ),
                  ),
                ],
                
                if (job['status'] == 'Failed') ...[
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
