import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../core/api/socket_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/exceptions/api_exceptions.dart';
import '../../data/providers/auction_provider.dart';
import '../../data/providers/wallet_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/models/auction.dart';

class AuctionDetailScreen extends StatefulWidget {
  final int auctionId;

  const AuctionDetailScreen({super.key, required this.auctionId});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final SocketService _socketService = SocketService();
  Timer? _countdownTimer;
  Duration? _timeRemaining;
  bool _isBidding = false;

  @override
  void initState() {
    super.initState();
    _loadAuction();
    _connectWebSocket();
  }

  Future<void> _loadAuction() async {
    await context.read<AuctionProvider>().fetchAuctionById(widget.auctionId);
    _startCountdown();
  }

  Future<void> _refreshAuction() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.userId;
    
    if (userId != null) {
      await Future.wait([
        context.read<AuctionProvider>().fetchAuctionById(widget.auctionId),
        context.read<WalletProvider>().fetchWallet(userId),
      ]);
      // Note: _auction is not declared in the original code.
      // Assuming it should update the selectedAuction in the provider
      // or a local state variable if it were declared.
      // For now, I'll keep the original line as requested,
      // but it might cause a compile error if _auction is not defined.
      // setState(() {
      //   _auction = context.read<AuctionProvider>().selectedAuction;
      // });
    }
  }

  void _connectWebSocket() {
    _socketService.connect(
      onConnect: () {
        _socketService.subscribeToAuction(
          auctionId: widget.auctionId,
          onUpdate: (data) {
            // Parse WebSocket message
            final type = data['type'] as String?;
            
            if (type == 'PRICE_UPDATE') {
              final newPrice = (data['newPrice'] as num).toDouble();
              final totalBids = data['totalBids'] as int;
              
              // Update auction in provider
              final auction = context.read<AuctionProvider>().selectedAuction;
              if (auction != null) {
                context.read<AuctionProvider>().updateAuction(
                  Auction(
                    id: auction.id,
                    productName: auction.productName,
                    sellerName: auction.sellerName,
                    currentPrice: newPrice,
                    startingPrice: auction.startingPrice,
                    bidIncrement: auction.bidIncrement,
                    startTime: auction.startTime,
                    endTime: auction.endTime,
                    originalEndTime: auction.originalEndTime,
                    status: auction.status,
                    totalBids: totalBids,
                  ),
                );
              }
            } else if (type == 'SOFT_CLOSE_EXTENDED') {
              final newEndTime = DateTime.parse(data['newEndTime'] as String);
              
              // Update end time
              final auction = context.read<AuctionProvider>().selectedAuction;
              if (auction != null) {
                context.read<AuctionProvider>().updateAuction(
                  Auction(
                    id: auction.id,
                    productName: auction.productName,
                    sellerName: auction.sellerName,
                    currentPrice: auction.currentPrice,
                    startingPrice: auction.startingPrice,
                    bidIncrement: auction.bidIncrement,
                    startTime: auction.startTime,
                    endTime: newEndTime,
                    originalEndTime: auction.originalEndTime,
                    status: auction.status,
                    totalBids: auction.totalBids,
                  ),
                );
                _startCountdown(); // Restart timer
              }
              
              _showSnackBar('⏰ Auction extended by 5 minutes!', Colors.orange);
            }
          },
        );
      },
      onError: (error) {
        _showSnackBar('WebSocket error: $error', Colors.red);
      },
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    
    final auction = context.read<AuctionProvider>().selectedAuction;
    if (auction == null) return;

    _updateCountdown(); // Fixed typo
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final auction = context.read<AuctionProvider>().selectedAuction;
    if (auction == null) return;

    final now = DateTime.now();
    final remaining = auction.endTime.difference(now);

    if (remaining.isNegative) {
      setState(() => _timeRemaining = Duration.zero);
      _countdownTimer?.cancel();
    } else {
      setState(() => _timeRemaining = remaining);
    }
  }

  Future<void> _placeBid(double increment) async {
    final auction = context.read<AuctionProvider>().selectedAuction;
    if (auction == null) return;

    final bidAmount = auction.currentPrice + increment;

    setState(() => _isBidding = true);

    try {
      final success = await context.read<AuctionProvider>().placeBid(
        auctionId: widget.auctionId,
        amount: bidAmount,
      );

      if (success) {
        _showSnackBar(
          '✅ Bid placed: ${_formatCurrency(bidAmount)}',
          Colors.green,
        );
        // Refresh wallet with authenticated userId
        final authProvider = context.read<AuthProvider>();
        final userId = authProvider.currentUser?.userId;
        if (userId != null) {
          await context.read<WalletProvider>().fetchWallet(userId);
        }
      }
    } on ConcurrencyException catch (e) {
      _showSnackBar('⚠️ ${e.message} Refreshing...', Colors.red);
      await _loadAuction();
    } on InsufficientFundsException catch (e) {
      _showSnackBar('❌ ${e.message}. Please deposit.', Colors.red);
    } on InvalidBidException catch (e) {
      _showSnackBar('❌ ${e.message}', Colors.red);
      await _loadAuction();
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isBidding = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Detail'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AuctionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final auction = provider.selectedAuction;
          if (auction == null) {
            return const Center(child: Text('Auction not found'));
          }

          final bool isEnded = _timeRemaining?.inSeconds == 0;
          final bool canBid = !isEnded && !_isBidding;

          return RefreshIndicator(
            onRefresh: _loadAuction,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name Header
                    Text(
                      auction.productName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Timer Chip
                    Chip(
                      avatar: const Icon(Icons.timer, color: Colors.white),
                      label: Text(
                        _timeRemaining != null
                            ? _formatCountdown(_timeRemaining!)
                            : 'Loading...',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.orange,
                    ),
                    const SizedBox(height: 24),

                    // Current Price Card
                    Card(
                      elevation: 4,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              'Current Price',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatCurrency(auction.currentPrice),
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Bids: ${auction.totalBids}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Bid Buttons
                    Text(
                      'Quick Bid',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canBid ? () => _placeBid(10000) : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('+10k đ'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canBid ? () => _placeBid(50000) : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('+50k đ'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canBid ? () => _placeBid(100000) : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('+100k đ'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bidding indicator
                    if (_isBidding)
                      const Center(child: CircularProgressIndicator()),

                    // Ended indicator
                    if (isEnded)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            '⏱️ Auction Ended',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Auction Details
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Starting Price', _formatCurrency(auction.startingPrice)),
                    _buildDetailRow('Bid Increment', _formatCurrency(auction.bidIncrement)),
                    _buildDetailRow('Minimum Bid', _formatCurrency(auction.minimumBid)),
                    _buildDetailRow('Status', auction.status),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
