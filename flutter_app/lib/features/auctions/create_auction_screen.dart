import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/providers/auction_provider.dart';
import '../../data/providers/auth_provider.dart';

class CreateAuctionScreen extends StatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  State<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends State<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _bidIncrementController = TextEditingController(text: '10000');
  
  String _selectedCondition = 'NEW';
  int _durationMinutes = 60;
  bool _isCreating = false;

  final List<Map<String, dynamic>> _durations = [
    {'label': '30 min', 'value': 30},
    {'label': '1 hour', 'value': 60},
    {'label': '3 hours', 'value': 180},
    {'label': '6 hours', 'value': 360},
    {'label': '12 hours', 'value': 720},
    {'label': '24 hours', 'value': 1440},
  ];

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _startingPriceController.dispose();
    _bidIncrementController.dispose();
    super.dispose();
  }

  Future<void> _createAuction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);

    try {
      final provider = context.read<AuctionProvider>();
      final userId = context.read<AuthProvider>().currentUser?.userId;

      // Create product first, then auction
      final headers = {'X-User-Id': userId.toString()};

      final productResponse = await provider.apiService.dio.post(
        '/api/products',
        data: {
          'productName': _productNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'condition': _selectedCondition,
          'categoryId': 1, // Default category
        },
        options: Options(headers: headers),
      );

      final productId = productResponse.data['productId'];

      await provider.apiService.dio.post(
        '/api/auctions',
        data: {
          'productId': productId,
          'startingPrice': double.parse(_startingPriceController.text),
          'bidIncrement': double.parse(_bidIncrementController.text),
          'durationMinutes': _durationMinutes,
        },
        options: Options(headers: headers),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auction created!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldDark,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Auction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product info section
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Product Information', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _productNameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Condition dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      dropdownColor: AppColors.cardDarkElevated,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        prefixIcon: Icon(Icons.grade_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'NEW', child: Text('New')),
                        DropdownMenuItem(value: 'LIKE_NEW', child: Text('Like New')),
                        DropdownMenuItem(value: 'GOOD', child: Text('Good')),
                        DropdownMenuItem(value: 'FAIR', child: Text('Fair')),
                        DropdownMenuItem(value: 'USED', child: Text('Used')),
                      ],
                      onChanged: (v) => setState(() => _selectedCondition = v!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Pricing section
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pricing', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _startingPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Starting Price (VND)',
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bidIncrementController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Bid Increment (VND)',
                        prefixIcon: Icon(Icons.trending_up),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Duration section
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duration', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _durations.map((d) {
                        final isSelected = _durationMinutes == d['value'];
                        return GestureDetector(
                          onTap: () => setState(() => _durationMinutes = d['value']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.cardDarkElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected ? null : Border.all(color: AppColors.border.withOpacity(0.3)),
                            ),
                            child: Text(
                              d['label'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              GradientButton(
                text: 'Create Auction',
                icon: Icons.gavel,
                isLoading: _isCreating,
                onPressed: _createAuction,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
