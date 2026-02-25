import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auction_provider.dart';
import 'auction_detail_screen.dart';

class AuctionListPage extends StatefulWidget {
  const AuctionListPage({super.key});

  @override
  State<AuctionListPage> createState() => _AuctionListPageState();
}

class _AuctionListPageState extends State<AuctionListPage> {
  @override
  void initState() {
    super.initState();
    // Fetch auctions on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuctionProvider>().fetchAuctions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auctions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AuctionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAuctions(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.auctions.isEmpty) {
            return const Center(child: Text('No active auctions'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAuctions(),
            child: ListView.builder(
              itemCount: provider.auctions.length,
              itemBuilder: (context, index) {
                final auction = provider.auctions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(auction.productName),
                    subtitle: Text(
                      'Current: \$${auction.currentPrice.toStringAsFixed(0)} | '
                      'Bids: ${auction.totalBids}',
                    ),
                    trailing: Chip(
                      label: Text(auction.status),
                      backgroundColor: auction.isActive
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuctionDetailScreen(
                            auctionId: auction.id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
