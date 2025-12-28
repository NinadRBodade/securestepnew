import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'user_type_selection_screen.dart';
import 'login_screen_unified.dart';
import 'guard/guard_access_request_screen.dart';

/// Initial role selection screen - "Who are you?"
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  String? _selectedRole;
  
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late AnimationController _card1Controller;
  late AnimationController _card2Controller;
  late AnimationController _card3Controller;
  late AnimationController _shineController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _buttonController;
  late AnimationController _indicatorController;
  late List<AnimationController> _particleControllers;
  
  @override
  void initState() {
    super.initState();
    
    // Background circles - simple slow animations
    _circle1Controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    
    _circle2Controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);
    
    _circle3Controller = AnimationController(
      duration: const Duration(seconds: 14),
      vsync: this,
    )..repeat(reverse: true);
    
    // Card floating animations - very subtle
    _card1Controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _card2Controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _card2Controller.repeat(reverse: true);
    });
    
    _card3Controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _card3Controller.repeat(reverse: true);
    });
    
    // Simple shine effect
    _shineController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Glow effect for selected cards
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // Pulse effect - subtle
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Button shine
    _buttonController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // Bottom indicator
    _indicatorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // Floating particles - fewer and simpler
    _particleControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: Duration(seconds: 8 + index * 2),
        vsync: this,
      )..repeat(reverse: true),
    );
  }
  
  @override
  void dispose() {
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    _card1Controller.dispose();
    _card2Controller.dispose();
    _card3Controller.dispose();
    _shineController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _buttonController.dispose();
    _indicatorController.dispose();
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Floating background circles
          _buildFloatingCircles(),
          
          // Floating particles
          _buildFloatingParticles(),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Header
                  const Text(
                    'Who are you?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your role to access the appropriate\nfeatures and permissions for your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Role cards
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildAnimatedRoleCard(
                            controller: _card1Controller,
                            icon: Icons.person_outline,
                            title: 'User',
                            subtitle: 'Access verification\nservices',
                            role: 'user',
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedRoleCard(
                            controller: _card2Controller,
                            icon: Icons.shield_outlined,
                            title: 'Agent',
                            subtitle: 'Manage verifications',
                            role: 'agent',
                            color: const Color(0xFF6366F1),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedRoleCard(
                            controller: _card3Controller,
                            icon: Icons.security_outlined,
                            title: 'Guard',
                            subtitle: 'Security monitoring',
                            role: 'guard',
                            color: const Color(0xFF06B6D4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Continue button
                  _buildContinueButton(),
                  
                  const SizedBox(height: 16),
                  
                  // Bottom indicator
                  _buildBottomIndicator(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCircles() {
    return Stack(
      children: [
        // Circle 1 - Top Right
        AnimatedBuilder(
          animation: _circle1Controller,
          builder: (context, child) {
            return Positioned(
              top: 80 + (_circle1Controller.value * 20),
              right: 40 + (_circle1Controller.value * 15),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF93C5FD).withOpacity(0.15),
                ),
              ),
            );
          },
        ),
        
        // Circle 2 - Middle Left
        AnimatedBuilder(
          animation: _circle2Controller,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.4 + 
                   (_circle2Controller.value * 25),
              left: 30 + (_circle2Controller.value * 10),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFA5B4FC).withOpacity(0.12),
                ),
              ),
            );
          },
        ),
        
        // Circle 3 - Bottom
        AnimatedBuilder(
          animation: _circle3Controller,
          builder: (context, child) {
            return Positioned(
              bottom: 100 + (_circle3Controller.value * 20),
              right: 50 + (_circle3Controller.value * 15),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF67E8F9).withOpacity(0.1),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildFloatingParticles() {
    return Stack(
      children: List.generate(5, (index) {
        final positions = [
          {'top': 150.0, 'right': 100.0},
          {'top': 250.0, 'left': 50.0},
          {'top': 400.0, 'right': 80.0},
          {'bottom': 200.0, 'left': 100.0},
          {'top': 350.0, 'right': 150.0},
        ];
        
        return AnimatedBuilder(
          animation: _particleControllers[index],
          builder: (context, child) {
            final value = _particleControllers[index].value;
            Widget positioned = Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.2 + value * 0.1),
              ),
            );
            
            if (positions[index].containsKey('top') && positions[index].containsKey('right')) {
              positioned = Positioned(
                top: positions[index]['top']! + (value * 15),
                right: positions[index]['right']!,
                child: positioned,
              );
            } else if (positions[index].containsKey('top') && positions[index].containsKey('left')) {
              positioned = Positioned(
                top: positions[index]['top']! + (value * 15),
                left: positions[index]['left']!,
                child: positioned,
              );
            } else if (positions[index].containsKey('bottom') && positions[index].containsKey('left')) {
              positioned = Positioned(
                bottom: positions[index]['bottom']! + (value * 15),
                left: positions[index]['left']!,
                child: positioned,
              );
            }
            
            return positioned;
          },
        );
      }),
    );
  }
  
  Widget _buildAnimatedRoleCard({
    required AnimationController controller,
    required IconData icon,
    required String title,
    required String subtitle,
    required String role,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Transform.translate(
            offset: Offset(0, isSelected ? 0 : (controller.value * 3 - 1.5)),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRole = role;
                });
              },
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? color.withOpacity(0.3)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: isSelected ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Selection indicator
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 18,
                                color: color,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildContinueButton() {
    final isEnabled = _selectedRole != null;
    
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFF3B82F6) : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  if (_selectedRole == 'user') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserTypeSelectionScreen(),
                      ),
                    );
                  } else if (_selectedRole == 'agent') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreenUnified(
                          userType: 'agent',
                        ),
                      ),
                    );
                  } else if (_selectedRole == 'guard') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GuardAccessRequestScreen(),
                      ),
                    );
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              'Continue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBottomIndicator() {
    return AnimatedBuilder(
      animation: _indicatorController,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - _indicatorController.value * 0.3,
          child: Transform.scale(
            scaleX: 1.0 - _indicatorController.value * 0.2,
            child: Container(
              width: 134,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? color.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.white : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: color,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}