import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class GuardActiveAgentsScreen extends StatefulWidget {
  const GuardActiveAgentsScreen({super.key});

  @override
  State<GuardActiveAgentsScreen> createState() => _GuardActiveAgentsScreenState();
}

class _GuardActiveAgentsScreenState extends State<GuardActiveAgentsScreen> {
  List<dynamic> _agents = [];
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
        await _fetchActiveAgents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading: $e')),
        );
      }
    }
  }

  Future<void> _fetchActiveAgents() async {
    if (!mounted) return;
    
    setState(() => _loading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/guards/active-agents'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _agents = data['data'] ?? [];
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

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final duration = DateTime.now().difference(date);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '$hours h $minutes min ago';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Agents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActiveAgents,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _agents.isEmpty
              ? const Center(child: Text('No agents currently inside'))
              : RefreshIndicator(
                  onRefresh: _fetchActiveAgents,
                  child: ListView.builder(
                    itemCount: _agents.length,
                    itemBuilder: (context, index) {
                      final agent = _agents[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(agent['name'][0].toUpperCase()),
                          ),
                          title: Text(agent['name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Company: ${agent['company'] ?? 'N/A'}'),
                              Text('Check-in: ${_formatDateTime(agent['lastCheckIn'])}'),
                              if (agent['verified'] == true)
                                const Row(
                                  children: [
                                    Icon(Icons.verified, color: Colors.green, size: 16),
                                    SizedBox(width: 4),
                                    Text('Verified', style: TextStyle(color: Colors.green)),
                                  ],
                                ),
                            ],
                          ),
                          trailing: const Chip(
                            label: Text('INSIDE'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
