import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/constants.dart';

class AgentSettingsScreen extends StatefulWidget {
  final String agentEmail;
  
  const AgentSettingsScreen({super.key, required this.agentEmail});

  @override
  State<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends State<AgentSettingsScreen> {
  bool _isLoading = true;
  bool _entryExitNotifications = true;
  bool _verificationNotifications = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/agent/${widget.agentEmail}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final agent = data['agent'];
        
        if (mounted && agent['notificationSettings'] != null) {
          setState(() {
            _entryExitNotifications = agent['notificationSettings']['entryExit'] ?? true;
            _verificationNotifications = agent['notificationSettings']['verification'] ?? true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/agent/${widget.agentEmail}/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'notificationSettings': {
            'entryExit': _entryExitNotifications,
            'verification': _verificationNotifications,
          }
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Failed to save settings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Notification Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your notification preferences',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Entry / Exit Updates'),
                        subtitle: const Text('Get notified when you check in or check out'),
                        value: _entryExitNotifications,
                        onChanged: (value) {
                          setState(() => _entryExitNotifications = value);
                        },
                        secondary: const Icon(Icons.door_front_door, color: Colors.blue),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Verification Status Updates'),
                        subtitle: const Text('Get notified about document verification status'),
                        value: _verificationNotifications,
                        onChanged: (value) {
                          setState(() => _verificationNotifications = value);
                        },
                        secondary: const Icon(Icons.verified_user, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
