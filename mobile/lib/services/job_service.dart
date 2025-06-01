import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class JobService {
  final String baseUrl = ApiConfig.baseUrl;

  // Create a new tatkal job
  Future<Map<String, dynamic>> createJob({
    required String userId,
    required String originStationCode,
    required String destinationStationCode,
    required String journeyDate,
    required String bookingTime,
    required String travelClass,
    required List<Map<String, dynamic>> passengers,
    required String jobType,
    required String bookingEmail,
    required String bookingPhone,
    bool autoUpgrade = false,
    bool autoBookAlternateDate = false,
    String paymentMethod = "wallet",
    String? notes,
    bool optForInsurance = false,
    Map<String, dynamic>? gstDetails,
    Map<String, dynamic>? selectedTrain,
    String? jobDate,
    String? jobExecutionTime,
  }) async {
    try {
      // Create the request body
      Map<String, dynamic> requestBody = {
        'user_id': userId,
        'origin_station_code': originStationCode,
        'destination_station_code': destinationStationCode,
        'journey_date': journeyDate,
        'booking_time': bookingTime,
        'travel_class': travelClass,
        'passengers': passengers,
        'job_type': jobType,
        'booking_email': bookingEmail,
        'booking_phone': bookingPhone,
        'auto_upgrade': autoUpgrade,
        'auto_book_alternate_date': autoBookAlternateDate,
        'payment_method': paymentMethod,
        'notes': notes,
        'opt_for_insurance': optForInsurance,
      };
      
      // Add job date and execution time if provided
      if (jobDate != null) {
        requestBody['job_date'] = jobDate;
      }
      
      if (jobExecutionTime != null) {
        requestBody['job_execution_time'] = jobExecutionTime;
      }

      // Add GST details if provided
      if (gstDetails != null) {
        requestBody['gst_details'] = gstDetails;
      }
      
      // Add selected train info if provided
      if (selectedTrain != null) {
        requestBody['train_details'] = selectedTrain;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/jobs/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to create job: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating job: $e');
    }
  }

  // Get all jobs for a user
  Future<List<Map<String, dynamic>>> getUserJobs({
    required String userId,
    String? status,
    String? journeyDateFrom,
    String? journeyDateTo,
  }) async {
    try {
      String url = '$baseUrl/jobs/?user_id=$userId';

      if (status != null) {
        url += '&status=$status';
      }

      if (journeyDateFrom != null) {
        url += '&journey_date_from=$journeyDateFrom';
      }

      if (journeyDateTo != null) {
        url += '&journey_date_to=$journeyDateTo';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jobsJson = jsonDecode(response.body);
        return jobsJson.map((job) => job as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to load jobs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading jobs: $e');
    }
  }

  // Get job details
  Future<Map<String, dynamic>> getJobDetails(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobs/$jobId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to load job details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading job details: $e');
    }
  }

  // Cancel a job
  Future<Map<String, dynamic>> cancelJob(String jobId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobs/$jobId/cancel'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to cancel job: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error cancelling job: $e');
    }
  }

  // Retry a failed job
  Future<Map<String, dynamic>> retryJob(String jobId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobs/$jobId/retry'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to retry job: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error retrying job: $e');
    }
  }
}
