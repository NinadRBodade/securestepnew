import 'package:flutter/material.dart';
import 'login_screen_unified.dart';
import 'society_user_auth_screen.dart';

/// Screen to select user type: Independent House or Society Resident
class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Header
                const Text(
                  'Where do you live?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your residence type to continue with secure verification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Independent House Card
                _buildLivingTypeCard(
                  icon: Icons.home_outlined,
                  title: 'Independent House',
                  subtitle: 'Standalone property with private access',
                  gradientColors: const [Color(0xFF34D399), Color(0xFF14B8A6)],
                  unselectedColor: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF34D399),
                  checkColor: const Color(0xFF10B981),
                  isSelected: _selectedType == 'house',
                  onTap: () {
                    setState(() {
                      _selectedType = 'house';
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Society Card
                _buildLivingTypeCard(
                  icon: Icons.apartment_outlined,
                  title: 'Society',
                  subtitle: 'Apartment or gated community',
                  gradientColors: const [Color(0xFFA78BFA), Color(0xFF9333EA)],
                  unselectedColor: const Color(0xFFF5F3FF),
                  iconColor: const Color(0xFFA78BFA),
                  checkColor: const Color(0xFF9333EA),
                  isSelected: _selectedType == 'society',
                  onTap: () {
                    setState(() {
                      _selectedType = 'society';
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Continue Button
                _buildContinueButton(),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivingTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required Color unselectedColor,
    required Color iconColor,
    required Color checkColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        // Scale animation on tap
        onTap();
      },
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 150),
        tween: Tween(begin: 1.0, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 200,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? gradientColors[0].withOpacity(0.3)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: isSelected ? 10 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon container
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.25)
                                : unselectedColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            icon,
                            size: 36,
                            color: isSelected ? Colors.white : iconColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Subtitle
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isSelected
                                ? Colors.white.withOpacity(0.9)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Checkmark indicator
                  if (isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: 1.0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 18,
                            color: checkColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _selectedType != null;
    
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                if (_selectedType == 'house') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreenUnified(
                        userType: 'independent',
                      ),
                    ),
                  );
                } else if (_selectedType == 'society') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SocietyUserAuthScreen(),
                    ),
                  );
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? const Color(0xFF1E293B) : Colors.grey[300],
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[500],
          elevation: isEnabled ? 4 : 0,
          shadowColor: isEnabled ? const Color(0xFF1E293B).withOpacity(0.3) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Continue',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isEnabled ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}
