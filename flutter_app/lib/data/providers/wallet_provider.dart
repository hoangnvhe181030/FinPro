import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../models/wallet.dart';

class WalletProvider with ChangeNotifier {
  final ApiService _apiService;
  
  Wallet? _wallet;
  bool _isLoading = false;
  String? _error;

  WalletProvider(this._apiService);

  // Getters
  Wallet? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  double get balance => _wallet?.balance ?? 0.0;
  double get availableBalance => _wallet?.availableBalance ?? 0.0;
  double get reservedBalance => _wallet?.reservedBalance ?? 0.0;

  // Fetch wallet
  Future<void> fetchWallet(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getWallet(userId);
      _wallet = Wallet.fromJson(data);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _wallet = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Deposit funds
  Future<bool> deposit({
    required int userId,
    required double amount,
  }) async {
    try {
      final data = await _apiService.depositFunds(userId: userId, amount: amount);
      _wallet = Wallet.fromJson(data);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if user can afford amount
  bool canAfford(double amount) {
    return _wallet?.canAfford(amount) ?? false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
