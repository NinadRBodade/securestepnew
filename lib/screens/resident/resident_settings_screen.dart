import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../config/api_config.dart';

class ResidentSettingsScreen extends StatefulWidget {
  const ResidentSettingsScreen({super.key});

  @override
  State<ResidentSettingsScreen> createState() => _ResidentSettingsScreenState();
}

class _ResidentSettingsScreenState extends State<ResidentSettingsScreen> with TickerProviderStateMixin {
  bool _pushEnabled = true;
  bool _smsEnabled = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Design System Colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color darkBlue = Color(0xFF2563EB);
  static const Color indigoColor = Color(0xFF4F46E5);
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color emeraldColor = Color(0xFF10B981);
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color tealColor = Color(0xFF0D9488);
  static const Color amberColor = Color(0xFFF59E0B);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber800 = Color(0xFF92400E);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray900 = Color(0xFF111827);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    // Don't auto-load settings to avoid network errors on navigation
    // User can manually refresh if needed
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _updateSettings() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      
      final response = await dio.put('/residents/settings', data: {
        'pushEnabled': _pushEnabled,
        'smsEnabled': _smsEnabled,
      });
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Settings updated successfully'),
              backgroundColor: emeraldColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _togglePush(bool value) {
    // Prevent disabling if it's the last enabled method
    if (_pushEnabled && !_smsEnabled) {
      return;
    }
    setState(() => _pushEnabled = value);
    _updateSettings();
  }

  void _toggleSMS(bool value) {
    // Prevent disabling if it's the last enabled method
    if (_smsEnabled && !_pushEnabled) {
      return;
    }
    setState(() => _smsEnabled = value);
    _updateSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gray50, blue50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAlertPreferencesCard(),
                          if (!_pushEnabled || !_smsEnabled) ...[
                            const SizedBox(height: 24),
                            _buildWarningMessage(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Notification Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Notification Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertPreferencesCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, gray50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alert Preferences',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: gray900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how you want to receive emergency notifications',
              style: TextStyle(
                fontSize: 14,
                color: gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _buildNotificationOption(
              enabled: _pushEnabled,
              icon: Icons.notifications,
              title: 'Push Notifications',
              description: 'Receive alerts via push notifications',
              gradient: const LinearGradient(colors: [primaryBlue, indigoColor]),
              bgGradient: const LinearGradient(colors: [blue50, indigo50]),
              borderColor: primaryBlue.withOpacity(0.3),
              onToggle: _togglePush,
              delay: 500,
            ),
            const SizedBox(height: 16),
            _buildNotificationOption(
              enabled: _smsEnabled,
              icon: Icons.message,
              title: 'SMS Notifications',
              description: 'Receive alerts via SMS',
              gradient: const LinearGradient(colors: [emeraldColor, tealColor]),
              bgGradient: const LinearGradient(colors: [emerald50, teal50]),
              borderColor: emerald300,
              onToggle: _toggleSMS,
              delay: 600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption({
    required bool enabled,
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required Gradient bgGradient,
    required Color borderColor,
    required Function(bool) onToggle,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-50 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: enabled ? bgGradient : const LinearGradient(colors: [gray50, gray50]),
          border: Border.all(
            color: enabled ? borderColor : gray200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: enabled ? gradient : const LinearGradient(colors: [gray300, gray300]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: gray600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => onToggle(!enabled),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 64,
                height: 36,
                decoration: BoxDecoration(
                  gradient: enabled ? gradient : const LinearGradient(colors: [gray300, gray300]),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (enabled)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: emeraldColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningMessage() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [amber50, Color(0xFFFEF3C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: amber300, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: amberColor.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: amberColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'At least one notification method must be enabled for emergency alerts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: amber800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
