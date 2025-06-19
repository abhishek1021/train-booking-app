import 'package:http/http.dart' as http;
import 'global_auth_interceptor.dart';

/// Provides access to the authenticated HTTP client
/// 
/// This class provides a convenient way to access the authenticated HTTP client
/// that automatically includes JWT tokens in all requests.
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  late final http.Client _client;

  // Factory constructor
  factory HttpClientService() {
    return _instance;
  }

  // Private constructor
  HttpClientService._internal() {
    // Use the standard client
    _client = http.Client();
  }

  /// Get the HTTP client
  http.Client get client => _client;

  /// Dispose the client when no longer needed
  void dispose() {
    _client.close();
  }
}

// Convenience getter to access the authenticated client
/// This provides a client that automatically adds authentication headers
http.Client get authClient => http.Client();
