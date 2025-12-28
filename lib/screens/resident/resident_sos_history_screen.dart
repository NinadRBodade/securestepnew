import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class ResidentSOSHistoryScreen extends StatefulWidget {
  const ResidentSOSHistoryScreen({super.key});

  @override
  State<ResidentSOSHistoryScreen> createState() => _ResidentSOSHistoryScreenState();
}

class _ResidentSOSHistoryScreenState extends State<ResidentSOSHistoryScreen> {
  List<Map<String, dynamic>> _sosEvents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSOSHistory();
  }

  Future<void> _loadSOSHistory() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      
      print('📡 Fetching SOS history with token: ${ApiConfig.token.substring(0, 20)}...');
      
      final response = await dio.get('/sos', queryParameters: {'mine': 'true'});
      
      print('✅ Response status: ${response.statusCode}');
      print('📊 Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data != null) {
        final status = response.data['status'];
        if (status == 'success') {
          if (mounted) {
            setState(() {
              final data = response.data['data'];
              // Handle both array and object with events property
              if (data is Map && data.containsKey('events')) {
                _sosEvents = List<Map<String, dynamic>>.from(data['events']);
                print('✅ Loaded ${_sosEvents.length} SOS events');
              } else if (data is List) {
                _sosEvents = List<Map<String, dynamic>>.from(data);
                print('✅ Loaded ${_sosEvents.length} SOS events');
              } else {
                _sosEvents = [];
                print('⚠️ No events found in response');
              }
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error loading SOS history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load SOS history: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'triggered':
        return Colors.red;
      case 'responded':
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'triggered':
        return Icons.emergency;
      case 'responded':
      case 'in_progress':
        return Icons.local_police;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Future<void> _viewGuardContact(String sosId) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      
      final response = await dio.get('/sos/$sosId/guard');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final guards = response.data['data']['guards'] as List;
        
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Guard Contacts'),
            content: guards.isEmpty
                ? const Text('No guards available')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: guards.map((guard) {
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.security),
                        ),
                        title: Text(guard['name'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📞 ${guard['phone'] ?? 'N/A'}'),
                            Text('📧 ${guard['email'] ?? 'N/A'}'),
                          ],
                        ),
                      );
                    }).toList(),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load guard contact: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSOSHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sosEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No SOS history',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your emergency alerts will appear here',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSOSHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: _sosEvents.length,
                    itemBuilder: (context, index) {
                      final event = _sosEvents[index];
                      final status = event['status'] ?? 'unknown';
                      final createdAt = event['createdAt'] ?? event['triggeredAt'];
                      final location = event['location'];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(status).withOpacity(0.2),
                            child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                          ),
                          title: Text(
                            event['description'] ?? 'Emergency Alert',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    createdAt != null
                                        ? DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.parse(createdAt))
                                        : 'Unknown time',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              if (location != null && location['address'] != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location['address'],
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone),
                            color: Colors.blue,
                            onPressed: () => _viewGuardContact(event['sosId'] ?? event['_id']),
                            tooltip: 'View Guard Contact',
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
