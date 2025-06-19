import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global authentication interceptor for HTTP requests
/// This provides authenticated HTTP clients that automatically attach JWT tokens
class GlobalAuthInterceptor {
  static bool _initialized = false;
  static String? _cachedToken;
  static String? _cachedTokenType;
  
  // Singleton instance of the HTTP client
  static final http.Client _httpClient = http.Client();
  
  // Singleton instance of the Dio client
  static final Dio _dioClient = Dio();
  
  /// Initialize the global interceptor
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Cache the token for better performance
    await _refreshTokenCache();
    
    // Setup Dio interceptor
    _setupDioInterceptor();
    
    _initialized = true;
  }
  
  /// Refresh the token from SharedPreferences
  static Future<void> _refreshTokenCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
      _cachedTokenType = prefs.getString('token_type') ?? 'Bearer';
    } catch (e) {
      print('Error refreshing token cache: $e');
    }
  }
  
  /// Setup Dio interceptor
  static void _setupDioInterceptor() {
    _dioClient.interceptors.clear();
    _dioClient.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _refreshTokenCache();
          if (_cachedToken != null && _cachedToken!.isNotEmpty) {
            options.headers['Authorization'] = '${_cachedTokenType} ${_cachedToken}';
          }
          return handler.next(options);
        },
      ),
    );
  }
  
  /// Get authentication headers
  static Future<Map<String, String>> getAuthHeaders() async {
    await _refreshTokenCache();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      headers['Authorization'] = '${_cachedTokenType} ${_cachedToken}';
    }
    
    return headers;
  }
  
  /// Make an authenticated GET request
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final authHeaders = await getAuthHeaders();
    if (headers != null) {
      authHeaders.addAll(headers);
    }
    return await _httpClient.get(url, headers: authHeaders);
  }
  
  /// Make an authenticated POST request
  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await getAuthHeaders();
    if (headers != null) {
      authHeaders.addAll(headers);
    }
    return await _httpClient.post(url, headers: authHeaders, body: body, encoding: encoding);
  }
  
  /// Make an authenticated PUT request
  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await getAuthHeaders();
    if (headers != null) {
      authHeaders.addAll(headers);
    }
    return await _httpClient.put(url, headers: authHeaders, body: body, encoding: encoding);
  }
  
  /// Make an authenticated DELETE request
  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await getAuthHeaders();
    if (headers != null) {
      authHeaders.addAll(headers);
    }
    return await _httpClient.delete(url, headers: authHeaders, body: body, encoding: encoding);
  }
  
  /// Make an authenticated PATCH request
  static Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await getAuthHeaders();
    if (headers != null) {
      authHeaders.addAll(headers);
    }
    return await _httpClient.patch(url, headers: authHeaders, body: body, encoding: encoding);
  }
  
  /// Get the Dio client with authentication
  static Dio get dio => _dioClient;
  
  /// Clear the token cache (useful after logout)
  static void clearTokenCache() {
    _cachedToken = null;
    _cachedTokenType = null;
  }
}
