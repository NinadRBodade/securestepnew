import 'package:flutter/material.dart';

class AgentStartJobScreen extends StatefulWidget {
  final String agentEmail;
  
  const AgentStartJobScreen({super.key, required this.agentEmail});

  @override
  State<AgentStartJobScreen> createState() => _AgentStartJobScreenState();
}

class _AgentStartJobScreenState extends State<AgentStartJobScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
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

  // Dummy job data
  final List<Map<String, dynamic>> _availableJobs = [
    {
      'id': 'JOB001',
      'title': 'Delivery Service',
      'client': 'John Delivery',
      'location': 'Tower A, Floor 5',
      'time': '10:00 AM',
      'duration': '30 mins',
      'status': 'Available',
      'priority': 'High',
      'initials': 'JD',
      'color': blueColor,
    },
    {
      'id': 'JOB002',
      'title': 'Maintenance Work',
      'client': 'Sarah Guest',
      'location': 'Tower B, Floor 12',
      'time': '11:30 AM',
      'duration': '1 hour',
      'status': 'Available',
      'priority': 'Medium',
      'initials': 'SG',
      'color': emeraldColor,
    },
    {
      'id': 'JOB003',
      'title': 'Service Request',
      'client': 'Mike Service',
      'location': 'Tower C, Floor 8',
      'time': '02:00 PM',
      'duration': '45 mins',
      'status': 'Available',
      'priority': 'Low',
      'initials': 'MS',
      'color': orangeColor,
    },
    {
      'id': 'JOB004',
      'title': 'Package Delivery',
      'client': 'Emma Wilson',
      'location': 'Tower A, Floor 3',
      'time': '03:30 PM',
      'duration': '20 mins',
      'status': 'Available',
      'priority': 'High',
      'initials': 'EW',
      'color': redColor,
    },
    {
      'id': 'JOB005',
      'title': 'Inspection Visit',
      'client': 'Robert Brown',
      'location': 'Tower D, Floor 15',
      'time': '04:00 PM',
      'duration': '1.5 hours',
      'status': 'Available',
      'priority': 'Medium',
      'initials': 'RB',
      'color': tealColor,
    },
  ];

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
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: gray900),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Available Jobs',
          style: TextStyle(
            color: gray900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: gray900),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 24),
              const Text(
                'Today\'s Jobs',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: gray900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              ..._availableJobs.asMap().entries.map((entry) {
                final index = entry.key;
                final job = entry.value;
                return _buildJobCard(job, index);
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, blueColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Available\nJobs', '${_availableJobs.length}'),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildSummaryItem('Total\nDuration', '4.5 hrs'),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildSummaryItem('High\nPriority', '2'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, int index) {
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
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showJobDetails(job),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: job['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            job['initials'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: job['color'],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    job['title'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: gray900,
                                    ),
                                  ),
                                ),
                                _buildPriorityBadge(job['priority']),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job['client'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: gray500.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildJobInfo(Icons.location_on_outlined, job['location']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildJobInfo(Icons.access_time, job['time']),
                      ),
                      Expanded(
                        child: _buildJobInfo(Icons.timer_outlined, job['duration']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startJob(job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: job['color'],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Accept Job',
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
        ),
      ),
    );
  }

  Widget _buildJobInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: gray500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: gray600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'High':
        color = redColor;
        break;
      case 'Medium':
        color = orangeColor;
        break;
      default:
        color = emeraldColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _startJob(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Accept Job'),
        content: Text('Do you want to accept "${job['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Job "${job['title']}" accepted!'),
                  backgroundColor: emeraldColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showJobDetails(Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: gray500.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              job['title'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Job ID: ${job['id']}',
              style: const TextStyle(
                fontSize: 14,
                color: gray500,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Client', job['client']),
            const SizedBox(height: 16),
            _buildDetailRow('Location', job['location']),
            const SizedBox(height: 16),
            _buildDetailRow('Time', job['time']),
            const SizedBox(height: 16),
            _buildDetailRow('Duration', job['duration']),
            const SizedBox(height: 16),
            _buildDetailRow('Priority', job['priority']),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: gray600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: gray900,
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Filter Jobs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Jobs'),
              leading: Radio(value: 0, groupValue: 0, onChanged: (v) {}),
            ),
            ListTile(
              title: const Text('High Priority'),
              leading: Radio(value: 1, groupValue: 0, onChanged: (v) {}),
            ),
            ListTile(
              title: const Text('Medium Priority'),
              leading: Radio(value: 2, groupValue: 0, onChanged: (v) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
