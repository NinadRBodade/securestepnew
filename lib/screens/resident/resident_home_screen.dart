import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'resident_scan_qr_screen.dart';
import 'resident_scan_agent_face_screen.dart';
import 'resident_sos_screen.dart';
import 'qr_scanner_screen.dart';
import 'resident_profile_screen.dart';
import 'resident_settings_screen.dart';
import 'resident_sos_history_screen.dart';
import 'resident_emergency_contacts_screen.dart';
import 'resident_complaints_screen.dart';
import 'simple_qr_scanner.dart';

class ResidentHomeScreen extends StatelessWidget {
  final UserModel user;
  
  const ResidentHomeScreen({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Clear session
      await AuthService.clearSession();
      // Clear token
      ApiConfig.token = '';
      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ResidentProfileScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ResidentSettingsScreen()),
                );
              } else if (value == 'logout') {
                _logout(context);
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
            _buildWelcomeCard(user),
            const SizedBox(height: 24),
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(context, Icons.sos, 'SOS Alert', 'Emergency', Colors.red, 'sos'),
                  _buildActionCard(context, Icons.history, 'SOS History', 'Past alerts', Colors.orange, 'history'),
                  _buildActionCard(context, Icons.report_problem, 'Report Issue', 'Non-emergency', Colors.deepOrange, 'complaint'),
                  _buildActionCard(context, Icons.face_unlock_outlined, 'Scan Agent Face', 'Verify visitor', Colors.blue, 'scan_face'),
                  _buildActionCard(context, Icons.qr_code_scanner, 'Scan QR Code', 'QR verify', Colors.green, 'scan_qr'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(UserModel user) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green,
              child: Text(user.name[0], style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${user.name}!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user.email, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, Color color, String action) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          switch (action) {
            case 'sos':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ResidentSOSScreen(user: user)),
              );
              break;
            case 'history':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResidentSOSHistoryScreen()),
              );
              break;
            case 'profile':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResidentProfileScreen()),
              );
              break;
            case 'contacts':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResidentEmergencyContactsScreen()),
              );
              break;
            case 'complaint':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResidentComplaintsScreen()),
              );
              break;
            case 'scan_face':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResidentScanAgentFaceScreen()),
              );
              break;
            case 'scan_qr':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SimpleQRScanner()),
              );
              break;
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 40),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}