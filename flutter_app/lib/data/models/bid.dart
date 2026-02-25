class Bid {
  final int id;
  final int auctionId;
  final String username;
  final double amount;
  final String status; // PENDING, ACCEPTED, REJECTED, OUTBID
  final DateTime time;

  Bid({
    required this.id,
    required this.auctionId,
    required this.username,
    required this.amount,
    required this.status,
    required this.time,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'] as int,
      auctionId: json['auctionId'] as int,
      username: json['username'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      time: DateTime.parse(json['time'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auctionId': auctionId,
      'username': username,
      'amount': amount,
      'status': status,
      'time': time.toIso8601String(),
    };
  }

  bool get isAccepted => status == 'ACCEPTED';
  bool get isOutbid => status == 'OUTBID';
}
