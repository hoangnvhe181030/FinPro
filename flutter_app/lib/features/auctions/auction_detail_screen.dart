import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../core/api/socket_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
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

class _AuctionDetailScreenState extends State<AuctionDetailScreen> with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  Timer? _countdownTimer;
  Duration? _timeRemaining;
  bool _isBidding = false;
  bool _isFavorite = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAuction();
    _connectWebSocket();
  }

  Future<void> _loadAuction() async {
    await context.read<AuctionProvider>().fetchAuctionById(widget.auctionId);
    _startCountdown();
  }

  void _connectWebSocket() {
    _socketService.connect(
      onConnect: () {
        _socketService.subscribeToAuction(
          auctionId: widget.auctionId,
          onUpdate: (data) {
            final type = data['type'] as String?;
            if (type == 'PRICE_UPDATE') {
              final newPrice = (data['newPrice'] as num).toDouble();
              final totalBids = data['totalBids'] as int;
              final auction = context.read<AuctionProvider>().selectedAuction;
              if (auction != null) {
                context.read<AuctionProvider>().updateAuction(
                  Auction(id: auction.id, productName: auction.productName, sellerName: auction.sellerName, currentPrice: newPrice, startingPrice: auction.startingPrice, bidIncrement: auction.bidIncrement, startTime: auction.startTime, endTime: auction.endTime, originalEndTime: auction.originalEndTime, status: auction.status, totalBids: totalBids),
                );
              }
            } else if (type == 'SOFT_CLOSE_EXTENDED') {
              final newEndTime = DateTime.parse(data['newEndTime'] as String);
              final auction = context.read<AuctionProvider>().selectedAuction;
              if (auction != null) {
                context.read<AuctionProvider>().updateAuction(
                  Auction(id: auction.id, productName: auction.productName, sellerName: auction.sellerName, currentPrice: auction.currentPrice, startingPrice: auction.startingPrice, bidIncrement: auction.bidIncrement, startTime: auction.startTime, endTime: newEndTime, originalEndTime: auction.originalEndTime, status: auction.status, totalBids: auction.totalBids),
                );
                _startCountdown();
              }
              _showSnackBar('Auction extended by 5 minutes!', AppColors.warning);
            }
          },
        );
      },
      onError: (error) => _showSnackBar('Connection error', AppColors.error),
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    final auction = context.read<AuctionProvider>().selectedAuction;
    if (auction == null) return;
    final remaining = auction.endTime.difference(DateTime.now());
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
      final success = await context.read<AuctionProvider>().placeBid(auctionId: widget.auctionId, amount: bidAmount);
      if (success) {
        _showSnackBar('Bid placed: ${_formatCurrency(bidAmount)}', AppColors.success);
        final userId = context.read<AuthProvider>().currentUser?.userId;
        if (userId != null) await context.read<WalletProvider>().fetchWallet(userId);
      }
    } on ConcurrencyException catch (e) {
      _showSnackBar('${e.message} Refreshing...', AppColors.error);
      await _loadAuction();
    } on InsufficientFundsException catch (e) {
      _showSnackBar('${e.message}. Please deposit.', AppColors.error);
    } on InvalidBidException catch (e) {
      _showSnackBar(e.message, AppColors.error);
      await _loadAuction();
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.error);
    } finally {
      setState(() => _isBidding = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(amount);
  }

  String _formatCountdown(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _socketService.disconnect();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: Consumer<AuctionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final auction = provider.selectedAuction;
          if (auction == null) {
            return const Center(child: Text('Auction not found', style: TextStyle(color: AppColors.textSecondary)));
          }
          final bool isEnded = _timeRemaining?.inSeconds == 0;
          final bool canBid = !isEnded && !_isBidding;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _loadAuction,
                color: AppColors.accent,
                backgroundColor: AppColors.cardDark,
                child: CustomScrollView(
                  slivers: [
                    // Hero Image Area
                    SliverAppBar(
                      expandedHeight: 240,
                      pinned: true,
                      backgroundColor: AppColors.surfaceDark,
                      leading: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                        ),
                      ),
                      actions: [
                        GestureDetector(
                          onTap: () => setState(() => _isFavorite = !_isFavorite),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: _isFavorite ? AppColors.error : Colors.white,
                            ),
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withOpacity(0.3), AppColors.cardDarkElevated, AppColors.scaffoldDark],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(child: Icon(Icons.image_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.2))),
                        ),
                      ),
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Status
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    auction.productName,
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                StatusBadge(status: isEnded ? 'ENDED' : auction.status),
                              ],
                            ),
                            if (auction.sellerName != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text('by ${auction.sellerName}', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Price + Timer row
                            Row(
                              children: [
                                Expanded(
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Current Price', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                        const SizedBox(height: 6),
                                        PriceTag(price: _formatCurrency(auction.currentPrice), fontSize: 24),
                                        const SizedBox(height: 4),
                                        Text('${auction.totalBids} bids', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(18),
                                    borderColor: isEnded ? AppColors.error.withOpacity(0.3) : AppColors.auctionEnding.withOpacity(0.3),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(isEnded ? 'Ended' : 'Time Left', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                        const SizedBox(height: 6),
                                        Text(
                                          _timeRemaining != null ? _formatCountdown(_timeRemaining!) : '...',
                                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isEnded ? AppColors.error : AppColors.auctionEnding),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(isEnded ? 'Auction ended' : 'remaining', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Tabs
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                indicator: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                tabs: const [
                                  Tab(text: 'Details'),
                                  Tab(text: 'Bid History'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 250,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildDetailsTab(auction),
                                  _buildBidHistoryTab(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom bid panel
              if (!isEnded)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.3))),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -5))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Quick Bid', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildBidButton('+10K', 10000, canBid),
                            const SizedBox(width: 8),
                            _buildBidButton('+50K', 50000, canBid),
                            const SizedBox(width: 8),
                            _buildBidButton('+100K', 100000, canBid),
                          ],
                        ),
                        if (_isBidding) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(color: AppColors.accent, backgroundColor: AppColors.cardDark),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBidButton(String label, double amount, bool enabled) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () => _placeBid(amount) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.primaryGradient : null,
            color: enabled ? null : AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            boxShadow: enabled ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: enabled ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(Auction auction) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _detailRow(Icons.monetization_on_outlined, 'Starting Price', _formatCurrency(auction.startingPrice)),
        _detailRow(Icons.trending_up, 'Bid Increment', _formatCurrency(auction.bidIncrement)),
        _detailRow(Icons.arrow_upward, 'Minimum Bid', _formatCurrency(auction.minimumBid)),
        _detailRow(Icons.calendar_today_outlined, 'Start Time', DateFormat('dd/MM/yyyy HH:mm').format(auction.startTime)),
        _detailRow(Icons.event_outlined, 'End Time', DateFormat('dd/MM/yyyy HH:mm').format(auction.endTime)),
        _detailRow(Icons.info_outline, 'Status', auction.status),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBidHistoryTab() {
    return FutureBuilder<List<dynamic>>(
      future: _fetchBidHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final bids = snapshot.data ?? [];
        if (bids.isEmpty) {
          return const EmptyState(icon: Icons.how_to_vote, title: 'No bids yet');
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: bids.length,
          itemBuilder: (context, index) {
            final bid = bids[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: index == 0 ? Border.all(color: AppColors.accent.withOpacity(0.3)) : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: index == 0 ? AppColors.accent.withOpacity(0.15) : AppColors.cardDarkElevated,
                    child: Icon(Icons.person, size: 18, color: index == 0 ? AppColors.accent : AppColors.textMuted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bid['username'] ?? 'User #${bid['id']}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(bid['time'] != null ? DateFormat('HH:mm dd/MM').format(DateTime.parse(bid['time'])) : '', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  PriceTag(price: _formatCurrency((bid['amount'] as num).toDouble()), fontSize: 13, color: index == 0 ? AppColors.accent : AppColors.textPrimary),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _fetchBidHistory() async {
    try {
      final provider = context.read<AuctionProvider>();
      final response = await provider.apiService.dio.get('/api/auctions/${widget.auctionId}/bids');
      return List<dynamic>.from(response.data);
    } catch (_) {
      return [];
    }
  }
}
