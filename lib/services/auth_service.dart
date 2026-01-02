import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../config/api_config.dart';
import '../utils/constants.dart';

/// Service to manage authentication and session persistence
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userSocietyIdKey = 'user_society_id';
  static const String _userFlatNumberKey = 'user_flat_number';

  /// Save user session after login
  static Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, user.id ?? '');
    await prefs.setString(_userRoleKey, user.role);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_userEmailKey, user.email);
    await prefs.setString(_userPhoneKey, user.phone);
    await prefs.setString(_userSocietyIdKey, user.societyId);
    await prefs.setString(_userFlatNumberKey, user.flatNumber);
    
    // Set token in ApiConfig for services
    ApiConfig.setToken(token);
    
    print('✅ Session saved: ${user.email} (${user.role})');
  }

  /// Get stored auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Check if user has active session
  static Future<bool> hasActiveSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Restore user session from stored data
  static Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      print('❌ No saved session found');
      return null;
    }

    // Verify token with backend
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.authEndpoint}/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          final userData = data['user'];
          
          // Create UserModel from stored data
          final user = UserModel(
            id: userData['id'] ?? prefs.getString(_userIdKey)!,
            name: userData['name'] ?? prefs.getString(_userNameKey)!,
            email: userData['email'] ?? prefs.getString(_userEmailKey)!,
            role: userData['role'] ?? prefs.getString(_userRoleKey)!,
            phone: userData['phone'] ?? prefs.getString(_userPhoneKey) ?? '',
            societyId: userData['societyId'] ?? prefs.getString(_userSocietyIdKey) ?? '',
            flatNumber: userData['flatNumber'] ?? prefs.getString(_userFlatNumberKey) ?? '',
            token: token,
          );
          
          // Set token in ApiConfig
          ApiConfig.setToken(token);
          
          print('✅ Session restored: ${user.email} (${user.role})');
          return user;
        }
      }
      
      // Token invalid, clear session
      print('❌ Token verification failed, clearing session');
      await clearSession();
      return null;
      
    } catch (e) {
      print('⚠️ Could not verify token (offline?), using cached data');
      
      // If offline, use cached data (fallback)
      final userId = prefs.getString(_userIdKey);
      final userRole = prefs.getString(_userRoleKey);
      final userName = prefs.getString(_userNameKey);
      final userEmail = prefs.getString(_userEmailKey);
      
      if (userId != null && userRole != null && userName != null && userEmail != null) {
        final user = UserModel(
          id: userId,
          name: userName,
          email: userEmail,
          role: userRole,
          phone: prefs.getString(_userPhoneKey) ?? '',
          societyId: prefs.getString(_userSocietyIdKey) ?? '',
          flatNumber: prefs.getString(_userFlatNumberKey) ?? '',
          token: token,
        );
        
        // Set token in ApiConfig
        ApiConfig.setToken(token);
        
        print('✅ Using cached session: ${user.email} (${user.role})');
        return user;
      }
      
      return null;
    }
  }

  /// Clear user session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userSocietyIdKey);
    await prefs.remove(_userFlatNumberKey);
    
    // Clear token from ApiConfig
    ApiConfig.clearToken();
    
    print('✅ Session cleared');
  }

  /// Get user role from stored session
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  /// Get society ID from stored session
  static Future<String?> getSocietyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userSocietyIdKey);
  }
}
