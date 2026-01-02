import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../splash_screen.dart';
import 'resident_scan_qr_screen.dart';
import 'resident_scan_agent_face_screen.dart';
import 'emergency_sos_screen.dart';
import 'resident_profile_screen.dart';
import 'resident_settings_screen.dart';
import 'sos_history_screen.dart';
import 'my_complaints_screen.dart';

class ResidentHomeScreen extends StatefulWidget {
  final UserModel user;
  
  const ResidentHomeScreen({super.key, required this.user});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _blobController;
  late Animation<double> _fadeAnimation;

  // Design System Colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color indigoColor = Color(0xFF4F46E5);
  static const Color emeraldColor = Color(0xFF10B981);
  static const Color tealColor = Color(0xFF14B8A6);
  static const Color redColor = Color(0xFFEF4444);
  static const Color amberColor = Color(0xFFF59E0B);
  static const Color bgColor = Color(0xFFF9FAFB);
  static const Color gray900 = Color(0xFF111827);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray100 = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _blobController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: redColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService.clearSession();
      ApiConfig.token = '';
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Animated Background Blobs
          _buildAnimatedBlobs(),
          
          // Main Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildStatsSection(),
                        const SizedBox(height: 32),
                        _buildQuickActionsHeader(),
                        const SizedBox(height: 16),
                        _buildQuickActionsGrid(),
                        const SizedBox(height: 32),
                        _buildRecentActivityHeader(),
                        const SizedBox(height: 16),
                        _buildRecentActivityList(),
                        const SizedBox(height: 24),
                        _buildEmergencyBanner(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Animated Background Blobs
  Widget _buildAnimatedBlobs() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _blobController,
          builder: (context, child) {
            return Positioned(
              top: -100 + (_blobController.value * 50),
              right: -100 + (_blobController.value * 30),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.1),
                      indigoColor.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _blobController,
          builder: (context, child) {
            return Positioned(
              bottom: -150 + (_blobController.value * 40),
              left: -120 + (_blobController.value * 25),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      emeraldColor.withOpacity(0.08),
                      tealColor.withOpacity(0.04),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Sliver App Bar
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.95),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: gray100, width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hi, ${widget.user.name.split(' ')[0]}! 👋',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: gray900,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Welcome back to Secure Step',
                        style: TextStyle(
                          fontSize: 15,
                          color: gray500,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ResidentProfileScreen()),
                        );
                      },
                      child: Stack(
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
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                gradient: const LinearGradient(
                                  colors: [emeraldColor, tealColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: emeraldColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  widget.user.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: emeraldColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined, size: 24),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ResidentSettingsScreen()),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: redColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: gray900),
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
                  Icon(Icons.logout, size: 20, color: redColor),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: redColor)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Stats Section
  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people_outline,
              value: '24',
              label: 'Total\nVisitors',
              trend: '+12%',
              trendUp: true,
              gradient: const LinearGradient(colors: [primaryBlue, indigoColor]),
              delay: 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.verified_user_outlined,
              value: '18',
              label: 'Verified\nToday',
              trend: '+8%',
              trendUp: true,
              gradient: const LinearGradient(colors: [emeraldColor, tealColor]),
              delay: 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.pending_outlined,
              value: '3',
              label: 'Pending',
              trend: '-5%',
              trendUp: false,
              gradient: const LinearGradient(colors: [amberColor, Color(0xFFF97316)]),
              delay: 200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required String trend,
    required bool trendUp,
    required Gradient gradient,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(
            opacity: animValue,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: gray900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: gray500,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  trendUp ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: trendUp ? emeraldColor : redColor,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: trendUp ? emeraldColor : redColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Quick Actions Header
  Widget _buildQuickActionsHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Quick Actions',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: gray900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  // Quick Actions Grid
  Widget _buildQuickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
        children: [
          _buildQuickActionCard(
            icon: Icons.warning_amber_rounded,
            title: 'Emergency SOS',
            subtitle: 'Instant alert',
            gradient: const LinearGradient(colors: [redColor, Color(0xFFDC2626)]),
            delay: 0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmergencySOSScreen()),
              );
            },
          ),
          _buildQuickActionCard(
            icon: Icons.face_outlined,
            title: 'Face Verify',
            subtitle: 'Scan visitor',
            gradient: const LinearGradient(colors: [primaryBlue, indigoColor]),
            delay: 100,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResidentScanAgentFaceScreen()),
              );
            },
          ),
          _buildQuickActionCard(
            icon: Icons.qr_code_scanner,
            title: 'QR Scan',
            subtitle: 'Quick verify',
            gradient: const LinearGradient(colors: [emeraldColor, tealColor]),
            delay: 200,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResidentScanQRScreen()),
              );
            },
          ),
          _buildQuickActionCard(
            icon: Icons.report_problem_outlined,
            title: 'Report Issue',
            subtitle: 'Non-emergency',
            gradient: const LinearGradient(colors: [amberColor, Color(0xFFF97316)]),
            delay: 300,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyComplaintsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Recent Activity Header
  Widget _buildRecentActivityHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: gray900,
              letterSpacing: -0.5,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SOSHistoryScreen()),
              );
            },
            child: const Text(
              'View All',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Recent Activity List
  Widget _buildRecentActivityList() {
    final activities = [
      {'name': 'John', 'role': 'Delivery', 'time': '2 mins ago', 'status': 'Verified', 'initials': 'JD'},
      {'name': 'Sarah', 'role': 'Guest', 'time': '15 mins ago', 'status': 'Verified', 'initials': 'SG'},
      {'name': 'Mike', 'role': 'Service', 'time': '1 hour ago', 'status': 'Pending', 'initials': 'MS'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(-50 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: gray900.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Center(
                      child: Text(
                        activity['initials']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: gray900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['name']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activity['role']} • ${activity['time']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(activity['status']!),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isVerified = status == 'Verified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified ? emeraldColor.withOpacity(0.1) : amberColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.schedule,
            size: 14,
            color: isVerified ? emeraldColor : amberColor,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isVerified ? emeraldColor : amberColor,
            ),
          ),
        ],
      ),
    );
  }

  // Emergency Banner
  Widget _buildEmergencyBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmergencySOSScreen()),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [redColor, Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: redColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.1),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need Help?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap here for emergency assistance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bottom Navigation
  Widget _buildBottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0, true),
          _buildNavItem(Icons.history, 'History', 1, false),
          _buildNavItem(Icons.qr_code_scanner, 'Scan', 2, false),
          _buildNavItem(Icons.person_outline, 'Profile', 3, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SOSHistoryScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResidentScanQRScreen()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResidentProfileScreen()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [primaryBlue, indigoColor]) : null,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : gray500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}