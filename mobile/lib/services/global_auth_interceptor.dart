import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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
  
  /// Setup Dio interceptor with detailed logging
  static void _setupDioInterceptor() {
    _dioClient.interceptors.clear();
    
    // Add logging interceptor
    _dioClient.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (object) {
          debugPrint('🌐 DIO LOG: ${object.toString()}');
        },
      ),
    );
    
    // Add auth interceptor
    _dioClient.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('🌐 REQUEST DETAILS 🌐');
          debugPrint('URL: ${options.uri}');
          debugPrint('METHOD: ${options.method}');
          debugPrint('HEADERS: ${options.headers}');
          debugPrint('DATA: ${options.data}');
          
          await _refreshTokenCache();
          if (_cachedToken != null && _cachedToken!.isNotEmpty) {
            options.headers['Authorization'] = '${_cachedTokenType} ${_cachedToken}';
            debugPrint('AUTH: Added token ${_cachedTokenType} ${_cachedToken!.substring(0, min(_cachedToken!.length, 10))}...');
          } else {
            debugPrint('AUTH: No token available');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('🌐 RESPONSE DETAILS 🌐');
          debugPrint('STATUS: ${response.statusCode}');
          debugPrint('HEADERS: ${response.headers}');
          debugPrint('DATA: ${_truncateResponse(response.data)}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          debugPrint('🌐 ERROR DETAILS 🌐');
          debugPrint('ERROR: ${error.message}');
          debugPrint('RESPONSE: ${error.response?.data}');
          return handler.next(error);
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
  
  /// Make an authenticated GET request with detailed logging
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final authHeaders = await getAuthHeaders();
    if (headers != null) {
      authHeaders.addAll(headers);
    }
    
    // Log request details
    debugPrint('🌐 HTTP GET REQUEST 🌐');
    debugPrint('URL: $url');
    debugPrint('HEADERS: $authHeaders');
    
    final stopwatch = Stopwatch()..start();
    final response = await _httpClient.get(url, headers: authHeaders);
    stopwatch.stop();
    
    // Log response details
    debugPrint('🌐 HTTP GET RESPONSE (${stopwatch.elapsedMilliseconds}ms) 🌐');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('HEADERS: ${response.headers}');
    debugPrint('BODY: ${_truncateResponseBody(response.body)}');
    
    return response;
  }
  
  /// Make an authenticated POST request with detailed logging
  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await getAuthHeaders();
    if (headers != null) {
      authHeaders.addAll(headers);
    }
    
    // Log request details
    debugPrint('🌐 HTTP POST REQUEST 🌐');
    debugPrint('URL: $url');
    debugPrint('HEADERS: $authHeaders');
    debugPrint('BODY: ${_truncateRequestBody(body)}');
    
    final stopwatch = Stopwatch()..start();
    final response = await _httpClient.post(url, headers: authHeaders, body: body, encoding: encoding);
    stopwatch.stop();
    
    // Log response details
    debugPrint('🌐 HTTP POST RESPONSE (${stopwatch.elapsedMilliseconds}ms) 🌐');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('HEADERS: ${response.headers}');
    debugPrint('BODY: ${_truncateResponseBody(response.body)}');
    
    return response;
  }
  
  /// Make an authenticated PUT request with detailed logging
  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await getAuthHeaders();
    if (headers != null) {
      authHeaders.addAll(headers);
    }
    
    // Log request details
    debugPrint('🌐 HTTP PUT REQUEST 🌐');
    debugPrint('URL: $url');
    debugPrint('HEADERS: $authHeaders');
    debugPrint('BODY: ${_truncateRequestBody(body)}');
    
    final stopwatch = Stopwatch()..start();
    final response = await _httpClient.put(url, headers: authHeaders, body: body, encoding: encoding);
    stopwatch.stop();
    
    // Log response details
    debugPrint('🌐 HTTP PUT RESPONSE (${stopwatch.elapsedMilliseconds}ms) 🌐');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('HEADERS: ${response.headers}');
    debugPrint('BODY: ${_truncateResponseBody(response.body)}');
    
    return response;
  }
  
  /// Make an authenticated DELETE request
  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await getAuthHeaders();
    if (headers != null) {
      authHeaders.addAll(headers);
    }
    
    // Log request details
    debugPrint('🌐 HTTP DELETE REQUEST 🌐');
    debugPrint('URL: $url');
    debugPrint('HEADERS: $authHeaders');
    if (body != null) {
      debugPrint('BODY: ${_truncateRequestBody(body)}');
    }
    
    final stopwatch = Stopwatch()..start();
    final response = await _httpClient.delete(url, headers: authHeaders, body: body, encoding: encoding);
    stopwatch.stop();
    
    // Log response details
    debugPrint('🌐 HTTP DELETE RESPONSE (${stopwatch.elapsedMilliseconds}ms) 🌐');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('HEADERS: ${response.headers}');
    debugPrint('BODY: ${_truncateResponseBody(response.body)}');
    
    return response;
  }
  
  /// Make an authenticated PATCH request
  static Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final authHeaders = await getAuthHeaders();
    if (headers != null) {
      authHeaders.addAll(headers);
    }
    return await _httpClient.patch(url, headers: authHeaders, body: body, encoding: encoding);
  }
  
  /// Get the Dio client instance
  static Dio getDioClient() {
    if (!_initialized) {
      throw Exception('GlobalAuthInterceptor not initialized');
    }
    return _dioClient;
  }
  
  /// Helper method to truncate request body for logging
  static String _truncateRequestBody(Object? body) {
    if (body == null) return 'null';
    
    String bodyStr;
    if (body is String) {
      bodyStr = body;
      // Try to parse as JSON for pretty printing
      try {
        final jsonObj = json.decode(body);
        bodyStr = const JsonEncoder.withIndent('  ').convert(jsonObj);
      } catch (e) {
        // Not JSON, use as is
      }
    } else {
      bodyStr = body.toString();
    }
    
    // Truncate if too long
    const maxLength = 1000;
    if (bodyStr.length > maxLength) {
      return '${bodyStr.substring(0, maxLength)}... [truncated ${bodyStr.length - maxLength} chars]';
    }
    return bodyStr;
  }
  
  /// Helper method to truncate response body for logging
  static String _truncateResponseBody(String body) {
    String bodyStr = body;
    
    // Try to parse as JSON for pretty printing
    try {
      final jsonObj = json.decode(body);
      bodyStr = const JsonEncoder.withIndent('  ').convert(jsonObj);
    } catch (e) {
      // Not JSON, use as is
    }
    
    // Truncate if too long
    const maxLength = 1000;
    if (bodyStr.length > maxLength) {
      return '${bodyStr.substring(0, maxLength)}... [truncated ${bodyStr.length - maxLength} chars]';
    }
    return bodyStr;
  }
  
  /// Helper method to truncate Dio response data for logging
  static String _truncateResponse(dynamic data) {
    if (data == null) return 'null';
    
    String dataStr;
    if (data is Map || data is List) {
      try {
        dataStr = const JsonEncoder.withIndent('  ').convert(data);
      } catch (e) {
        dataStr = data.toString();
      }
    } else if (data is String) {
      dataStr = data;
      // Try to parse as JSON for pretty printing
      try {
        final jsonObj = json.decode(data);
        dataStr = const JsonEncoder.withIndent('  ').convert(jsonObj);
      } catch (e) {
        // Not JSON, use as is
      }
    } else {
      dataStr = data.toString();
    }
    
    // Truncate if too long
    const maxLength = 1000;
    if (dataStr.length > maxLength) {
      return '${dataStr.substring(0, maxLength)}... [truncated ${dataStr.length - maxLength} chars]';
    }
    return dataStr;
  }
  
  /// Helper method to get minimum of two integers
  static int min(int a, int b) {
    return a < b ? a : b;
  }
  
  /// Clear the token cache (useful after logout)
  static void clearTokenCache() {
    _cachedToken = null;
    _cachedTokenType = null;
  }
}
