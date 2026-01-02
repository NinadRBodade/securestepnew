import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../splash_screen.dart';
import 'agent_qr_screen.dart';
import 'agent_profile_screen.dart';
import 'agent_face_registration_screen.dart';
import 'upload_documents_screen.dart';
import 'agent_settings_screen.dart';
import 'agent_start_job_screen.dart';

// Premium Agent Dashboard with Material 3
class AgentHomeScreen extends StatefulWidget {
  final UserModel user;
  
  const AgentHomeScreen({super.key, required this.user});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _blobController;
  late Animation<double> _fadeAnimation;

  // Design System Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color blueColor = Color(0xFF3B82F6);
  static const Color emeraldColor = Color(0xFF10B981);
  static const Color tealColor = Color(0xFF14B8A6);
  static const Color orangeColor = Color(0xFFF59E0B);
  static const Color redColor = Color(0xFFEF4444);
  static const Color gray900 = Color(0xFF111827);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray500 = Color(0xFF6B7280);

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated Background Blobs
          _buildAnimatedBlobs(size),
          
          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 32),
                      _buildStatsSection(),
                      const SizedBox(height: 32),
                      _buildQuickActionsHeader(),
                      const SizedBox(height: 16),
                      _buildQuickActionsGrid(context),
                      const SizedBox(height: 32),
                      _buildRecentJobsHeader(),
                      const SizedBox(height: 16),
                      _buildRecentJobsList(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Animated Background Blobs
  Widget _buildAnimatedBlobs(Size size) {
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
                      blueColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05),
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

  // Header Section
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${widget.user.name.split(' ')[0]}! 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: gray900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Welcome to Agent Portal',
                style: TextStyle(
                  fontSize: 15,
                  color: gray500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showUserDetailsDialog(context),
              child: Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: const LinearGradient(
                        colors: [primaryColor, blueColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
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
                icon: const Icon(Icons.settings_outlined, size: 24),
                onPressed: () {
                  _showSettingsDialog(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Stats Section
  Widget _buildStatsSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.work_outline,
              number: 12,
              label: 'Active\nJobs',
              trend: '+15%',
              trendUp: true,
              color: blueColor,
              delay: 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline,
              number: 8,
              label: 'Completed\nToday',
              trend: '+22%',
              trendUp: true,
              color: emeraldColor,
              delay: 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.pending_outlined,
              number: 5,
              label: 'Pending\nRequests',
              trend: '-8%',
              trendUp: false,
              color: orangeColor,
              delay: 200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int number,
    required String label,
    required String trend,
    required bool trendUp,
    required Color color,
    required int delay,
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
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: number),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: gray900,
                    letterSpacing: -1,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: gray600,
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
    return const Text(
      'Quick Actions',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: gray900,
        letterSpacing: -0.5,
      ),
    );
  }

  // Quick Actions Grid
  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.88,
      children: [
        _buildActionCard(
          context: context,
          icon: Icons.play_arrow,
          title: 'Start Job',
          subtitle: 'Begin new task',
          gradient: const LinearGradient(
            colors: [redColor, Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          delay: 0,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AgentStartJobScreen(agentEmail: widget.user.email),
              ),
            );
          },
        ),
        _buildActionCard(
          context: context,
          icon: Icons.qr_code_2,
          title: 'My QR Code',
          subtitle: 'Show to verify',
          gradient: const LinearGradient(
            colors: [blueColor, primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          delay: 100,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AgentQRScreen(agentEmail: widget.user.email),
              ),
            );
          },
        ),
        _buildActionCard(
          context: context,
          icon: Icons.upload_file,
          title: 'Upload Documents',
          subtitle: 'Submit files',
          gradient: const LinearGradient(
            colors: [emeraldColor, tealColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          delay: 200,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UploadDocumentsScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          context: context,
          icon: Icons.face,
          title: 'Register Face',
          subtitle: 'Setup biometric',
          gradient: const LinearGradient(
            colors: [orangeColor, Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          delay: 300,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AgentFaceRegistrationScreen(agentEmail: widget.user.email),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
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
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 32,
                    ),
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

  // Recent Jobs Header
  Widget _buildRecentJobsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Jobs',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: gray900,
            letterSpacing: -0.5,
          ),
        ),
        TextButton(
          onPressed: () {
            _showComingSoonDialog(context, 'View All Jobs');
          },
          child: const Text(
            'View All',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // Recent Jobs List
  Widget _buildRecentJobsList() {
    final jobs = [
      {
        'name': 'John',
        'role': 'Delivery',
        'time': '5 mins ago',
        'status': 'Completed',
        'initials': 'JD',
      },
      {
        'name': 'Sarah',
        'role': 'Maintenance',
        'time': '15 mins ago',
        'status': 'In Progress',
        'initials': 'SG',
      },
      {
        'name': 'Mike',
        'role': 'Service',
        'time': '1 hour ago',
        'status': 'Pending',
        'initials': 'MS',
      },
    ];

    return Column(
      children: jobs.asMap().entries.map((entry) {
        final index = entry.key;
        final job = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(50 * (1 - value), 0),
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
                      job['initials']!,
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
                        job['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: gray900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${job['role']} • ${job['time']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(job['status']!),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Completed':
        bgColor = emeraldColor.withOpacity(0.1);
        textColor = emeraldColor;
        icon = Icons.check_circle;
        break;
      case 'In Progress':
        bgColor = blueColor.withOpacity(0.1);
        textColor = blueColor;
        icon = Icons.hourglass_empty;
        break;
      case 'Pending':
        bgColor = orangeColor.withOpacity(0.1);
        textColor = orangeColor;
        icon = Icons.schedule;
        break;
      default:
        bgColor = gray500.withOpacity(0.1);
        textColor = gray500;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
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
          _buildNavItem(Icons.work_outline, 'Jobs', 1, false),
          _buildNavItem(Icons.qr_code_2, 'My QR', 2, false),
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
            MaterialPageRoute(
              builder: (context) => AgentStartJobScreen(agentEmail: widget.user.email),
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgentQRScreen(agentEmail: widget.user.email),
            ),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgentProfileScreen(agentEmail: widget.user.email),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? primaryColor : gray500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? primaryColor : gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // User Details Dialog
  void _showUserDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    colors: [primaryColor, blueColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.user.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: gray500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.phone,
                style: const TextStyle(
                  fontSize: 14,
                  color: gray500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgentProfileScreen(agentEmail: widget.user.email),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.person, color: Colors.white),
                  label: const Text(
                    'View Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  // Settings Dialog
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: gray900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_outlined, color: primaryColor),
              title: const Text('Notification Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgentSettingsScreen(agentEmail: widget.user.email),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: redColor),
              title: const Text(
                'Logout',
                style: TextStyle(color: redColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Logout Confirmation
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              await AuthService.clearSession();
              ApiConfig.token = '';
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: redColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Coming Soon Dialog
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in the next update'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}