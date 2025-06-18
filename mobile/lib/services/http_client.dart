import 'package:http/http.dart' as http;

/// Provides access to the standard HTTP client
/// 
/// Note: This client is automatically authenticated by the GlobalAuthInterceptor
/// which patches all HTTP requests to include the JWT token.
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  late final http.Client _client;

  // Factory constructor
  factory HttpClientService() {
    return _instance;
  }

  // Private constructor
  HttpClientService._internal() {
    // Use the standard client (GlobalAuthInterceptor will handle authentication)
    _client = http.Client();
  }

  /// Get the HTTP client
  http.Client get client => _client;

  /// Dispose the client when no longer needed
  void dispose() {
    _client.close();
  }
}

// Convenience getter to access the client
/// This client is automatically authenticated by the GlobalAuthInterceptor
http.Client get authClient => HttpClientService().client;
