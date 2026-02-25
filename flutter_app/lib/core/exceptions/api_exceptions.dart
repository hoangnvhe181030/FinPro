// Custom Exceptions

class ConcurrencyException implements Exception {
  final String message;
  
  ConcurrencyException([this.message = 'Price has changed. Please refresh and try again.']);
  
  @override
  String toString() => message;
}

class InsufficientFundsException implements Exception {
  final String message;
  final double? required;
  final double? available;
  
  InsufficientFundsException({
    this.message = 'Insufficient funds',
    this.required,
    this.available,
  });
  
  @override
  String toString() {
    if (required != null && available != null) {
      return 'Insufficient funds. Required: $required, Available: $available';
    }
    return message;
  }
}

class InvalidBidException implements Exception {
  final String message;
  final double? bidAmount;
  final double? minimumRequired;
  
  InvalidBidException({
    this.message = 'Invalid bid amount',
    this.bidAmount,
    this.minimumRequired,
  });
  
  @override
  String toString() {
    if (bidAmount != null && minimumRequired != null) {
      return 'Bid amount $bidAmount is lower than minimum required: $minimumRequired';
    }
    return message;
  }
}

class AuctionNotFoundException implements Exception {
  final String message;
  
  AuctionNotFoundException([this.message = 'Auction not found']);
  
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'API Error ($statusCode): $message';
}
