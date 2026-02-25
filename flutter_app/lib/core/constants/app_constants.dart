class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:8080/api'; // Android Emulator
  // For iOS Simulator use: 'http://localhost:8080/api'
  // For Physical Device use: 'http://YOUR_IP:8080/api'
  
  static const String wsUrl = 'ws://10.0.2.2:8080/ws'; // WebSocket endpoint
  
  // Mock Authentication
  static const int defaultUserId = 1; // Will be replaced with real auth
  
  // API Endpoints
  static const String auctionsEndpoint = '/auctions';
  static const String bidsEndpoint = '/bids';
  static const String walletsEndpoint = '/wallets';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Error Codes
  static const String concurrencyErrorCode = 'CONCURRENCY_ERROR';
  static const String insufficientFundsCode = 'INSUFFICIENT_FUNDS';
  static const String invalidBidCode = 'INVALID_BID_AMOUNT';
  static const String auctionNotFoundCode = 'AUCTION_NOT_FOUND';
}
