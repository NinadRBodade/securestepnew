import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'resident_face_verification_screen.dart';

class AgentVerificationResultScreen extends StatelessWidget {
  final Map<String, dynamic> agentData;
  final bool isOffline;

  const AgentVerificationResultScreen({
    super.key,
    required this.agentData,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final String name = agentData['name'] ?? 'Unknown';
    final String id = agentData['id'] ?? 'N/A';
    final String email = agentData['email'] ?? 'N/A';
    final String phone = agentData['phone'] ?? 'N/A';
    final double score = (agentData['score'] ?? 0).toDouble();
    final String verificationStatus = agentData['verificationStatus'] ?? 'unknown';
    final String verifiedAt = agentData['verifiedAt'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Agent Details'),
            if (isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 14, color: Colors.orange.shade900),
                    const SizedBox(width: 4),
                    Text(
                      'OFFLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'QR Code Scanned Successfully',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Agent Information',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Agent details card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.person, 'Name', name),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.badge, 'ID', id),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.email, 'Email', email),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.phone, 'Phone', phone),
                    const Divider(height: 24),
                    _buildDetailRow(
                      Icons.verified, 
                      'Status', 
                      verificationStatus == 'verified' ? 'Verified ✓' : 'Not Verified',
                    ),
                    const Divider(height: 24),
                    // Score display with stars
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Trust Score',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < score ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${score.toStringAsFixed(1)}/5.0',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (verifiedAt != 'N/A') ...[
                      const Divider(height: 24),
                      _buildDetailRow(Icons.calendar_today, 'Verified On', _formatDate(verifiedAt)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Offline warning if applicable
            if (isOffline)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verified offline using QR signature. Limited information available.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Action buttons
            ElevatedButton.icon(
              onPressed: () {
                final agentEmail = agentData['email'] ?? agentData['id'] ?? '';
                if (agentEmail.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot verify: Agent email not found'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResidentFaceVerificationScreen(
                      agentEmail: agentEmail,
                      agentData: agentData,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.face),
              label: const Text('Verify Agent Face'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () {
                // TODO: Report suspicious activity
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report functionality coming soon'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Report Suspicious Activity'),
            ),
            const SizedBox(height: 12),
            
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}
