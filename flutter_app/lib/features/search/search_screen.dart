import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/auction_provider.dart';
import '../auctions/auction_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSort = 'Newest';
  List<dynamic> _results = [];
  bool _isSearching = false;

  final List<String> _categories = ['All', 'Electronics', 'Fashion', 'Home', 'Art', 'Collectibles', 'Other'];
  final List<String> _sortOptions = ['Newest', 'Price: Low to High', 'Price: High to Low', 'Most Bids', 'Ending Soon'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _isSearching = true);
    try {
      final provider = context.read<AuctionProvider>();
      // Use the existing auctions list and filter client-side
      final allAuctions = provider.auctions;
      final keyword = _searchController.text.toLowerCase();
      
      var results = allAuctions.where((a) {
        if (keyword.isNotEmpty && !a.productName.toLowerCase().contains(keyword)) {
          return false;
        }
        return true;
      }).toList();

      // Sort
      switch (_selectedSort) {
        case 'Price: Low to High':
          results.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
          break;
        case 'Price: High to Low':
          results.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
          break;
        case 'Most Bids':
          results.sort((a, b) => b.totalBids.compareTo(a.totalBids));
          break;
        case 'Ending Soon':
          results.sort((a, b) => a.endTime.compareTo(b.endTime));
          break;
        default:
          results.sort((a, b) => b.startTime.compareTo(a.startTime));
      }

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onSubmitted: (_) => _search(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search auctions...',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                onPressed: _search,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: AppColors.textSecondary),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _search();
                    },
                    child: Chip(
                      label: Text(cat),
                      backgroundColor: isSelected ? AppColors.primary : AppColors.cardDark,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      side: isSelected ? BorderSide.none : BorderSide(color: AppColors.border.withOpacity(0.3)),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty ? 'Search for auctions' : 'No results found',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final auction = _results[index];
                          final remaining = auction.endTime.difference(DateTime.now());
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: auction.id))),
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
                                    width: 56, height: 56,
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
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            PriceTag(price: Formatters.formatCompactCurrency(auction.currentPrice), fontSize: 13),
                                            const SizedBox(width: 12),
                                            Text('${auction.totalBids} bids', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      StatusBadge(status: auction.status, fontSize: 10),
                                      const SizedBox(height: 6),
                                      Text(Formatters.formatCompactCountdown(remaining), style: TextStyle(fontSize: 10, color: AppColors.auctionEnding)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn();
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Sort By', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...List.generate(_sortOptions.length, (i) {
              final option = _sortOptions[i];
              return ListTile(
                title: Text(option, style: TextStyle(color: _selectedSort == option ? AppColors.accent : AppColors.textPrimary, fontSize: 14)),
                trailing: _selectedSort == option ? Icon(Icons.check, color: AppColors.accent, size: 20) : null,
                onTap: () {
                  setState(() => _selectedSort = option);
                  Navigator.pop(context);
                  _search();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
