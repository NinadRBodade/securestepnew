import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/constants.dart';

class AgentProfileScreen extends StatefulWidget {
  final String agentEmail;
  
  const AgentProfileScreen({super.key, required this.agentEmail});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  Map<String, dynamic>? _agentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgentProfile();
  }

  Future<void> _loadAgentProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/agent/${widget.agentEmail}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() => _agentData = data['agent']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _agentData = null);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_agentData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                const Text('Documents Not Uploaded', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Please upload your documents to complete registration.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final verified = _agentData!['verified'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: RefreshIndicator(
        onRefresh: _loadAgentProfile,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: verified ? Colors.green.shade100 : Colors.orange.shade100,
                child: Icon(verified ? Icons.verified_user : Icons.pending, size: 60, color: verified ? Colors.green : Colors.orange),
              ),
              const SizedBox(height: 20),
              Text(_agentData!['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: verified ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(20)),
                child: Text(verified ? 'VERIFIED' : 'PENDING', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profile Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _buildInfoTile(Icons.person, 'Name', _agentData!['name']),
                      _buildInfoTile(Icons.email, 'Email', _agentData!['email']),
                      _buildInfoTile(Icons.business, 'Company', _agentData!['company'] ?? 'Not Specified'),
                      _buildInfoTile(Icons.badge, 'Agent ID', _agentData!['id']),
                      _buildInfoTile(Icons.verified, 'Status', verified ? 'Verified' : 'Pending', color: verified ? Colors.green : Colors.orange),
                      _buildInfoTile(Icons.star, 'Score', '${_agentData!['score'] ?? 0}/5.0', color: Colors.amber),
                    ],
                  ),
                ),
              ),
              if (!verified) const SizedBox(height: 20),
              if (!verified)
                Card(
                  color: Colors.orange.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(child: Text('Documents under review. QR code will be available after verification.', style: TextStyle(color: Colors.orange))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
