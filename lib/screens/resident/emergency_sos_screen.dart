import 'package:flutter/material.dart';
import 'dart:async';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({Key? key}) : super(key: key);

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> with SingleTickerProviderStateMixin {
  String? _selectedEmergencyType;
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<EmergencyType> _emergencyTypes = [
    EmergencyType(
      name: 'Suspicious Person',
      icon: Icons.person_search,
      gradient: const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    EmergencyType(
      name: 'Medical Emergency',
      icon: Icons.local_hospital,
      gradient: const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    EmergencyType(
      name: 'Fire',
      icon: Icons.local_fire_department,
      gradient: const LinearGradient(
        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    EmergencyType(
      name: 'Theft',
      icon: Icons.report_problem,
      gradient: const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    EmergencyType(
      name: 'Violence',
      icon: Icons.warning,
      gradient: const LinearGradient(
        colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    EmergencyType(
      name: 'Other',
      icon: Icons.emergency,
      gradient: const LinearGradient(
        colors: [Color(0xFF64748B), Color(0xFF475569)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    // Start fade-in animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _selectEmergencyType(String type) {
    setState(() {
      _selectedEmergencyType = type;
    });
  }

  Future<void> _sendSOS() async {
    if (_selectedEmergencyType == null) return;

    setState(() => _isLoading = true);

    // Simulate sending SOS (2 seconds delay)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
              ),
              const SizedBox(width: 12),
              const Text('SOS Alert Sent!'),
            ],
          ),
          content: const Text('Emergency services have been notified. Help is on the way.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency SOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Banner
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFEF4444).withOpacity(0.1),
                          const Color(0xFFFEF2F2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Emergency Alert System',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Use only in case of genuine emergency',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Section Title
                const Text(
                  'Select Emergency Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 16),

                // Emergency Type Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _emergencyTypes.length,
                  itemBuilder: (context, index) {
                    final emergencyType = _emergencyTypes[index];
                    final isSelected = _selectedEmergencyType == emergencyType.name;

                    return GestureDetector(
                      onTap: () => _selectEmergencyType(emergencyType.name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon Container
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: emergencyType.gradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                emergencyType.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Label
                            Text(
                              emergencyType.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),

                            // Checkmark
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Additional Details
                const Text(
                  'Additional Details (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _detailsController,
                  maxLines: 5,
                  maxLength: 200,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Describe the emergency situation...',
                    hintStyle: TextStyle(
                      color: const Color(0xFF4B5563).withOpacity(0.6),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: const Color(0xFF4B5563),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'This will alert guards and police with your location',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Send SOS Button
              GestureDetector(
                onTapDown: _selectedEmergencyType != null && !_isLoading
                    ? (_) => setState(() {})
                    : null,
                onTapUp: _selectedEmergencyType != null && !_isLoading
                    ? (_) => setState(() {})
                    : null,
                onTapCancel: () => setState(() {}),
                onTap: _selectedEmergencyType != null && !_isLoading
                    ? _sendSOS
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _selectedEmergencyType != null && !_isLoading
                        ? const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFF9CA3AF),
                              const Color(0xFF9CA3AF),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _selectedEmergencyType != null && !_isLoading
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'SEND SOS ALERT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
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
}

class EmergencyType {
  final String name;
  final IconData icon;
  final Gradient gradient;

  const EmergencyType({
    required this.name,
    required this.icon,
    required this.gradient,
  });
}
