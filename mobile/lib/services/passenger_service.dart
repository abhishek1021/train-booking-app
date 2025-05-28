import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_constants.dart';

class PassengerService {
  final String _baseUrl = '${ApiConstants.baseUrl}/api/v1';
  final SharedPreferences _prefs;

  PassengerService(this._prefs);

  // Get user ID from shared preferences
  String? get _userId {
    final userProfileJson = _prefs.getString('user_profile');
    if (userProfileJson != null && userProfileJson.isNotEmpty) {
      try {
        final userProfile = jsonDecode(userProfileJson);
        return userProfile['UserID'];
      } catch (e) {
        print('Error parsing user profile: $e');
      }
    }
    return null;
  }

  // Get all favorite passengers for the current user
  Future<List<dynamic>> getFavoritePassengers() async {
    try {
      // Return empty list if no user ID
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        print('No user ID found');
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/passengers?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is List) {
            return data;
          } else if (data is Map && data.containsKey('data')) {
            return data['data'] as List;
          } else {
            print('Unexpected response format: $data');
            return [];
          }
        } catch (e) {
          print('Error parsing favorites: $e');
          return [];
        }
      } else if (response.statusCode == 401) {
        // Handle unauthorized
        print('Unauthorized - please login again');
        return [];
      } else {
        print('Failed to load favorites: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error in getFavoritePassengers: $e');
      return [];
    }
  }

  // Add a new favorite passenger
  Future<Map<String, dynamic>> addFavoritePassenger(Map<String, dynamic> passenger) async {
    try {
      // Make sure passenger has user_id
      if (!passenger.containsKey('user_id')) {
        final userId = _userId;
        if (userId != null && userId.isNotEmpty) {
          passenger['user_id'] = userId;
        }
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/passengers/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(passenger),
      );

      if (response.statusCode == 201) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to add favorite passenger');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Delete a favorite passenger
  Future<void> deleteFavoritePassenger(String passengerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/passengers/$passengerId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete favorite passenger');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Save current passenger as favorite
  Future<Map<String, dynamic>> saveAsFavorite({
    required String name,
    required String age,
    required String gender,
    required String idType,
    required String idNumber,
    bool isSenior = false,
  }) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      throw Exception('User ID not found');
    }

    final passenger = {
      'name': name,
      'age': int.tryParse(age) ?? 0,
      'gender': gender,
      'id_type': idType,
      'id_number': idNumber,
      'is_senior': isSenior,
      'user_id': userId,
    };

    return await addFavoritePassenger(passenger);
  }

  // Save multiple passengers in one go
  Future<List<Map<String, dynamic>>> saveMultiplePassengers(List<Map<String, dynamic>> passengers) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      throw Exception('User ID not found');
    }
    
    List<Map<String, dynamic>> results = [];
    
    for (var passenger in passengers) {
      try {
        final result = await addFavoritePassenger(passenger);
        results.add(result);
      } catch (e) {
        print('Error saving passenger ${passenger['name']}: $e');
      }
    }
    
    return results;
  }
  
  // Update an existing favorite passenger
  Future<Map<String, dynamic>> updateFavoritePassenger(String passengerId, Map<String, dynamic> passenger) async {
    try {
      // Make sure passenger has user_id
      if (!passenger.containsKey('user_id')) {
        final userId = _userId;
        if (userId != null && userId.isNotEmpty) {
          passenger['user_id'] = userId;
        }
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/passengers/?passenger_id=$passengerId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(passenger),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to update favorite passenger: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating passenger: $e');
    }
  }
}
