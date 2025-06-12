import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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
      print('Error updating profile: $e');
      return {
        'success': false,
        'message': 'Error updating profile: $e'
      };
    }
  }
  
  // Register FCM token for push notifications
  Future<Map<String, dynamic>> registerFcmToken(String? token) async {
    // Skip FCM token registration on web platform
    if (kIsWeb) {
      print('UserService: Skipping FCM token registration on web platform');
      return {
        'success': true,
        'message': 'FCM token registration skipped on web platform'
      };
    }
    
    // Skip if token is null
    if (token == null) {
      return {
        'success': false,
        'message': 'FCM token is null'
      };
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userProfile = await getUserProfile();
    final userId = userProfile['user_id'];
    
    if (userId == null) {
      return {
        'success': false,
        'message': 'User ID not found'
      };
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token
        }),
      );
      
      if (response.statusCode == 200) {
        print('FCM token registered successfully');
        return {
          'success': true,
          'message': 'FCM token registered successfully'
        };
      } else {
        print('Failed to register FCM token: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to register FCM token: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error registering FCM token: $e');
      return {
        'success': false,
        'message': 'Error registering FCM token: $e'
      };
    }
  }
}
