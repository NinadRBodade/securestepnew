import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/sos_service.dart';
import '../../models/sos_event_model.dart';

class SOSHistoryScreen extends StatefulWidget {
  const SOSHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SOSHistoryScreen> createState() => _SOSHistoryScreenState();
}

class _SOSHistoryScreenState extends State<SOSHistoryScreen> with SingleTickerProviderStateMixin {
  final SOSService _sosService = SOSService();
  String _selectedFilter = 'all';
  bool _isRefreshing = false;
  bool _isLoading = true;
  late AnimationController _rotationController;
  List<SOSEvent> _allAlerts = [];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _sosService.getSOSHistory();
      if (mounted) {
        setState(() {
          _allAlerts = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading SOS history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<SOSEvent> get _filteredAlerts {
    if (_selectedFilter == 'all') return _allAlerts;
    return _allAlerts.where((alert) => alert.status.toLowerCase() == _selectedFilter).toList();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    _rotationController.repeat();
    
    await _loadHistory();
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      _rotationController.stop();
      _rotationController.reset();
      setState(() => _isRefreshing = false);
    }
  }

  Map<String, dynamic> _getTypeConfig(String? description) {
    final desc = description?.toLowerCase() ?? '';
    
    if (desc.contains('medical')) {
      return {
        'icon': Icons.local_hospital,
        'gradient': const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
        'borderColor': const Color(0xFFEF4444),
      };
    } else if (desc.contains('suspicious')) {
      return {
        'icon': Icons.person_search,
        'gradient': const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        'borderColor': const Color(0xFFF59E0B),
      };
    } else if (desc.contains('theft')) {
      return {
        'icon': Icons.report_problem,
        'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
        'borderColor': const Color(0xFF8B5CF6),
      };
    } else if (desc.contains('fire')) {
      return {
        'icon': Icons.local_fire_department,
        'gradient': const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
        'borderColor': const Color(0xFFF97316),
      };
    } else if (desc.contains('violence')) {
      return {
        'icon': Icons.warning,
        'gradient': const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
        'borderColor': const Color(0xFFDC2626),
      };
    } else {
      return {
        'icon': Icons.emergency,
        'gradient': const LinearGradient(colors: [Color(0xFF64748B), Color(0xFF475569)]),
        'borderColor': const Color(0xFF64748B),
      };
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'active':
        return 'Active';
      case 'resolved':
        return 'Resolved';
      case 'cancelled':
        return 'Cancelled';
      default:
        return filter;
    }
  }

  String _getEmptyMessage() {
    if (_selectedFilter == 'all') {
      return "You don't have any alerts yet";
    }
    return "You don't have any ${_getFilterLabel(_selectedFilter).toLowerCase()} alerts";
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
              colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
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
          'SOS History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
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
        child: Column(
          children: [
            // Filter Tabs
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterTab('all'),
                    const SizedBox(width: 8),
                    _buildFilterTab('active'),
                    const SizedBox(width: 8),
                    _buildFilterTab('resolved'),
                    const SizedBox(width: 8),
                    _buildFilterTab('cancelled'),
                  ],
                ),
              ),
            ),

            // Alert List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAlerts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAlerts.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildAlertCard(_filteredAlerts[index], index),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String filter) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _getFilterLabel(filter),
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(SOSEvent alert, int index) {
    final typeConfig = _getTypeConfig(alert.description);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: typeConfig['borderColor'],
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: typeConfig['gradient'],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                typeConfig['icon'],
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Alert Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.description ?? 'Emergency Alert',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(alert.status),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Timestamp
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Color(0xFF4B5563)),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimestamp(alert.timestamp),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Location (if available)
                  if (alert.locationAddress != null && alert.locationAddress!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Color(0xFF4B5563)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            alert.locationAddress!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Responded By (only for resolved)
                  if (alert.status.toLowerCase() == 'resolved' && alert.guardId != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Responded by Guard',  
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData? icon;

    switch (status) {
      case 'active':
        bgColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        label = 'Active';
        icon = Icons.circle;
        break;
      case 'resolved':
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
        label = 'Resolved';
        icon = Icons.check;
        break;
      case 'cancelled':
        bgColor = const Color(0xFF9CA3AF);
        textColor = Colors.white;
        label = 'Cancelled';
        icon = Icons.close;
        break;
      default:
        bgColor = const Color(0xFF9CA3AF);
        textColor = Colors.white;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (status == 'active')
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, child) => Opacity(opacity: value, child: child),
              child: Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(left: 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              onEnd: () {
                if (mounted && status == 'active') {
                  setState(() {});
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 48,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Alerts Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _getEmptyMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
