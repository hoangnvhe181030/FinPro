import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/auction_provider.dart';
import '../../data/providers/wallet_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../auctions/auction_detail_screen.dart';
import '../auctions/create_auction_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final auctionProvider = context.read<AuctionProvider>();
    final walletProvider = context.read<WalletProvider>();

    final userId = authProvider.currentUser?.userId;
    if (userId != null) {
      await Future.wait([
        auctionProvider.fetchAuctions(),
        walletProvider.fetchWallet(userId),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        backgroundColor: AppColors.cardDark,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom Header
            SliverToBoxAdapter(child: _buildHeader()),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Search auctions...',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
            ),

            // Wallet Card
            SliverToBoxAdapter(child: _buildWalletCard()),

            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: _buildQuickStats(),
              ),
            ),

            // Live Auctions Header
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Live Auctions',
                onSeeAll: () {},
              ).animate(delay: 500.ms).fadeIn(),
            ),

            // Featured Auctions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildFeaturedAuctions(),
              ),
            ),

            // Ending Soon
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SectionHeader(
                  title: 'Ending Soon',
                  onSeeAll: () {},
                ),
              ).animate(delay: 600.ms).fadeIn(),
            ),

            SliverToBoxAdapter(child: _buildEndingSoon()),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateAuctionScreen()),
        ),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name = auth.currentUser?.fullName ?? auth.currentUser?.username ?? 'User';
        return Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Find your best deals',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Icon(Icons.person, color: AppColors.primaryLight, size: 24),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
        );
      },
    );
  }

  Widget _buildWalletCard() {
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        if (provider.wallet == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.walletGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDeep.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet,
                                size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              'VND',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    Formatters.formatCurrency(provider.availableBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        'Reserved: ${Formatters.formatCurrency(provider.reservedBalance)}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Consumer<AuctionProvider>(
      builder: (context, provider, child) {
        final activeCount = provider.auctions.where((a) => a.isActive).length;
        final endingSoonCount = provider.auctions.where((a) {
          final remaining = a.endTime.difference(DateTime.now());
          return a.isActive && remaining.inHours < 1;
        }).length;

        return Row(
          children: [
            Expanded(child: _buildStatCard('Active', activeCount.toString(), Icons.flash_on_rounded, AppColors.auctionActive)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Ending', endingSoonCount.toString(), Icons.timer_outlined, AppColors.auctionEnding)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Total', provider.auctions.length.toString(), Icons.bar_chart_rounded, AppColors.info)),
          ],
        ).animate(delay: 400.ms).fadeIn();
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildFeaturedAuctions() {
    return Consumer<AuctionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final featured = provider.auctions.where((a) => a.isActive).take(5).toList();
        if (featured.isEmpty) {
          return const EmptyState(icon: Icons.gavel, title: 'No live auctions');
        }

        return SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featured.length,
            itemBuilder: (context, index) {
              final auction = featured[index];
              return _buildAuctionCard(auction, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildAuctionCard(auction, int index) {
    final remaining = auction.endTime.difference(DateTime.now());
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuctionDetailScreen(auctionId: auction.id),
        ),
      ),
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 105,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.cardDarkElevated,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.image_outlined, size: 36, color: AppColors.textMuted.withOpacity(0.3)),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: remaining.inMinutes < 30
                            ? AppColors.error.withOpacity(0.9)
                            : AppColors.auctionActive.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 10, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            Formatters.formatCompactCountdown(remaining),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  PriceTag(
                    price: Formatters.formatCompactCurrency(auction.currentPrice),
                    fontSize: 16,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${auction.totalBids} bids',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildEndingSoon() {
    return Consumer<AuctionProvider>(
      builder: (context, provider, _) {
        final endingSoon = provider.auctions.where((a) {
          final remaining = a.endTime.difference(DateTime.now());
          return a.isActive && remaining.inHours < 2;
        }).take(3).toList();

        if (endingSoon.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No auctions ending soon', style: Theme.of(context).textTheme.bodySmall),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: endingSoon.map((auction) {
              final remaining = auction.endTime.difference(DateTime.now());
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AuctionDetailScreen(auctionId: auction.id),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.auctionEnding.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.auctionEnding.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.timer, color: AppColors.auctionEnding, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auction.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${auction.totalBids} bids',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          PriceTag(
                            price: Formatters.formatCompactCurrency(auction.currentPrice),
                            fontSize: 14,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatCompactCountdown(remaining),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.auctionEnding,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
