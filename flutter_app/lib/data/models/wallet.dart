class Wallet {
  final int userId;
  final int walletId;
  final double balance;
  final double reservedBalance;
  final double availableBalance;
  final String currency;

  Wallet({
    required this.userId,
    required this.walletId,
    required this.balance,
    required this.reservedBalance,
    required this.availableBalance,
    required this.currency,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      userId: json['userId'] as int,
      walletId: json['walletId'] as int,
      balance: (json['balance'] as num).toDouble(),
      reservedBalance: (json['reservedBalance'] as num).toDouble(),
      availableBalance: (json['availableBalance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'VND',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'walletId': walletId,
      'balance': balance,
      'reservedBalance': reservedBalance,
      'availableBalance': availableBalance,
      'currency': currency,
    };
  }

  // Helper to check if user can afford a bid
  bool canAfford(double amount) => availableBalance >= amount;
}
