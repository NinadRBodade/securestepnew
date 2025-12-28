import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class ResidentSettingsScreen extends StatefulWidget {
  const ResidentSettingsScreen({super.key});

  @override
  State<ResidentSettingsScreen> createState() => _ResidentSettingsScreenState();
}

class _ResidentSettingsScreenState extends State<ResidentSettingsScreen> {
  bool _pushEnabled = true;
  bool _smsEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      
      final response = await dio.get('/residents/settings');
      
      if (response.statusCode == 200 && response.data != null) {
        final status = response.data['status'];
        if (status == 'success' && response.data['data'] != null) {
          final data = response.data['data'];
          if (mounted) {
            setState(() {
              _pushEnabled = data['pushEnabled'] == true;
              _smsEnabled = data['smsEnabled'] == true;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.options.headers['Authorization'] = 'Bearer ${ApiConfig.token}';
      
      final response = await dio.put('/residents/settings', data: {
        'pushEnabled': _pushEnabled,
        'smsEnabled': _smsEnabled,
      });
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings updated successfully'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alert Preferences',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose how you want to receive emergency notifications',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        
                        // Push notifications toggle
                        SwitchListTile(
                          value: _pushEnabled,
                          onChanged: (value) {
                            setState(() => _pushEnabled = value);
                            _updateSettings();
                          },
                          title: const Text('Push Notifications'),
                          subtitle: const Text('Receive alerts via push notifications'),
                          secondary: const Icon(Icons.notifications_active, color: Colors.blue),
                        ),
                        const Divider(),
                        
                        // SMS notifications toggle
                        SwitchListTile(
                          value: _smsEnabled,
                          onChanged: (value) {
                            setState(() => _smsEnabled = value);
                            _updateSettings();
                          },
                          title: const Text('SMS Notifications'),
                          subtitle: const Text('Receive alerts via SMS'),
                          secondary: const Icon(Icons.sms, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'At least one notification method must be enabled for emergency alerts',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
