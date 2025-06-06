import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../services/job_service.dart'; // To fetch job details
// import '../models/job_model.dart'; // Assuming a Job model exists or will be created
// import '../widgets/loading_indicator.dart'; // A common loading indicator
// import '../widgets/error_display.dart'; // A common error display widget

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _JobDetailsScreenState createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final JobService _jobService = JobService();
  Future<Map<String, dynamic>>? _jobDetailsFuture;

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  void _fetchJobDetails() {
    setState(() {
      _jobDetailsFuture = _jobService.getJobDetails(widget.jobId);
    });
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'N/A';
    }
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime.toLocal());
    } catch (e) {
      return dateTimeString;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailRow(String label, String? value,
      {IconData? icon, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'N/A',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    status = status?.toLowerCase();
    if (status == 'completed' || status == 'success') {
      return Colors.green.shade700;
    } else if (status == 'failed') {
      return Colors.red.shade700;
    } else if (status == 'in progress' || status == 'processing') {
      return Colors.orange.shade700;
    } else if (status == 'scheduled' || status == 'pending') {
      return Colors.blue.shade700;
    } else if (status == 'cancelled') {
      return Colors.grey.shade700;
    }
    return Colors.black87;
  }

  Color _getStatusBackgroundColor(String? status) {
    status = status?.toLowerCase();
    if (status == 'completed' || status == 'success') {
      return Colors.green.shade50;
    } else if (status == 'failed') {
      return Colors.red.shade50;
    } else if (status == 'in progress' || status == 'processing') {
      return Colors.orange.shade50;
    } else if (status == 'scheduled' || status == 'pending') {
      return Colors.blue.shade50;
    } else if (status == 'cancelled') {
      return Colors.grey.shade50;
    }
    return Colors.grey.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Job Details',
          style: TextStyle(
              fontFamily: 'ProductSans',
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7C3AED), // Primary purple
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _jobDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF7C3AED)),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading job details...',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 16,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade400, size: 70),
                    const SizedBox(height: 24),
                    Text(
                      'Failed to load job details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Retry',
                          style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.white,
                              fontSize: 16)),
                      onPressed: _fetchJobDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, color: Colors.grey[400], size: 70),
                  const SizedBox(height: 24),
                  const Text(
                    'No job details found.',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The job may have been deleted or does not exist.',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final job = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _fetchJobDetails();
            },
            color: const Color(0xFF7C3AED),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with job ID and status
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Job ID',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job['job_id'] ?? 'Unknown',
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  _getStatusBackgroundColor(job['job_status']),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(job['job_status']),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  job['job_status'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontFamily: 'ProductSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(job['job_status']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Job Overview Section
                    _buildSectionTitle('Job Overview'),
                    _buildCard([
                      if (job['job_status']?.toLowerCase() == 'completed' ||
                          job['job_status']?.toLowerCase() == 'success') ...[
                        _buildDetailRow('Booking ID', job['booking_id'],
                            icon: Icons.confirmation_number),
                        _buildDetailRow('PNR', job['pnr'], icon: Icons.receipt),
                      ],
                      if (job['job_status']?.toLowerCase() == 'failed')
                        _buildDetailRow('Failure Reason', job['failure_reason'],
                            icon: Icons.error_outline,
                            valueColor: Colors.red.shade700),
                      _buildDetailRow(
                          'Created At', _formatDateTime(job['created_at']),
                          icon: Icons.calendar_today),
                      _buildDetailRow(
                          'Last Updated', _formatDateTime(job['updated_at']),
                          icon: Icons.update),
                    ]),

                    // Journey Details Section with a more visual representation
                    _buildSectionTitle('Journey Details'),
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Journey visualization
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job['origin_station_code'] ?? '',
                                        style: const TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7C3AED),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        job['origin_station_name'] ?? '',
                                        style: TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        height: 2,
                                        color: const Color(0xFF7C3AED)
                                            .withOpacity(0.3),
                                      ),
                                      const Icon(
                                        Icons.train,
                                        color: Color(0xFF7C3AED),
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        job['destination_station_code'] ?? '',
                                        style: const TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7C3AED),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        job['destination_station_name'] ?? '',
                                        style: TextStyle(
                                          fontFamily: 'ProductSans',
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Journey details
                            Row(
                              children: [
                                Expanded(
                                  child: _buildJourneyInfoItem(
                                    Icons.date_range,
                                    'Journey Date',
                                    _formatDate(job['journey_date']),
                                  ),
                                ),
                                Expanded(
                                  child: _buildJourneyInfoItem(
                                    Icons.access_time,
                                    'Booking Time',
                                    job['booking_time'] ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildJourneyInfoItem(
                                    Icons.airline_seat_recline_normal,
                                    'Travel Class',
                                    job['travel_class'] ?? 'N/A',
                                  ),
                                ),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Passenger Details Section
                    _buildSectionTitle('Passenger Details'),
                    _buildPassengerDetails(job['passengers']),

                    // Contact Information Section
                    _buildSectionTitle('Contact Information'),
                    _buildCard([
                      _buildDetailRow('Booking Email', job['booking_email'],
                          icon: Icons.email),
                      _buildDetailRow('Booking Phone', job['booking_phone'],
                          icon: Icons.phone),
                    ]),

                    // Job Configuration Section
                    _buildSectionTitle('Job Configuration'),
                    _buildCard([
                      _buildDetailRow('Job Type', job['job_type'],
                          icon: Icons.work_outline),
                      _buildDetailRow('Auto Upgrade',
                          job['auto_upgrade'] == true ? 'Yes' : 'No',
                          icon: Icons.upgrade),
                      _buildDetailRow(
                          'Auto Book Alternate Date',
                          job['auto_book_alternate_date'] == true
                              ? 'Yes'
                              : 'No',
                          icon: Icons.date_range_outlined),
                      _buildDetailRow('Payment Method', job['payment_method'],
                          icon: Icons.payment),
                      _buildDetailRow('Notes', job['notes'], icon: Icons.notes),
                      _buildDetailRow('Execution Attempts',
                          job['execution_attempts']?.toString(),
                          icon: Icons.repeat),
                      _buildDetailRow(
                          'Max Attempts', job['max_attempts']?.toString(),
                          icon: Icons.repeat_one),
                      _buildDetailRow('Next Execution',
                          _formatDateTime(job['next_execution_time']),
                          icon: Icons.next_plan_outlined),
                      _buildDetailRow('Last Execution',
                          _formatDateTime(job['last_execution_time']),
                          icon: Icons.history_toggle_off_outlined),
                    ]),

                    // Add some bottom padding
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPassengerDetails(dynamic passengersData) {
    if (passengersData == null ||
        !(passengersData is List) ||
        passengersData.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No passenger details available',
                  style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 16,
                      color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<dynamic> passengers = passengersData;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(passengers.length, (index) {
            final passenger = passengers[index] as Map<String, dynamic>;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: (index == passengers.length - 1) ? 0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Color(0xFF7C3AED),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Passenger ${index + 1}',
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Name', passenger['name'],
                      icon: Icons.person_outline),
                  _buildDetailRow('Age', passenger['age']?.toString(),
                      icon: Icons.cake_outlined),
                  _buildDetailRow('Gender', passenger['gender'],
                      icon: Icons.wc_outlined),
                  if (passenger['berth_preference'] != null &&
                      passenger['berth_preference'].isNotEmpty)
                    _buildDetailRow(
                        'Berth Preference', passenger['berth_preference'],
                        icon: Icons.king_bed_outlined),
                  if (passenger['food_preference'] != null &&
                      passenger['food_preference'].isNotEmpty)
                    _buildDetailRow(
                        'Food Preference', passenger['food_preference'],
                        icon: Icons.fastfood_outlined),
                  if (index < passengers.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(
                          height: 1, thickness: 1, color: Colors.grey[200]),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// You might need to create these helper widgets if they don't exist:
// lib/widgets/loading_indicator.dart
// lib/widgets/error_display.dart
// And a JobModel in lib/models/job_model.dart if you prefer typed data over Map<String, dynamic>
