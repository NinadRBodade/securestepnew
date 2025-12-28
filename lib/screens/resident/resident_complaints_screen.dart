import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class ResidentComplaintsScreen extends StatefulWidget {
  const ResidentComplaintsScreen({super.key});

  @override
  State<ResidentComplaintsScreen> createState() => _ResidentComplaintsScreenState();
}

class _ResidentComplaintsScreenState extends State<ResidentComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      
      final response = await dio.get('/complaints', queryParameters: {'mine': 'true'});
      
      if (response.statusCode == 200 && response.data != null) {
        final status = response.data['status'];
        if (status == 'success') {
          if (mounted) {
            setState(() {
              final data = response.data['data'];
              if (data is List) {
                _complaints = List<Map<String, dynamic>>.from(data);
              } else {
                _complaints = [];
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load complaints: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createComplaint() async {
    final descriptionController = TextEditingController();
    String selectedType = 'maintenance';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report Non-Emergency Issue'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Issue Type',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'guard_misbehaviour', child: Text('Guard Misbehaviour')),
                      DropdownMenuItem(value: 'agent_suspicious', child: Text('Agent Suspicious')),
                      DropdownMenuItem(value: 'maintenance', child: Text('Society Maintenance')),
                      DropdownMenuItem(value: 'noise_rules', child: Text('Noise / Rules Violation')),
                      DropdownMenuItem(value: 'unknown_visitors', child: Text('Repeated Unknown Visitors')),
                    ],
                    onChanged: (value) => setDialogState(() => selectedType = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                      hintText: 'Describe the issue in detail...',
                    ),
                    maxLines: 5,
                    validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
                    dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
                    
                    final response = await dio.post('/complaints', data: {
                      'type': selectedType,
                      'description': descriptionController.text.trim(),
                    });
                    
                    if (response.statusCode == 201 && response.data != null && response.data['status'] == 'success') {
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    print('Create complaint error: $e');
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create complaint. Please try again.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadComplaints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'guard_misbehaviour':
        return Icons.person_off;
      case 'agent_suspicious':
        return Icons.warning;
      case 'maintenance':
        return Icons.build;
      case 'noise_rules':
        return Icons.volume_up;
      case 'unknown_visitors':
        return Icons.people_outline;
      default:
        return Icons.report_problem;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'guard_misbehaviour':
        return 'Guard Misbehaviour';
      case 'agent_suspicious':
        return 'Agent Suspicious';
      case 'maintenance':
        return 'Society Maintenance';
      case 'noise_rules':
        return 'Noise / Rules Violation';
      case 'unknown_visitors':
        return 'Repeated Unknown Visitors';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComplaints,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createComplaint,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.report),
        label: const Text('Report Issue'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.report_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No complaints',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Report non-emergency issues here',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createComplaint,
                        icon: const Icon(Icons.report),
                        label: const Text('Report Issue'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadComplaints,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: _complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = _complaints[index];
                      final status = complaint['status'] ?? 'submitted';
                      final type = complaint['type'] ?? 'maintenance';
                      final createdAt = complaint['createdAt'];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(status).withOpacity(0.2),
                            child: Icon(_getTypeIcon(type), color: _getStatusColor(status)),
                          ),
                          title: Text(
                            _getTypeLabel(type),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                complaint['description'] ?? 'No description',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    createdAt != null
                                        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAt))
                                        : 'Unknown',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 12),
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
