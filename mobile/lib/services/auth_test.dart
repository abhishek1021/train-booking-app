import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_constants.dart';
import 'global_auth_interceptor.dart';

/// A utility class to test JWT authentication
class AuthTest {
  /// Test the JWT authentication by making a request to the auth-test endpoint
  static Future<Map<String, dynamic>> testAuthentication(BuildContext context) async {
    try {
      // Get the token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login first.'
        };
      }
      
      // Make a request to the auth-test endpoint
      final response = await GlobalAuthInterceptor.get(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/auth/auth-test'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Authentication successful',
          'data': data
        };
      } else if (response.statusCode == 401) {
        // Token is invalid or expired
        return {
          'success': false,
          'message': 'Authentication failed: Your session has expired. Please login again.'
        };
      } else {
        return {
          'success': false,
          'message': 'Authentication test failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error testing authentication: $e'
      };
    }
  }
  
  /// Display the authentication test result in a dialog
  static void showAuthTestResult(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
        ),
      ),
    );
    
    // Test authentication
    final result = await testAuthentication(context);
    
    // Remove loading indicator
    Navigator.of(context).pop();
    
    // Show result dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result['success'] ? 'Authentication Successful' : 'Authentication Failed',
          style: TextStyle(
            color: result['success'] ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['message']),
            if (result['success'] && result['data'] != null) ...[
              const SizedBox(height: 16),
              const Text('User Information:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('User ID: ${result['data']['user_id']}'),
              Text('Email: ${result['data']['email']}'),
              Text('Username: ${result['data']['username']}'),
              Text('Role: ${result['data']['role']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
