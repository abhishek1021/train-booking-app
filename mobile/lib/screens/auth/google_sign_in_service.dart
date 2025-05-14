import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import '../../api_constants.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(
          clientId:
              '67107230139-gr30cv7m5ts9mjn2ol2v2nd8r17bburd.apps.googleusercontent.com',
        )
      : GoogleSignIn();

  /// Performs Google Sign-In and checks if user exists in DynamoDB.
  /// Returns a map { 'exists': bool, 'email': String, 'name': String }
  static Future<Map<String, dynamic>> signInAndCheckUser() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled the sign-in
        return {'exists': false, 'email': null, 'name': null};
      }
      final email = account.email;
      final displayName = account.displayName ?? '';
      // Check if user exists in DynamoDB
      final url = Uri.parse(
          '${ApiConstants.baseUrl}/api/v1/dynamodb/users/exists/$email');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final exists = jsonDecode(response.body)['exists'] as bool;
        return {'exists': exists, 'email': email, 'name': displayName};
      } else {
        throw Exception('Failed to check user existence');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new user in DynamoDB for Google sign-in
  static Future<bool> createUserWithGoogle(
      {required String email, required String name}) async {
    final userId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    final username = email.split('@')[0];
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/dynamodb/users/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'PK': 'USER#$email',
          'SK': 'PROFILE',
          'UserID': userId,
          'Email': email,
          'Username': username,
          'PasswordHash': 'GOOGLE_OAUTH', // Placeholder for Google users
          'CreatedAt': now,
          'IsActive': true,
          'kyc_status': 'pending',
          'LastLoginAt': now,
          'OtherAttributes': {'FullName': name, 'Role': 'user'},
          'preferences': {},
          'recent_bookings': [],
          'updated_at': now,
          'created_at': now,
          'wallet_balance': 0,
          'wallet_id': '',
          'google_signin': true
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
