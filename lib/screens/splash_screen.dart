import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'role_selection_screen.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'agent/agent_home_screen.dart';
import 'resident/resident_home_screen.dart';
import 'guard/guard_home_screen.dart';

// Splash screen - First screen when app opens
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _floatingController;
  late AnimationController _textController;
  late AnimationController _spinnerController;
  late AnimationController _dotsController;
  late AnimationController _circleController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFloatAnimation;
  late Animation<double> _shieldOpacityAnimation;
  late Animation<double> _footprintsAnimation;
  late Animation<double> _appNameAnimation;
  late Animation<Offset> _appNameSlideAnimation;
  late Animation<double> _taglineAnimation;
  late Animation<double> _spinnerOpacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkSession();
  }

  void _setupAnimations() {
    // Logo scale and appear animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoScaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // Floating animation
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _logoFloatAnimation = Tween<double>(begin: -12.0, end: 12.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _shieldOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.33, 0.50, curve: Curves.easeIn),
      ),
    );
    
    _footprintsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.60, 0.80, curve: Curves.easeOut),
      ),
    );
    
    _appNameAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.47, 0.67, curve: Curves.easeOut),
      ),
    );
    
    _appNameSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.47, 0.67, curve: Curves.easeOut),
      ),
    );
    
    _taglineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.73, 0.93, curve: Curves.easeOut),
      ),
    );

    // Spinner animation
    _spinnerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    
    _spinnerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.93, 1.0, curve: Curves.easeIn),
      ),
    );

    // Dots animation
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // Background circles animation
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    )..repeat();

    // Start animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _logoController.forward();
        _textController.forward();
      }
    });
  }

  Future<void> _checkSession() async {
    // Wait 3.5 seconds for splash display
    await Future.delayed(const Duration(milliseconds: 3500));
    
    if (!mounted) return;
    
    // Check for existing session
    final user = await AuthService.restoreSession();
    
    if (user != null) {
      // Session exists, navigate to appropriate home screen
      _navigateToHomeScreen(user);
    } else {
      // No session, navigate to role selection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    }
  }

  void _navigateToHomeScreen(UserModel user) {
    Widget homeScreen;
    
    switch (user.role) {
      case 'agent':
        homeScreen = AgentHomeScreen(user: user);
        break;
      case 'resident':
        homeScreen = ResidentHomeScreen(user: user);
        break;
      case 'guard':
        homeScreen = GuardHomeScreen(user: user);
        break;
      default:
        // Unknown role, go to role selection
        homeScreen = const RoleSelectionScreen();
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => homeScreen),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _floatingController.dispose();
    _textController.dispose();
    _spinnerController.dispose();
    _dotsController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4F46E5), // Indigo
              Color(0xFF2563EB), // Blue
              Color(0xFF06B6D4), // Cyan
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            AnimatedBuilder(
              animation: _circleController,
              builder: (context, child) {
                return Stack(
                  children: [
                    _buildFloatingCircle(
                      top: -100 + (_circleController.value * 50),
                      left: -50 + (_circleController.value * 30),
                      size: 200,
                      opacity: 0.1,
                    ),
                    _buildFloatingCircle(
                      top: 100 + math.sin(_circleController.value * 2 * math.pi) * 30,
                      right: -80 + (_circleController.value * 40),
                      size: 300,
                      opacity: 0.08,
                    ),
                    _buildFloatingCircle(
                      bottom: -150 + (_circleController.value * 60),
                      right: -100 + (_circleController.value * 50),
                      size: 350,
                      opacity: 0.12,
                    ),
                    _buildFloatingCircle(
                      bottom: 50 + math.cos(_circleController.value * 2 * math.pi) * 40,
                      left: -60 + (_circleController.value * 35),
                      size: 250,
                      opacity: 0.09,
                    ),
                  ],
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with floating effect
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _floatingController]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _logoFloatAnimation.value),
                        child: Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: _buildLogo(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // App name with slide and fade animation
                  FadeTransition(
                    opacity: _appNameAnimation,
                    child: SlideTransition(
                      position: _appNameSlideAnimation,
                      child: const Text(
                        'Secure Step',
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Tagline with fade animation
                  FadeTransition(
                    opacity: _taglineAnimation,
                    child: Text(
                      'Real-Time Verification System',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Loading spinner with fade animation
                  FadeTransition(
                    opacity: _spinnerOpacityAnimation,
                    child: Column(
                      children: [
                        RotationTransition(
                          turns: _spinnerController,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Animated dots
                        AnimatedBuilder(
                          animation: _dotsController,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (index) {
                                final delay = index * 0.2;
                                final value = (_dotsController.value - delay) % 1.0;
                                final scale = value < 0.5
                                    ? 1.0 + (value * 2 * 0.5)
                                    : 1.5 - ((value - 0.5) * 2 * 0.5);
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Version number at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _taglineAnimation,
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(opacity * 0.5),
              blurRadius: 60,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 144,
      height: 144,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shield with fade animation
          FadeTransition(
            opacity: _shieldOpacityAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.shield,
                size: 64,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          
          // Footprints with scale and rotate animation
          AnimatedBuilder(
            animation: _footprintsAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _footprintsAnimation.value,
                child: Transform.rotate(
                  angle: (1 - _footprintsAnimation.value) * 0.3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top footprint (teardrop shape)
                      Container(
                        width: 16,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Bottom footprint (teardrop shape)
                      Container(
                        width: 16,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}