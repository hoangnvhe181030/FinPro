import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api/api_service.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/main_screen.dart';
import 'core/storage/secure_storage.dart';
import 'data/providers/auction_provider.dart';
import 'data/providers/wallet_provider.dart';
import 'data/providers/auth_provider.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize API Service (userId will be set by AuthProvider after login)
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuctionProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Auction App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SecureStorage.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const MainScreen() : const LoginScreen();
      },
    );
  }
}
