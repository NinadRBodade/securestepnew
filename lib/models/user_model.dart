// User model to store user data
class UserModel {
  final String? id; // MongoDB user ID
  final String email;
  final String role; // agent, resident, guard, admin
  final String name;
  final String phone; // Phone number
  final String societyId;
  final String flatNumber;
  final String? token; // JWT token
  
  UserModel({
    this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.phone,
    required this.societyId,
    required this.flatNumber,
    this.token,
  });
  
  // Convert user object to JSON (for storing in SharedPreferences later)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'phone': phone,
      'societyId': societyId,
      'flatNumber': flatNumber,
      'token': token,
    };
  }
  
  // Convert user object to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'phone': phone,
      'societyId': societyId,
      'flat': flatNumber,
      'token': token,
    };
  }
  
  // Create user object from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      name: json['name'],
      phone: json['phone'] ?? '',
      societyId: json['societyId'] ?? '',
      flatNumber: json['flatNumber'] ?? '',
      token: json['token'],
    );
  }
}