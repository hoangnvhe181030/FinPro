import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/auction_provider.dart';
import 'auction_detail_screen.dart';

class AuctionListPage extends StatefulWidget {
  const AuctionListPage({super.key});

  @override
  State<AuctionListPage> createState() => _AuctionListPageState();
}

class _AuctionListPageState extends State<AuctionListPage> {
  bool _isGridView = true;
  String _selectedFilter = 'All';
  final _filters = ['All', 'Active', 'Ending Soon', 'Ended'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuctionProvider>().fetchAuctions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Auctions', style: Theme.of(context).textTheme.displayMedium),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(22),
                          border: isSelected
                              ? null
                              : Border.all(color: AppColors.border.withOpacity(0.3)),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Auction list/grid
          Consumer<AuctionProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }

              if (provider.error != null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Failed to load', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        GradientButton(
                          text: 'Retry',
                          width: 120,
                          onPressed: () => provider.fetchAuctions(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              var auctions = provider.auctions;

              // Apply filter
              if (_selectedFilter == 'Active') {
                auctions = auctions.where((a) => a.isActive).toList();
              } else if (_selectedFilter == 'Ending Soon') {
                auctions = auctions.where((a) {
                  final remaining = a.endTime.difference(DateTime.now());
                  return a.isActive && remaining.inHours < 1;
                }).toList();
              } else if (_selectedFilter == 'Ended') {
                auctions = auctions.where((a) => !a.isActive).toList();
              }

              if (auctions.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyState(icon: Icons.gavel, title: 'No auctions found'),
                );
              }

              if (_isGridView) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildGridCard(auctions[index], index),
                      childCount: auctions.length,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildListCard(auctions[index], index),
                    childCount: auctions.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildGridCard(auction, int index) {
    final remaining = auction.endTime.difference(DateTime.now());
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: auction.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.cardDarkElevated,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(Icons.image_outlined, size: 32, color: AppColors.textMuted.withOpacity(0.2))),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: StatusBadge(status: auction.status),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    PriceTag(price: Formatters.formatCompactCurrency(auction.currentPrice), fontSize: 15),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${auction.totalBids} bids', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 11, color: AppColors.auctionEnding),
                            const SizedBox(width: 3),
                            Text(
                              Formatters.formatCompactCountdown(remaining),
                              style: TextStyle(fontSize: 10, color: AppColors.auctionEnding, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
    );
  }

  Widget _buildListCard(auction, int index) {
    final remaining = auction.endTime.difference(DateTime.now());
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: auction.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.cardDarkElevated]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.image_outlined, color: AppColors.textMuted.withOpacity(0.3)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auction.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      PriceTag(price: Formatters.formatCompactCurrency(auction.currentPrice), fontSize: 14),
                      const SizedBox(width: 12),
                      Text('${auction.totalBids} bids', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: auction.status, fontSize: 10),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: AppColors.auctionEnding),
                    const SizedBox(width: 3),
                    Text(Formatters.formatCompactCountdown(remaining), style: TextStyle(fontSize: 11, color: AppColors.auctionEnding)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.05, end: 0),
    );
  }
}
