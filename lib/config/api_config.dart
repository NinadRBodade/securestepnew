import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Automatically uses correct URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001/api';
    } else {
      // For mobile devices - use your computer's WiFi IP
      return 'http://10.156.78.17:5001/api';
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
