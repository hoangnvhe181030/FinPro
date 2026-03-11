import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/wallet_provider.dart';
import '../../data/providers/auth_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId != null) {
      await context.read<WalletProvider>().fetchWallet(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: RefreshIndicator(
        onRefresh: _loadWallet,
        color: AppColors.accent,
        backgroundColor: AppColors.cardDark,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 8),
                child: Text('Wallet', style: Theme.of(context).textTheme.displayMedium),
              ),
            ),

            // Balance card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBalanceCard(),
              ),
            ),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: _buildAction(Icons.arrow_downward_rounded, 'Deposit', AppColors.success, _showDepositDialog)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAction(Icons.arrow_upward_rounded, 'Withdraw', AppColors.warning, _showWithdrawDialog)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAction(Icons.history, 'History', AppColors.info, () {})),
                  ],
                ).animate(delay: 400.ms).fadeIn(),
              ),
            ),

            // Transaction history header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),

            // Transaction list
            SliverToBoxAdapter(child: _buildTransactionList()),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        if (provider.wallet == null) {
          return GlassCard(
            padding: const EdgeInsets.all(24),
            child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.walletGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDeep.withOpacity(0.6),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.account_balance_wallet, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('My Wallet', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(provider.wallet?.currency ?? 'VND', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Total Balance', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                Formatters.formatCurrency(provider.totalBalance),
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(provider.availableBalance),
                          style: TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Reserved', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.lock_outline, size: 12, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.formatCurrency(provider.reservedBalance),
                              style: TextStyle(color: AppColors.warning, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        final transactions = provider.transactions;
        if (transactions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: EmptyState(icon: Icons.receipt_long, title: 'No transactions yet', subtitle: 'Make a deposit to get started'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isDeposit = tx['type'] == 'DEPOSIT';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isDeposit ? AppColors.success : AppColors.error).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isDeposit ? AppColors.success : AppColors.error,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx['description'] ?? (isDeposit ? 'Deposit' : 'Withdrawal'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                        if (tx['createdAt'] != null)
                          Text(Formatters.formatRelativeTime(DateTime.parse(tx['createdAt'])), style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Text(
                    '${isDeposit ? '+' : '-'}${Formatters.formatCompactCurrency(tx['amount'])}',
                    style: TextStyle(color: isDeposit ? AppColors.success : AppColors.error, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDepositDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Deposit Funds', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            // Quick amounts
            Row(
              children: [
                _quickAmountChip(controller, 100000),
                const SizedBox(width: 8),
                _quickAmountChip(controller, 500000),
                const SizedBox(width: 8),
                _quickAmountChip(controller, 1000000),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Amount (VND)',
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Confirm Deposit',
              icon: Icons.check_rounded,
              colors: [AppColors.success, const Color(0xFF00C853)],
              onPressed: () async {
                final amount = double.tryParse(controller.text);
                if (amount == null || amount <= 0) return;
                Navigator.pop(context);
                final userId = context.read<AuthProvider>().currentUser?.userId;
                if (userId != null) {
                  await context.read<WalletProvider>().deposit(userId, amount);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAmountChip(TextEditingController controller, int amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.text = amount.toString(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Center(
            child: Text('${(amount / 1000).toStringAsFixed(0)}K', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ),
    );
  }

  void _showWithdrawDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Withdraw Funds', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Consumer<WalletProvider>(
              builder: (context, provider, _) {
                return Text('Available: ${Formatters.formatCurrency(provider.availableBalance)}', style: TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.w600));
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(labelText: 'Amount (VND)', prefixIcon: Icon(Icons.monetization_on_outlined)),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Confirm Withdraw',
              icon: Icons.check_rounded,
              colors: [AppColors.warning, const Color(0xFFFF8F00)],
              onPressed: () {
                final amount = double.tryParse(controller.text);
                if (amount == null || amount <= 0) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Withdrawal requested'), backgroundColor: AppColors.success),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
