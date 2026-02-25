import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/auction_provider.dart';

class CreateAuctionScreen extends StatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  State<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends State<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _bidIncrementController = TextEditingController();
  final _durationController = TextEditingController();

  // Dropdown values
  List<Category> _categories = [];
  int? _selectedCategoryId;
  String _selectedCondition = 'NEW';
  bool _isLoadingCategories = false;
  bool _isCreating = false;

  // Conditions are fixed
  static const List<String> _conditions = [
    'NEW',
    'LIKE_NEW',
    'GOOD',
    'FAIR',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    
    try {
      final auctionProvider = context.read<AuctionProvider>();
      final response = await auctionProvider.apiService.dio.get('/categories');
      
      final List<dynamic> data = response.data;
      setState(() {
        _categories = data.map((json) => Category.fromJson(json)).toList();
        // Set first category as default if available
        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
      });
    } catch (e) {
      print('Error fetching categories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _startingPriceController.dispose();
    _bidIncrementController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final auctionProvider = context.read<AuctionProvider>();

      if (authProvider.currentUser == null) {
        throw Exception('Not logged in');
      }

      // Step 1: Create product
      final productResponse = await auctionProvider.apiService.dio.post(
        '/products',
        data: {
          'productName': _productNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'categoryId': _selectedCategoryId,
          'condition': _selectedCondition,
        },
        options: Options(
          headers: {
            'X-User-Id': authProvider.currentUser!.userId.toString(),
          },
        ),
      );

      final productId = productResponse.data['productId'];

      // Step 2: Create auction
      await auctionProvider.apiService.dio.post(
        '/auctions',
        data: {
          'productId': productId,
          'startingPrice': double.parse(_startingPriceController.text),
          'bidIncrement': double.parse(_bidIncrementController.text),
          'durationMinutes': int.parse(_durationController.text) * 60, // Convert hours to minutes
        },
        options: Options(
          headers: {
            'X-User-Id': authProvider.currentUser!.userId.toString(),
          },
        ),
      );

      // Refresh auctions
      await auctionProvider.fetchAuctions();

      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auction created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create auction: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Auction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section: Product Details
            Text(
              'Product Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Product Name
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., iPhone 14 Pro Max',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the product...',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            _isLoadingCategories
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
            const SizedBox(height: 16),

            // Condition Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Condition',
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition.replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCondition = value!);
              },
            ),
            const SizedBox(height: 32),

            // Section: Auction Settings
            Text(
              'Auction Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Starting Price
            TextFormField(
              controller: _startingPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Starting Price (đ)',
                hintText: 'e.g., 1000000',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter starting price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Bid Increment
            TextFormField(
              controller: _bidIncrementController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bid Increment (đ)',
                hintText: 'e.g., 50000',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter bid increment';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Duration (hours)
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (hours)',
                hintText: 'e.g., 24',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter duration';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Create Button
            ElevatedButton(
              onPressed: _isCreating ? null : _handleCreate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Create Auction'),
            ),
          ],
        ),
      ),
    );
  }
}
