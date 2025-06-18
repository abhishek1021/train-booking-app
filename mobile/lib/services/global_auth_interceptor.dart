import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:shared_preferences/shared_preferences.dart';

/// Global authentication interceptor that patches HTTP and Dio libraries
/// to automatically attach JWT tokens to all outgoing requests
class GlobalAuthInterceptor {
  static bool _initialized = false;
  static String? _cachedToken;
  static String? _cachedTokenType;
  
  /// Initialize the global interceptor
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Cache the token for better performance
    await _refreshTokenCache();
    
    // Patch the HTTP library
    _patchHttpLibrary();
    
    // Patch the Dio library
    _patchDioLibrary();
    
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
  
  /// Patch the HTTP library to intercept all requests
  static void _patchHttpLibrary() {
    // Save the original HTTP methods
    final originalGet = http.get;
    final originalPost = http.post;
    final originalPut = http.put;
    final originalDelete = http.delete;
    final originalPatch = http.patch;
    
    // Override HTTP GET
    http.get = (Uri url, {Map<String, String>? headers}) async {
      await _refreshTokenCache();
      final newHeaders = _addAuthHeader(headers);
      return await originalGet(url, headers: newHeaders);
    };
    
    // Override HTTP POST
    http.post = (Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
      await _refreshTokenCache();
      final newHeaders = _addAuthHeader(headers);
      return await originalPost(url, headers: newHeaders, body: body, encoding: encoding);
    };
    
    // Override HTTP PUT
    http.put = (Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
      await _refreshTokenCache();
      final newHeaders = _addAuthHeader(headers);
      return await originalPut(url, headers: newHeaders, body: body, encoding: encoding);
    };
    
    // Override HTTP DELETE
    http.delete = (Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
      await _refreshTokenCache();
      final newHeaders = _addAuthHeader(headers);
      return await originalDelete(url, headers: newHeaders, body: body, encoding: encoding);
    };
    
    // Override HTTP PATCH
    http.patch = (Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
      await _refreshTokenCache();
      final newHeaders = _addAuthHeader(headers);
      return await originalPatch(url, headers: newHeaders, body: body, encoding: encoding);
    };
  }
  
  /// Patch the Dio library to intercept all requests
  static void _patchDioLibrary() {
    // Create a Dio interceptor
    final dioInterceptor = dio.InterceptorsWrapper(
      onRequest: (options, handler) async {
        await _refreshTokenCache();
        if (_cachedToken != null && _cachedToken!.isNotEmpty) {
          options.headers['Authorization'] = '${_cachedTokenType} ${_cachedToken}';
        }
        return handler.next(options);
      },
    );
    
    // Add the interceptor to the default Dio instance
    dio.Dio().interceptors.add(dioInterceptor);
  }
  
  /// Add authentication header to existing headers
  static Map<String, String> _addAuthHeader(Map<String, String>? headers) {
    final newHeaders = headers != null ? Map<String, String>.from(headers) : <String, String>{};
    
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      newHeaders['Authorization'] = '${_cachedTokenType} ${_cachedToken}';
    }
    
    return newHeaders;
  }
  
  /// Clear the token cache (useful after logout)
  static void clearTokenCache() {
    _cachedToken = null;
    _cachedTokenType = null;
  }
}
