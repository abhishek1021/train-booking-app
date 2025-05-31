class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'https://services.tatkalpro.in/api/v1';
  
  // Timeout duration in seconds
  static const int timeout = 60;
  
  // API endpoints
  static const String trainEndpoint = '/trains';
  static const String bookingEndpoint = '/bookings';
  static const String paymentEndpoint = '/payments';
  static const String walletEndpoint = '/wallet';
  static const String walletTransactionEndpoint = '/wallet-transactions';
  static const String passengerEndpoint = '/passengers';
  static const String cityEndpoint = '/cities';
  static const String stationEndpoint = '/cities';
  static const String jobsEndpoint = '/jobs';
}
