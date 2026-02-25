import 'package:flutter/foundation.dart';
import '../../core/api/api_service.dart';
import '../../core/storage/secure_storage.dart';
import '../models/auth_user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  
  AuthUser? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;
  
  AuthProvider(this._apiService);
  
  // Getters
  AuthUser? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Initialize - Load saved token on app start
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final savedToken = await SecureStorage.getToken();
      if (savedToken != null) {
        _token = savedToken;
        
        // Load userId from storage
        final userId = await SecureStorage.getUserId();
        final username = await SecureStorage.getUsername();
        
        if (userId != null && username != null) {
          _currentUser = AuthUser(
            userId: userId,
            username: username,
            email: '',
            fullName: '',
          );
          
          // Update ApiService with the logged-in user's ID
          _apiService.updateUserId(userId);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Register new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );
      
      final data = response.data;
      _token = data['token'];
      _currentUser = AuthUser.fromJson(data);
      
      // Save to secure storage
      await SecureStorage.saveAuthData(
        token: _token!,
        userId: _currentUser!.userId,
        username: _currentUser!.username,
      );
      
      // Update ApiService with the logged-in user's ID
      _apiService.updateUserId(_currentUser!.userId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Login user
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      
      final data = response.data;
      _token = data['token'];
      _currentUser = AuthUser.fromJson(data);
      
      // Save to secure storage
      await SecureStorage.saveAuthData(
        token: _token!,
        userId: _currentUser!.userId,
        username: _currentUser!.username,
      );
      
      // Update ApiService with the logged-in user's ID
      _apiService.updateUserId(_currentUser!.userId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Logout
  Future<void> logout() async {
    await SecureStorage.clearAuthData();
    _token = null;
    _currentUser = null;
    notifyListeners();
  }
}
