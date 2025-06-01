import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/job_logs_service.dart';

class JobLogsScreen extends StatefulWidget {
  final String jobId;
  final String jobStatus;

  const JobLogsScreen({
    Key? key,
    required this.jobId,
    required this.jobStatus,
  }) : super(key: key);

  @override
  State<JobLogsScreen> createState() => _JobLogsScreenState();
}

class _JobLogsScreenState extends State<JobLogsScreen> {
  final JobLogsService _jobLogsService = JobLogsService();
  List<Map<String, dynamic>> _jobLogs = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchJobLogs();
  }

  // Fetch job logs from API
  Future<void> _fetchJobLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final logs = await _jobLogsService.getJobLogs(widget.jobId);
      setState(() {
        _jobLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load job logs. Please try again.';
        _isLoading = false;
        // Use example logs as fallback
        _jobLogs = _generateExampleLogs();
      });
    }
  }

  // Generate example logs for fallback
  List<Map<String, dynamic>> _generateExampleLogs() {
    final now = DateTime.now();
    return [
      {
        'event_type': 'EXECUTION_STARTED',
        'message': 'Job execution started',
        'timestamp': now.subtract(const Duration(minutes: 15)).toIso8601String(),
      },
      {
        'event_type': 'JOB_DETAILS',
        'message': 'Job details retrieved',
        'timestamp': now.subtract(const Duration(minutes: 14)).toIso8601String(),
        'details': {
          'origin': 'SAWANTWADI ROAD',
          'destination': 'MADGOAN JN.',
          'journey_date': '2025-06-04',
          'travel_class': '1A',
          'passenger_count': 1,
          'auto_upgrade': false,
          'auto_book_alternate_date': false
        }
      },
      {
        'event_type': 'TRAIN_SELECTED',
        'message': 'Using specified train: 50107 - SWV-MAO PASS',
        'timestamp': now.subtract(const Duration(minutes: 13)).toIso8601String(),
        'details': {
          'train_number': '50107',
          'train_name': 'SWV-MAO PASS',
          'departure_time': null,
          'arrival_time': null,
          'duration': null
        }
      },
      {
        'event_type': 'BOOKING_ATTEMPT',
        'message': 'Attempting to book tickets',
        'timestamp': now.subtract(const Duration(minutes: 12)).toIso8601String(),
      },
      {
        'event_type': 'BOOKING_SUCCESSFUL',
        'message': 'Booking successful! PNR: PNR2025060112345',
        'timestamp': now.subtract(const Duration(minutes: 10)).toIso8601String(),
        'details': {
          'booking_id': 'BK-1622554766',
          'pnr': 'PNR2025060112345',
          'fare': 1250.00,
          'seats': ['B1-10']
        }
      }
    ];
  }

  // Get color based on event type
  Color _getEventColor(String eventType) {
    final type = eventType.toUpperCase();
    
    if (type.contains('STARTED') || type.contains('DETAILS') || type.contains('SEARCH')) {
      return Colors.blue;
    } else if (type.contains('SELECTED') || type.contains('FOUND')) {
      return Colors.green[700]!;
    } else if (type.contains('ATTEMPT')) {
      return Colors.orange;
    } else if (type.contains('SUCCESSFUL')) {
      return Colors.green;
    } else if (type.contains('FAILED') || type.contains('ERROR')) {
      return Colors.red;
    } else if (type.contains('RETRY')) {
      return Colors.amber[700]!;
    } else {
      return const Color(0xFF7C3AED); // Default purple
    }
  }

  // Get icon based on event type
  IconData _getEventIcon(String eventType) {
    final type = eventType.toUpperCase();
    
    if (type.contains('STARTED')) {
      return Icons.play_arrow;
    } else if (type.contains('DETAILS')) {
      return Icons.info;
    } else if (type.contains('SEARCH')) {
      return Icons.search;
    } else if (type.contains('SELECTED') || type.contains('FOUND')) {
      return Icons.train;
    } else if (type.contains('ATTEMPT')) {
      return Icons.pending;
    } else if (type.contains('SUCCESSFUL')) {
      return Icons.check_circle;
    } else if (type.contains('FAILED') || type.contains('ERROR')) {
      return Icons.error;
    } else if (type.contains('RETRY')) {
      return Icons.refresh;
    } else {
      return Icons.article; // Default
    }
  }

  // Format timestamp
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyyy, h:mm:ss a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Job Logs: ${widget.jobId}',
          style: const TextStyle(
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
            onPressed: _fetchJobLogs,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildLogsList(),
    );
  }

  Widget _buildLogsList() {
    return Column(
      children: [
        // Status card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getStatusColor(widget.jobStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.jobStatus).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(widget.jobStatus),
                      color: _getStatusColor(widget.jobStatus),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontFamily: 'ProductSans',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.jobStatus,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(widget.jobStatus),
                          fontFamily: 'ProductSans',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Logs header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.history,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Execution Logs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontFamily: 'ProductSans',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_jobLogs.length} events',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7C3AED),
                    fontFamily: 'ProductSans',
                  ),
                ),
              ),
            ],
          ),
        ),

        // Logs timeline
        Expanded(
          child: _jobLogs.isEmpty
              ? _buildEmptyLogsState()
              : ListView.builder(
                  itemCount: _jobLogs.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final log = _jobLogs[index];
                    final eventType = log['event_type'] ?? 'UNKNOWN';
                    final message = log['message'] ?? 'No message';
                    final timestamp = log['timestamp'] ?? '';
                    final details = log['details'];
                    final isLast = index == _jobLogs.length - 1;

                    return _buildTimelineItem(
                      eventType: eventType,
                      message: message,
                      timestamp: timestamp,
                      details: details,
                      isLast: isLast,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String eventType,
    required String message,
    required String timestamp,
    Map<String, dynamic>? details,
    required bool isLast,
  }) {
    final color = _getEventColor(eventType);
    final icon = _getEventIcon(eventType);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and dot
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 10,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: details != null ? 160 : 60,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Log content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event type and timestamp
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      eventType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFamily: 'ProductSans',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'ProductSans',
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontFamily: 'ProductSans',
                ),
              ),
              // Details card if available
              if (details != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontFamily: 'ProductSans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...details.entries.map((entry) {
                        // Format the value based on type
                        String valueStr;
                        if (entry.value is List) {
                          valueStr = (entry.value as List).join(', ');
                        } else if (entry.value is Map) {
                          valueStr = json.encode(entry.value);
                        } else {
                          valueStr = entry.value?.toString() ?? 'N/A';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_formatKey(entry.key)}: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ProductSans',
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  valueStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                    fontFamily: 'ProductSans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // Format key for display
  String _formatKey(String key) {
    // Convert snake_case to Title Case
    return key.split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }

  // Get color based on job status
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

  // Get icon based on job status
  IconData _getStatusIcon(String? status) {
    if (status == null) {
      return Icons.help_outline;
    }

    // Normalize status to handle case variations
    final normalizedStatus = status.toLowerCase();

    if (normalizedStatus.contains('schedule')) {
      return Icons.schedule;
    } else if (normalizedStatus.contains('progress') ||
        normalizedStatus.contains('in-progress')) {
      return Icons.pending;
    } else if (normalizedStatus.contains('complete')) {
      return Icons.check_circle;
    } else if (normalizedStatus.contains('fail')) {
      return Icons.error;
    } else {
      return Icons.help_outline;
    }
  }

  // Empty logs state
  Widget _buildEmptyLogsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Logs Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontFamily: 'ProductSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Logs will appear here once the job starts executing',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'ProductSans',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Loading state
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
            'Loading job logs...',
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

  // Error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
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
                fontSize: 14,
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
              onPressed: _fetchJobLogs,
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
}

// Helper for JSON encoding
import 'dart:convert';
