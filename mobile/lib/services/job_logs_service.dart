import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class JobLogsService {
  final String baseUrl = ApiConfig.baseUrl;

  // Get logs for a specific job
  Future<List<Map<String, dynamic>>> getJobLogs(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/job-logs/$jobId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> logsJson = jsonDecode(response.body);
        return logsJson.map((log) => log as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Failed to fetch job logs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching job logs: $e');
      throw Exception('Failed to fetch job logs: $e');
    }
  }
}
