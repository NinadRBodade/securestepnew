import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Automatically uses correct URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001/api';
    } else {
      // For mobile devices - use your computer's WiFi IP
      return 'http://192.168.1.59:5001/api';
    }
  }
  
  static String token = '';
  
  static void setToken(String newToken) {
    token = newToken;
  }
  
  static void clearToken() {
    token = '';
  }
}
