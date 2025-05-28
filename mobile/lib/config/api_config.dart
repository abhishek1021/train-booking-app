class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  // Timeout duration in seconds
  static const int timeout = 30;
  
  // API endpoints
  static const String trainEndpoint = '/trains';
  static const String bookingEndpoint = '/bookings';
  static const String paymentEndpoint = '/payments';
  static const String walletEndpoint = '/wallet';
  static const String walletTransactionEndpoint = '/wallet-transactions';
  static const String passengerEndpoint = '/passengers';
  static const String cityEndpoint = '/cities';
}
