import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import 'agent_qr_screen.dart';
import 'agent_profile_screen.dart';
import 'agent_face_registration_screen.dart';
import 'agent_document_upload_screen.dart';
import 'agent_settings_screen.dart';

// Agent home screen
class AgentHomeScreen extends StatelessWidget {
  final UserModel user;
  
  const AgentHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgentProfileScreen(agentEmail: user.email),
                  ),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgentSettingsScreen(agentEmail: user.email),
                  ),
                );
              } else if (value == 'logout') {
                AuthService.clearSession();
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 12),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppConstants.primaryColor,
                      child: Text(
                        user.name[0],
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user.name}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action cards grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    icon: Icons.upload_file,
                    title: 'Upload Documents',
                    subtitle: 'Submit for verification',
                    color: Colors.orange,
                    onTap: () {
                      // Navigate to document upload
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AgentDocumentUploadScreen(
                            agentId: user.email,
                            agentName: user.name,
                            agentEmail: user.email,
                            agentPhone: user.phone ?? '0000000000',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.qr_code,
                    title: 'My QR Code',
                    subtitle: 'Show to verify',
                    color: Colors.blue,
                    onTap: () {
                      // Navigate to QR screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AgentQRScreen(agentEmail: user.email),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.face,
                    title: 'Register Face',
                    subtitle: 'Set up face ID',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AgentFaceRegistrationScreen(agentEmail: user.email),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.work,
                    title: 'My Jobs',
                    subtitle: 'View deliveries',
                    color: Colors.orange,
                    onTap: () {
                      _showComingSoonDialog(context, 'Job List');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Action card widget
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Coming soon dialog
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in Phase 2'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}