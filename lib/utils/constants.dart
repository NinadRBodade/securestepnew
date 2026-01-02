import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// App-wide constants for colors, text styles, and values
class AppConstants {
  // API Configuration
  // Automatically uses the correct URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      // For Web browser (Chrome, etc.)
      return 'http://localhost:5001';
    } else {
      // For Mobile devices (Android/iOS)
      // Real device: Use your computer's WiFi IP (192.168.1.59)
      try {
        if (Platform.isAndroid) {
          return 'http://192.168.1.59:5001';
        } else if (Platform.isIOS) {
          return 'http://192.168.1.59:5001';
        } else {
          return 'http://192.168.1.59:5001';
        }
      } catch (e) {
        return 'http://192.168.1.59:5001';
      }
    }
  }
  
  static const String apiVersion = '/api';
  
  // API Endpoints
  static const String authEndpoint = '$apiVersion/auth';
  static const String sosEndpoint = '$apiVersion/sos';
  static const String agentsEndpoint = '$apiVersion/agents';
  static const String residentsEndpoint = '$apiVersion/residents';
  static const String guardsEndpoint = '$apiVersion/guards';
  
  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFFFF5722);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color dangerColor = Color(0xFFF44336);
  
  // User Roles (Mobile App Only - Admin is Web Portal only)
  static const String roleAgent = 'agent';
  static const String roleResident = 'resident';
  static const String roleGuard = 'guard';
  
  // Mock credentials for demo
  // Format: email -> password
  static const Map<String, String> mockCredentials = {
    'agent@demo.com': 'agent123',
    'resident@demo.com': 'resident123',
    'guard@demo.com': 'guard123',
  };
  
  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 16,
    color: Colors.black54,
  );
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
}