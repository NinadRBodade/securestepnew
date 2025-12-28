import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class GuardEntryLogsScreen extends StatefulWidget {
  const GuardEntryLogsScreen({super.key});

  @override
  State<GuardEntryLogsScreen> createState() => _GuardEntryLogsScreenState();
}

class _GuardEntryLogsScreenState extends State<GuardEntryLogsScreen> {
  List<dynamic> _logs = [];
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
        await _fetchLogs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading: $e')),
        );
      }
    }
  }

  Future<void> _fetchLogs() async {
    if (!mounted) return;
    
    setState(() => _loading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/guards/entry-logs'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _logs = data['data'] ?? [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading logs')),
        );
      }
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry/Exit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLogs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('No logs available'))
              : RefreshIndicator(
                  onRefresh: _fetchLogs,
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isCheckIn = log['action'] == 'CHECK_IN';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCheckIn ? Colors.green : Colors.orange,
                            child: Icon(
                              isCheckIn ? Icons.login : Icons.logout,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(log['name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Company: ${log['company'] ?? 'N/A'}'),
                              Text('Time: ${_formatDateTime(log['timestamp'])}'),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(log['action'] ?? 'N/A'),
                            backgroundColor: isCheckIn ? Colors.green.shade100 : Colors.orange.shade100,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

