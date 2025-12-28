import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'user_type_selection_screen.dart';
import 'agent/agent_home_screen.dart';
import 'guard/guard_home_screen.dart';
import 'login_screen_unified.dart';

/// Initial role selection screen - first screen after splash
class InitialRoleSelectionScreen extends StatelessWidget {
  const InitialRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App branding
              const Icon(
                Icons.security,
                size: 80,
                color: Color(0xFF2196F3),
              ),
              const SizedBox(height: 16),
              const Text(
                'Society Safety',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(height: 48),

              // Title
              const Text(
                'Who are you?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // User card
              _buildRoleCard(
                context: context,
                icon: Icons.person,
                title: 'User',
                subtitle: 'I am a resident',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserTypeSelectionScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Agent card
              _buildRoleCard(
                context: context,
                icon: Icons.delivery_dining,
                title: 'Agent',
                subtitle: 'Delivery & service agent',
                color: Colors.orange,
                onTap: () {
                  // Navigate to agent login
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreenUnified(userType: 'agent'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Guard card
              _buildRoleCard(
                context: context,
                icon: Icons.shield,
                title: 'Guard',
                subtitle: 'Security guard',
                color: Colors.green,
                onTap: () {
                  // Navigate to guard login only (no registration)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreenUnified(userType: 'guard'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
