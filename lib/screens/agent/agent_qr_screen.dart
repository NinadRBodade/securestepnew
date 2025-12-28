import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Agent QR Code screen - Shows agent's unique QR code
class AgentQRScreen extends StatefulWidget {
  final String agentEmail;
  
  const AgentQRScreen({super.key, required this.agentEmail});

  @override
  State<AgentQRScreen> createState() => _AgentQRScreenState();
}

class _AgentQRScreenState extends State<AgentQRScreen> {
  Map<String, dynamic>? _agentData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }

  Future<void> _loadAgentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/agent/${widget.agentEmail}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final agent = data['agent'];
        
        if (agent['verified'] != true) {
          setState(() {
            _errorMessage = 'QR code will be available after verification.';
            _isLoading = false;
          });
          return;
        }
        
        setState(() {
          _agentData = agent;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Please upload documents first.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load agent data.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildQRView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your documents are under review. You will be notified once verified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRView() {
    // Create timestamp and expiry (24 hours)
    final issuedAt = DateTime.now();
    final expiresAt = issuedAt.add(Duration(hours: 24));
    
    // Create agent data
    final agentInfo = {
      'id': _agentData!['id'],
      'name': _agentData!['name'],
      'email': _agentData!['email'],
      'company': _agentData!['company'],
      'verified': _agentData!['verified'],
      'score': _agentData!['score'],
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
    
    // Generate signature (simple hash for offline verification)
    final signedData = '${agentInfo['id']}-${agentInfo['email']}-${agentInfo['issuedAt']}';
    final signedHash = sha256.convert(utf8.encode(signedData)).toString();
    agentInfo['signedHash'] = signedHash;
    agentInfo['signature'] = signedHash.substring(0, 16); // First 16 chars as signature
    
    // Create QR data
    final qrData = jsonEncode(agentInfo);
    
    // DEBUG: Print QR data
    print('=' * 80);
    print('🔷 AGENT QR CODE DATA:');
    print('Raw JSON: $qrData');
    print('Length: ${qrData.length} characters');
    print('Agent Info: $agentInfo');
    print('=' * 80);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          // Verification status badge
          _buildStatusBadge(),
          const SizedBox(height: 24),
          
          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Agent info card
          _buildInfoCard(),
          const SizedBox(height: 16),
          
          // QR Expiry info
          _buildExpiryInfo(DateTime.parse(jsonDecode(qrData)['expiresAt'])),
          const SizedBox(height: 16),
          
          // Instructions
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isVerified = _agentData!['verified'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.pending,
            color: isVerified ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isVerified ? 'Verified Agent' : 'Verification Pending',
            style: TextStyle(
              color: isVerified ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.person, 'Name', _agentData!['name']),
            const Divider(),
            _buildInfoRow(Icons.business, 'Company', _agentData!['company'] ?? 'Not Specified'),
            const Divider(),
            _buildInfoRow(Icons.badge, 'Agent ID', _agentData!['id']),
            const Divider(),
            _buildInfoRow(
              Icons.star,
              'Safety Score',
              '${_agentData!['score']}/5.0',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'How to use',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionItem('1. Show this QR code to the resident'),
            _buildInstructionItem('2. Resident will scan to verify your identity'),
            _buildInstructionItem('3. Wait for verification confirmation'),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryInfo(DateTime expiresAt) {
    final now = DateTime.now();
    final timeLeft = expiresAt.difference(now);
    final hoursLeft = timeLeft.inHours;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hoursLeft < 6 ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hoursLeft < 6 ? Colors.orange : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: hoursLeft < 6 ? Colors.orange : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR Code Valid For',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$hoursLeft hours remaining',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hoursLeft < 6 ? Colors.orange.shade900 : Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),
          if (hoursLeft < 1)
            TextButton(
              onPressed: () {
                setState(() {
                  _loadAgentData(); // Refresh QR
                });
              },
              child: Text('Refresh'),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue.shade900,
          fontSize: 14,
        ),
      ),
    );
  }
}