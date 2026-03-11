import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/auction_provider.dart';
import '../../data/providers/wallet_provider.dart';
import '../auctions/auction_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.userId;
      if (userId != null) {
        final provider = context.read<AuctionProvider>();
        final response = await provider.apiService.dio.get('/api/users/$userId/stats');
        setState(() => _stats = Map<String, dynamic>.from(response.data));
      }
    } catch (_) {}
    setState(() => _isLoadingStats = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDeep, AppColors.scaffoldDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profile', style: Theme.of(context).textTheme.displayMedium),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Avatar + info
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: Center(
                          child: Text(
                            (user?.fullName ?? user?.username ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.fullName ?? user?.username ?? 'User', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // Stats grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildStatsGrid(),
            ),
          ),

          // Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
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
                    Tab(text: 'Selling'),
                    Tab(text: 'Bidding'),
                    Tab(text: 'Won'),
                  ],
                ),
              ),
            ),
          ),

          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAuctionTab('selling'),
                _buildAuctionTab('bidding'),
                _buildAuctionTab('won'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoadingStats || _stats == null) {
      return Row(
        children: List.generate(3, (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 80,
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14)),
          ),
        )),
      );
    }

    return Row(
      children: [
        _statItem('Created', '${_stats!['totalAuctionsCreated'] ?? 0}', Icons.add_circle_outline, AppColors.info),
        const SizedBox(width: 10),
        _statItem('Won', '${_stats!['auctionsWon'] ?? 0}', Icons.emoji_events_outlined, AppColors.accent),
        const SizedBox(width: 10),
        _statItem('Bids', '${_stats!['totalBids'] ?? 0}', Icons.gavel, AppColors.primaryLight),
      ],
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionTab(String type) {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return const EmptyState(icon: Icons.person, title: 'Not logged in');

    return FutureBuilder(
      future: _fetchUserAuctions(userId, type),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final auctions = snapshot.data ?? [];
        if (auctions.isEmpty) {
          return EmptyState(
            icon: type == 'won' ? Icons.emoji_events : Icons.gavel,
            title: type == 'selling' ? 'No auctions created' : type == 'bidding' ? 'Not bidding on any auction' : 'No auctions won yet',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: auctions.length,
          itemBuilder: (context, index) {
            final a = auctions[index];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: a['auctionId']))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.cardDarkElevated]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.image_outlined, color: AppColors.textMuted.withOpacity(0.3), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['productName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          StatusBadge(status: a['status'] ?? 'UNKNOWN', fontSize: 10),
                        ],
                      ),
                    ),
                    PriceTag(
                      price: Formatters.formatCompactCurrency(a['currentPrice'] ?? 0),
                      fontSize: 13,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _fetchUserAuctions(int userId, String type) async {
    try {
      final provider = context.read<AuctionProvider>();
      String endpoint = '/api/users/$userId/auctions';
      if (type == 'bidding') endpoint = '/api/users/$userId/bidding';
      if (type == 'won') endpoint = '/api/users/$userId/won';
      final response = await provider.apiService.dio.get(endpoint);
      return List<dynamic>.from(response.data);
    } catch (_) {
      return [];
    }
  }
}
