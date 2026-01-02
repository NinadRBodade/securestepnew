import 'package:flutter/material.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({Key? key}) : super(key: key);

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  late AnimationController _rotationController;
  
  // Empty state by default
  final List<dynamic> _complaints = [];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    _rotationController.repeat();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      _rotationController.stop();
      _rotationController.reset();
      setState(() => _isRefreshing = false);
    }
  }

  void _showReportIssueModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReportIssueModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF2563EB), Color(0xFF0891B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'My Complaints',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Track your reports',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          RotationTransition(
            turns: _rotationController,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isRefreshing ? null : _handleRefresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _complaints.isEmpty ? _buildEmptyState() : _buildComplaintsList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportIssueModal,
        icon: const Icon(Icons.message, color: Colors.white),
        label: const Text(
          'Report Issue',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFF97316),
      ),
    );
  }

  Widget _buildEmptyState() {
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.message_outlined,
                  size: 64,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'No Complaints Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Report non-emergency issues and track their status here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showReportIssueModal,
                icon: const Icon(Icons.message, color: Colors.white),
                label: const Text(
                  'Report Issue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintsList() {
    // Future implementation
    return const Center(child: Text('Complaints list will appear here'));
  }
}

class ReportIssueModal extends StatefulWidget {
  const ReportIssueModal({Key? key}) : super(key: key);

  @override
  State<ReportIssueModal> createState() => _ReportIssueModalState();
}

class _ReportIssueModalState extends State<ReportIssueModal> {
  String? _selectedIssueType;
  String? _selectedSubmitTo;
  final TextEditingController _descriptionController = TextEditingController();

  final List<IssueType> _issueTypes = [
    IssueType(
      value: 'maintenance',
      label: 'Society Maintenance',
      icon: Icons.construction,
    ),
    IssueType(
      value: 'guard',
      label: 'Guard Misbehaviour',
      icon: Icons.shield_outlined,
    ),
    IssueType(
      value: 'agent',
      label: 'Agent Suspicious',
      icon: Icons.person_search,
    ),
    IssueType(
      value: 'noise',
      label: 'Noise / Rules Violation',
      icon: Icons.volume_up,
    ),
    IssueType(
      value: 'visitors',
      label: 'Repeated Unknown Visitors',
      icon: Icons.group,
    ),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isFormComplete {
    return _selectedIssueType != null &&
        _descriptionController.text.trim().isNotEmpty &&
        _selectedSubmitTo != null;
  }

  void _handleSubmit() {
    if (!_isFormComplete) return;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Complaint submitted successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF2563EB), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Report Issue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Non-emergency complaints only',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content (Scrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Issue Type Dropdown
                  const Text(
                    'Issue Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedIssueType,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Select issue type',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        items: _issueTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type.value,
                            child: Row(
                              children: [
                                Icon(type.icon, size: 20, color: const Color(0xFF6B7280)),
                                const SizedBox(width: 12),
                                Text(
                                  type.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedIssueType = value);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Field
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    maxLength: 300,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Describe the issue in detail...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF4F46E5),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit To Section
                  const Text(
                    'Submit To',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSubmitToCard(
                          icon: Icons.admin_panel_settings,
                          label: 'Admin',
                          value: 'admin',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSubmitToCard(
                          icon: Icons.security,
                          label: 'Guard',
                          value: 'guard',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Bottom Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            foregroundColor: const Color(0xFF6B7280),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isFormComplete ? _handleSubmit : null,
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                          label: const Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFormComplete
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFF9CA3AF),
                            disabledBackgroundColor: const Color(0xFF9CA3AF),
                            elevation: _isFormComplete ? 2 : 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitToCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedSubmitTo == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedSubmitTo = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IssueType {
  final String value;
  final String label;
  final IconData icon;

  const IssueType({
    required this.value,
    required this.label,
    required this.icon,
  });
}
