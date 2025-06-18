import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import 'http_client.dart';

/// Service class for making authenticated API calls
class ApiService {
  /// Base URL for API calls
  final String baseUrl = ApiConstants.baseUrl;
  
  /// Get user profile data
  Future<Map<String, dynamic>> getUserProfile(String email) async {
    try {
      final response = await authClient.get(
        Uri.parse('$baseUrl/api/v1/dynamodb/users/$email'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting profile: $e');
    }
  }
  
  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile(String email, Map<String, dynamic> data) async {
    try {
      final response = await authClient.put(
        Uri.parse('$baseUrl/api/v1/dynamodb/users/$email/update'),
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
  
  /// Example of a protected API call that requires authentication
  Future<List<dynamic>> getBookingHistory() async {
    try {
      final response = await authClient.get(
        Uri.parse('$baseUrl/api/v1/bookings/history'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to load booking history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting booking history: $e');
    }
  }
}
