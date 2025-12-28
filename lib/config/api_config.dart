class ApiConfig {
  // static const String baseUrl = 'http://10.0.2.2:5001/api'; // Android emulator
  static const String baseUrl = 'http://localhost:5001/api'; // Chrome/Web browser
  // For iOS simulator use: 'http://localhost:5001/api'
  // For physical device use your computer's IP: 'http://192.168.1.2:5001/api'
  
  static String token = '';
  
  static void setToken(String newToken) {
    token = newToken;
  }
  
  static void clearToken() {
    token = '';
  }
}
