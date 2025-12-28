import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

// This is the entry point of our Flutter app
void main() {
  runApp(const SocietySafetyApp());
}

// Root widget of the application
class SocietySafetyApp extends StatelessWidget {
  const SocietySafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App title
      title: 'Society Safety System',
      
      // Remove debug banner
      debugShowCheckedModeBanner: false,
      
      // App theme colors
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2196F3),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF2196F3),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      
      // First screen to show
      home: const SplashScreen(),
    );
  }
}