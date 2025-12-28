import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class AdminVerificationDashboard extends StatefulWidget {
  final String adminId;

  const AdminVerificationDashboard({Key? key, required this.adminId}) : super(key: key);

  @override
  State<AdminVerificationDashboard> createState() => _AdminVerificationDashboardState();
}

class _AdminVerificationDashboardState extends State<AdminVerificationDashboard> {
  List<dynamic> _pendingAgents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingAgents();
  }

  Future<void> _loadPendingAgents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/agent/verification/pending'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pendingAgents = data['agents'] ?? [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading agents: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveAgent(String agentId) async {
    // Show score input dialog
    double? score = await _showScoreDialog();
    if (score == null) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/agent/verification/approve/$agentId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'score': score,
          'adminId': widget.adminId,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agent approved successfully'), backgroundColor: Colors.green),
        );
        _loadPendingAgents();
      } else {
        if (!mounted) return;
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Approval failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectAgent(String agentId) async {
    // Show reason input dialog
    String? reason = await _showReasonDialog();
    if (reason == null || reason.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/agent/verification/reject/$agentId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agent rejected'), backgroundColor: Colors.orange),
        );
        _loadPendingAgents();
      } else {
        if (!mounted) return;
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Rejection failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<double?> _showScoreDialog() async {
    double score = 3.0;
    return showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Agent Score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate the agent from 0 to 5'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(score.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text(' / 5.0', style: TextStyle(fontSize: 18)),
                ],
              ),
              Slider(
                value: score,
                min: 0,
                max: 5,
                divisions: 10,
                label: score.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    score = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, score),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showReasonDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter reason for rejection...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Agents'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingAgents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 20),
                      const Text(
                        'No pending verifications',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingAgents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _pendingAgents.length,
                    itemBuilder: (context, index) {
                      final agent = _pendingAgents[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Agent Info
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      agent['name'][0].toUpperCase(),
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          agent['name'],
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        Text(agent['email'], style: TextStyle(color: Colors.grey.shade600)),
                                        Text(agent['phone'], style: TextStyle(color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 15),
                              
                              // Submitted Date
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 5),
                                    Text('Submitted: ${agent['submittedAt'] ?? 'N/A'}'),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 15),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _approveAgent(agent['id']),
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _rejectAgent(agent['id']),
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Reject'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
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
