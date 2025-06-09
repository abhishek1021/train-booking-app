import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // Base URL for API calls
  final String baseUrl = 'http://localhost:8000/api/v1';
  
  // Get user profile from local storage
  Future<Map<String, dynamic>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_profile');
    
    if (userJson != null) {
      return jsonDecode(userJson);
    } else {
      // If not in local storage, fetch from API
      return await fetchUserProfile();
    }
  }
  
  // Fetch user profile from API
  Future<Map<String, dynamic>> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    
    if (email == null) {
      throw Exception('User not logged in');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dynamodb/users/profile/$email'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['user'];
        
        // Save to local storage
        await prefs.setString('user_profile', jsonEncode(userData));
        
        return userData;
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? phone,
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    
    if (email == null) {
      throw Exception('User not logged in');
    }
    
    try {
      // Create the request body with only non-null fields
      final Map<String, dynamic> requestBody = {};
      if (fullName != null) requestBody['FullName'] = fullName;
      if (phone != null) requestBody['Phone'] = phone;
      if (username != null) requestBody['Username'] = username;
      
      final response = await http.put(
        Uri.parse('$baseUrl/dynamodb/users/update/$email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedUser = responseData['user'];
        
        // Update local storage
        await prefs.setString('user_profile', jsonEncode(updatedUser));
        
        return {
          'success': true,
          'data': updatedUser,
          'message': 'Profile updated successfully'
        };
      } else {
        print('Failed to update profile: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to update profile: ${response.statusCode}'
        };
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}
