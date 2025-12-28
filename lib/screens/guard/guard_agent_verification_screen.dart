import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';

class GuardAgentVerificationScreen extends StatefulWidget {
  const GuardAgentVerificationScreen({super.key});

  @override
  State<GuardAgentVerificationScreen> createState() => _GuardAgentVerificationScreenState();
}

class _GuardAgentVerificationScreenState extends State<GuardAgentVerificationScreen> {
  List<dynamic> _pendingAgents = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      
      if (_token != null) {
        await _fetchPendingAgents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading: $e')),
        );
      }
    }
  }

  Future<void> _fetchPendingAgents() async {
    if (!mounted) return;
    
    setState(() => _loading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/guard/agents/pending'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _pendingAgents = data['data'] ?? [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading agents')),
        );
      }
    }
  }

  Future<void> _verifyAgent(String agentId) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/v1/guard/agents/$agentId/verify'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agent verified successfully')),
          );
          await _fetchPendingAgents();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error verifying agent')),
        );
      }
    }
  }

  Future<void> _rejectAgent(String agentId) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/v1/guard/agents/$agentId/reject'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agent rejected')),
          );
          await _fetchPendingAgents();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error rejecting agent')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Agents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingAgents,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingAgents.isEmpty
              ? const Center(child: Text('No pending agents'))
              : RefreshIndicator(
                  onRefresh: _fetchPendingAgents,
                  child: ListView.builder(
                    itemCount: _pendingAgents.length,
                    itemBuilder: (context, index) {
                      final agent = _pendingAgents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(agent['name'][0].toUpperCase()),
                          ),
                          title: Text(agent['name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Company: ${agent['company'] ?? 'N/A'}'),
                              Text('Purpose: ${agent['purpose'] ?? 'N/A'}'),
                              Text('Flat: ${agent['flatNumber'] ?? 'N/A'}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _verifyAgent(agent['_id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectAgent(agent['_id']),
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
