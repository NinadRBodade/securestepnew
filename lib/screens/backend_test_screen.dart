import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({super.key});

  @override
  State<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  String _connectionStatus = 'Not tested';
  Color _statusColor = Colors.grey;
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing...';
      _statusColor = Colors.orange;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/health'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _connectionStatus = '✅ Connected! ${data['message']}';
          _statusColor = Colors.green;
          _isLoading = false;
        });
      } else {
        setState(() {
          _connectionStatus = '❌ Error: Status ${response.statusCode}';
          _statusColor = Colors.red;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Failed: $e';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Backend Status',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Status Card
            Card(
              color: _statusColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _statusColor == Colors.green
                          ? Icons.check_circle
                          : _statusColor == Colors.red
                              ? Icons.error
                              : Icons.help,
                      size: 48,
                      color: _statusColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        fontSize: 16,
                        color: _statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Testing...' : 'Test Connection'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            
            // Info Section
            const Text(
              'Backend URL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.baseUrl,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Test Credentials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            _buildCredentialCard('Agent', 'agent@demo.com', 'agent123'),
            _buildCredentialCard('Resident', 'resident@demo.com', 'resident123'),
            _buildCredentialCard('Guard', 'guard@demo.com', 'guard123'),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: Currently using mock authentication. Backend integration coming soon!',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialCard(String role, String email, String password) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getRoleIcon(role),
          color: AppConstants.primaryColor,
        ),
        title: Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$email / $password'),
        dense: true,
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'agent':
        return Icons.delivery_dining;
      case 'resident':
        return Icons.home;
      case 'guard':
        return Icons.shield;
      default:
        return Icons.person;
    }
  }
}
