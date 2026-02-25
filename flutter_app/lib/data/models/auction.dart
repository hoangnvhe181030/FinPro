class Auction {
  final int id;
  final String productName;
  final String? sellerName;
  final double currentPrice;
  final double startingPrice;
  final double bidIncrement;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? originalEndTime;
  final String status; // PENDING, ACTIVE, ENDED, CANCELLED, SETTLED
  final int totalBids;

  Auction({
    required this.id,
    required this.productName,
    this.sellerName,
    required this.currentPrice,
    required this.startingPrice,
    required this.bidIncrement,
    required this.startTime,
    required this.endTime,
    this.originalEndTime,
    required this.status,
    required this.totalBids,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: json['id'] as int,
      productName: json['productName'] as String,
      sellerName: json['sellerName'] as String?,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      startingPrice: (json['startingPrice'] as num).toDouble(),
      bidIncrement: (json['bidIncrement'] as num).toDouble(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      originalEndTime: json['originalEndTime'] != null
          ? DateTime.parse(json['originalEndTime'] as String)
          : null,
      status: json['status'] as String,
      totalBids: json['totalBids'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'sellerName': sellerName,
      'currentPrice': currentPrice,
      'startingPrice': startingPrice,
      'bidIncrement': bidIncrement,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'originalEndTime': originalEndTime?.toIso8601String(),
      'status': status,
      'totalBids': totalBids,
    };
  }

  // Helpers
  bool get isActive => status == 'ACTIVE';
  bool get hasEnded => DateTime.now().isAfter(endTime);
  double get minimumBid => currentPrice + bidIncrement;
}
