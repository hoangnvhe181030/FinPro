class AuthUser {
  final int userId;
  final String username;
  final String email;
  final String fullName;
  
  AuthUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.fullName,
  });
  
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId'],
      username: json['username'],
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'fullName': fullName,
    };
  }
}
