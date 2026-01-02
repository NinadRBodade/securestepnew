import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/constants.dart';

class AgentSettingsScreen extends StatefulWidget {
  final String agentEmail;
  
  const AgentSettingsScreen({super.key, required this.agentEmail});

  @override
  State<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends State<AgentSettingsScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _entryExitNotifications = true;
  bool _verificationNotifications = true;
  bool _securityAlerts = false;
  bool _systemUpdates = true;
  bool _isSaving = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Design System Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color blueColor = Color(0xFF3B82F6);
  static const Color emeraldColor = Color(0xFF10B981);
  static const Color amberColor = Color(0xFFF59E0B);
  static const Color gray900 = Color(0xFF111827);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color bgLight = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _loadSettings();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  int get _activeNotificationsCount {
    int count = 0;
    if (_entryExitNotifications) count++;
    if (_verificationNotifications) count++;
    if (_securityAlerts) count++;
    if (_systemUpdates) count++;
    return count;
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final url = '${AppConstants.baseUrl}/api/agent/${Uri.encodeComponent(widget.agentEmail)}';
      print('Loading settings from: $url'); // Debug log
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final agent = data['agent'];
        
        if (mounted && agent['notificationSettings'] != null) {
          setState(() {
            _entryExitNotifications = agent['notificationSettings']['entryExit'] ?? true;
            _verificationNotifications = agent['notificationSettings']['verification'] ?? true;
          });
        }
      } else {
        print('Failed to load settings: ${response.statusCode}');
        // Don't show error, just use default values
      }
    } catch (e) {
      print('Error loading settings: $e');
      // Silently fail and use default values
      // This prevents showing errors on first load when settings don't exist yet
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final url = '${AppConstants.baseUrl}/api/agent/${Uri.encodeComponent(widget.agentEmail)}/settings';
      print('Saving settings to: $url'); // Debug log
      
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'notificationSettings': {
            'entryExit': _entryExitNotifications,
            'verification': _verificationNotifications,
          }
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection and ensure the backend server is running.');
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
        }
      } else {
        throw Exception('Server returned error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to save settings';
        if (e.toString().contains('SocketException') || e.toString().contains('Network is unreachable')) {
          errorMessage = 'Cannot connect to server. Please check:\n1. Backend server is running\n2. Your device is on the same network\n3. Firewall settings allow the connection';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // Background gradient blobs
          _buildBackgroundEffects(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                _buildMainCard(),
                                const SizedBox(height: 20),
                                _buildInfoCard(),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Background Effects
  Widget _buildBackgroundEffects() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  blueColor.withOpacity(0.05),
                  primaryColor.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -120,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.04),
                  blueColor.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Header with gradient
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, blueColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main Card with settings
  Widget _buildMainCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(),
          const Divider(height: 1, thickness: 1),
          _buildNotificationTile(
            icon: Icons.login,
            iconColor: blueColor,
            title: 'Entry / Exit Updates',
            description: 'Get notified when you check in or check out',
            value: _entryExitNotifications,
            onChanged: (value) {
              setState(() => _entryExitNotifications = value);
            },
          ),
          _buildNotificationTile(
            icon: Icons.verified_user_outlined,
            iconColor: emeraldColor,
            title: 'Verification Status Updates',
            description: 'Get notified about document verification status',
            value: _verificationNotifications,
            onChanged: (value) {
              setState(() => _verificationNotifications = value);
            },
          ),
          _buildNotificationTile(
            icon: Icons.notifications_active_outlined,
            iconColor: amberColor,
            title: 'Security Alerts',
            description: 'Important security notifications and warnings',
            value: _securityAlerts,
            onChanged: (value) {
              setState(() => _securityAlerts = value);
            },
          ),
          _buildNotificationTile(
            icon: Icons.check_circle_outline,
            iconColor: primaryColor,
            title: 'System Updates',
            description: 'Updates about new features and improvements',
            value: _systemUpdates,
            onChanged: (value) {
              setState(() => _systemUpdates = value);
            },
            isLast: true,
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // Card Header
  Widget _buildCardHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: gray900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage your notification preferences',
                  style: TextStyle(
                    fontSize: 14,
                    color: gray500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                Text(
                  '$_activeNotificationsCount',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Notification Tile
  Widget _buildNotificationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(20 * (1 - animValue), 0),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: value ? iconColor.withOpacity(0.03) : Colors.transparent,
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(color: gray500.withOpacity(0.1)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 26,
                    ),
                  ),
                  if (value)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: emeraldColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: gray500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: iconColor,
                  activeTrackColor: iconColor.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Save Button
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryColor, blueColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              alignment: Alignment.center,
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Saving...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Info Card
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: blueColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: blueColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: blueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.info_outline,
              color: blueColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: gray900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'You can customize which notifications you receive. Make sure notifications are enabled in your device settings.',
                  style: TextStyle(
                    fontSize: 13,
                    color: gray600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
