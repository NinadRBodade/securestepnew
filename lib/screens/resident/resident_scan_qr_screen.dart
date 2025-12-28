import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../../services/offline_qr_service.dart';
import 'agent_verification_result_screen.dart';

// QR Scanner screen for residents
class ResidentScanQRScreen extends StatefulWidget {
  const ResidentScanQRScreen({super.key});

  @override
  State<ResidentScanQRScreen> createState() => _ResidentScanQRScreenState();
}

class _ResidentScanQRScreenState extends State<ResidentScanQRScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  bool _isOnline = true;
  final OfflineQRService _offlineService = OfflineQRService.instance;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final online = await _offlineService.isOnline();
    if (mounted) {
      setState(() => _isOnline = online);
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onQRScanned(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final String? qrData = barcode.rawValue;
      
      if (qrData == null || qrData.isEmpty) continue;
      
      setState(() => _isScanning = false);
      
      // DEBUG LOGGING
      print('=' * 80);
      print('📷 RESIDENT QR SCAN:');
      print('Length: ${qrData.length}');
      print('Data: ${qrData.substring(0, qrData.length > 200 ? 200 : qrData.length)}');
      print('=' * 80);
      
      // Process the QR code
      await _processQRCode(qrData);
      break;
    }
  }

  Future<void> _processQRCode(String qrData) async {
    try {
      // Validate: Check for HTML
      if (qrData.trim().startsWith('<!DOCTYPE') || qrData.trim().startsWith('<html')) {
        _showErrorDialog(
          'Invalid QR Code', 
          'This appears to be HTML, not a QR code.\n\nMake sure you are scanning the QR CODE IMAGE itself.'
        );
        setState(() => _isScanning = true);
        return;
      }
      
      // Validate: Check for URL
      if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
        _showErrorDialog(
          'Invalid QR Code', 
          'This is a URL, not agent data.\n\nThe QR code must contain JSON data.'
        );
        setState(() => _isScanning = true);
        return;
      }
      
      // Parse JSON
      Map<String, dynamic> agentData;
      try {
        agentData = json.decode(qrData);
      } catch (e) {
        print('❌ JSON parse error: $e');
        _showErrorDialog(
          'Invalid Format', 
          'Could not read QR code data.\n\nPlease try scanning again.'
        );
        setState(() => _isScanning = true);
        return;
      }
      
      // Validate required fields
      if (!agentData.containsKey('id') || !agentData.containsKey('name') || !agentData.containsKey('email')) {
        _showErrorDialog(
          'Invalid QR Code', 
          'This QR code is missing required information.\n\nPlease scan a valid agent QR code.'
        );
        setState(() => _isScanning = true);
        return;
      }
      
      print('✅ Parsed: ${agentData['name']} (${agentData['email']})');
      
      // Check connectivity
      final online = await _offlineService.isOnline();
      setState(() => _isOnline = online);
      
      if (online) {
        _fetchAgentDetailsOnline(agentData);
      } else {
        _verifyAgentOffline(agentData);
      }
      
    } catch (e) {
      print('❌ Error processing QR: $e');
      _showErrorDialog('Error', 'Failed to process QR code: $e');
      setState(() => _isScanning = true);
    }
  }

  Future<void> _verifyAgentOffline(Map<String, dynamic> qrData) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Verify QR offline
      final verification = _offlineService.verifyQROffline(qrData);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (verification['valid']) {
        // Navigate to result screen with offline indicator
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AgentVerificationResultScreen(
              agentData: qrData,
              isOffline: true,
            ),
          ),
        );
      } else {
        _showErrorDialog('Verification Failed', verification['reason']);
        setState(() {
          _isScanning = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Verification Error', 'Failed to verify QR code: $e');
      setState(() {
        _isScanning = true;
      });
    }
  }

  Future<void> _fetchAgentDetailsOnline(Map<String, dynamic> qrData) async {
    // Extract agent ID from QR data
    final agentId = qrData['id'];
    
    if (agentId == null) {
      _showErrorDialog('Invalid QR Code', 'Agent ID is missing from QR code.');
      setState(() {
        _isScanning = true;
      });
      return;
    }
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('🔍 Verifying agent QR with ID: $agentId');
      print('🌐 API URL: ${AppConstants.baseUrl}/api/verify-agent');
      print('📋 Scanned QR String: ${json.encode(qrData)}');
      
      // Send QR data to backend for verification
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/verify-agent'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(qrData), // Send entire QR data to backend
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('📡 Status: ${response.statusCode}');
      print('📝 Full Response Body: ${response.body}');
      print('📋 Content-Type: ${response.headers['content-type']}');
      print('🔍 Response length: ${response.body.length} chars');

      if (!mounted) return;
      Navigator.pop(context);

      // Check if response is HTML (BUG in backend)
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        print('❌ BACKEND BUG: Server returned HTML instead of JSON');
        print('❌ Full HTML Response: ${response.body}');
        _showErrorDialog(
          'Server Configuration Error',
          'Backend returned HTML instead of JSON.\n\nThis is a backend bug that must be fixed.\n\nAPI: POST /api/verify-agent\nExpected: JSON\nReceived: HTML\n\nCheck backend logs!',
        );
        setState(() {
          _isScanning = true;
        });
        return;
      }

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        
        // Validate JSON response
        if (!contentType.contains('application/json')) {
          print('❌ Invalid Content-Type: $contentType');
          throw Exception('Server returned non-JSON content-type: $contentType');
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true && data.containsKey('agent')) {
          final agentData = data['agent'] as Map<String, dynamic>;
          print('✅ Agent verified: ${agentData['name']}');

          // Navigate to result screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AgentVerificationResultScreen(
                agentData: agentData,
                isOffline: false,
              ),
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Agent not found');
        }
      } else if (response.statusCode == 404) {
        _showErrorDialog(
          'Agent Not Found', 
          'No agent registered with this email.\n\nThe agent may need to register first.',
        );
        setState(() {
          _isScanning = true;
        });
      } else {
        print('❌ HTTP Error ${response.statusCode}');
        
        String errorMessage = 'Failed to fetch agent details';
        try {
          final error = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = error['message'] ?? error['error'] ?? errorMessage;
        } catch (e) {
          // Ignore parse error
        }
        
        _showErrorDialog('Error', errorMessage);
        setState(() {
          _isScanning = true;
        });
      }
    } catch (e) {
      print('❌ Exception: $e');
      
      if (!mounted) return;
      Navigator.pop(context);
      
      String errorMessage = 'Network error';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout - please check your internet';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server - is backend running?';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      _showErrorDialog('Connection Error', errorMessage);
      setState(() {
        _isScanning = true;
      });
    }
  }

  Future<void> _fetchAgentDetails(String agentId) async {
    setState(() => _isScanning = false);
    await _fetchAgentDetailsOnline({'email': agentId});
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Agent QR'),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onQRScanned,
          ),
          if (!_isOnline)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OFFLINE MODE - Using cached data',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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