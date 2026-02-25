import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  
  // Keys
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  
  // Save auth data
  static Future<void> saveAuthData({
    required String token,
    required int userId,
    required String username,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyUserId, value: userId.toString()),
      _storage.write(key: _keyUsername, value: username),
    ]);
  }
  
  // Get token
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }
  
  // Get user ID
  static Future<int?> getUserId() async {
    final userIdStr = await _storage.read(key: _keyUserId);
    if (userIdStr == null) return null;
    return int.tryParse(userIdStr);
  }
  
  // Get username
  static Future<String?> getUsername() async {
    return await _storage.read(key: _keyUsername);
  }
  
  // Clear all auth data
  static Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _keyToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUsername),
    ]);
  }
  
  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
