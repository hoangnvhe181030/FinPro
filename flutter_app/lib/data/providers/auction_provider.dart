import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../models/auction.dart';

class AuctionProvider with ChangeNotifier {
  final ApiService _apiService;
  
  List<Auction> _auctions = [];
  Auction? _selectedAuction;
  bool _isLoading = false;
  String? _error;

  AuctionProvider(this._apiService);

  // Getters
  ApiService get apiService => _apiService;  // Expose for custom API calls
  List<Auction> get auctions => _auctions;
  Auction? get selectedAuction => _selectedAuction;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch active auctions
  Future<void> fetchAuctions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getActiveAuctions();
      _auctions = data.map((json) => Auction.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _auctions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch single auction by ID
  Future<void> fetchAuctionById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getAuctionById(id);
      _selectedAuction = Auction.fromJson(data);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _selectedAuction = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Place a bid
  Future<bool> placeBid({
    required int auctionId,
    required double amount,
  }) async {
    try {
      await _apiService.placeBid(auctionId: auctionId, amount: amount);
      
      // Refresh auction after successful bid
      await fetchAuctionById(auctionId);
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update auction from WebSocket
  void updateAuction(Auction updatedAuction) {
    final index = _auctions.indexWhere((a) => a.id == updatedAuction.id);
    if (index != -1) {
      _auctions[index] = updatedAuction;
    }
    
    if (_selectedAuction?.id == updatedAuction.id) {
      _selectedAuction = updatedAuction;
    }
    
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
