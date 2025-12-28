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
      final String? code = barcode.rawValue;
      
      if (code != null) {
        setState(() {
          _isScanning = false;
        });
        
        // Parse QR data
        try {
          final qrData = jsonDecode(code);
          
          // Check if online or offline
          final online = await _offlineService.isOnline();
          setState(() => _isOnline = online);
          
          if (online) {
            // ONLINE: Use old flow (fetch from backend)
            _fetchAgentDetailsOnline(qrData);
          } else {
            // OFFLINE: Verify locally
            _verifyAgentOffline(qrData);
          }
          
        } catch (e) {
          // Invalid QR code
          _showErrorDialog('Invalid QR Code', 'This is not a valid agent QR code.');
          setState(() {
            _isScanning = true;
          });
        }
        break;
      }
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
    // Validate QR code structure
    final agentId = qrData['id'] ?? qrData['agentId'];
    
    if (agentId == null) {
      _showErrorDialog('Invalid QR Code', 'This is not a valid agent QR code.');
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
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/agent/$agentId'),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final agentData = data['agent'];

        // Navigate to result screen with full agent details
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
        final error = json.decode(response.body);
        _showErrorDialog('Agent Not Found', error['error'] ?? 'Could not verify agent');
        setState(() {
          _isScanning = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Connection Error', 'Could not connect to server. Please check your internet connection.');
      setState(() {
        _isScanning = true;
      });
    }
  }

  Future<void> _fetchAgentDetails(String agentId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/agent/$agentId'),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final agentData = data['agent'];

        // Navigate to result screen with full agent details
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AgentVerificationResultScreen(
              agentData: agentData,
            ),
          ),
        );
      } else {
        final error = json.decode(response.body);
        _showErrorDialog('Agent Not Found', error['error'] ?? 'Could not verify agent');
        setState(() {
          _isScanning = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Connection Error', 'Could not connect to server. Please check your internet connection.');
      setState(() {
        _isScanning = true;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
        actions: [
          // Network status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isOnline ? Colors.green : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isOnline ? Icons.cloud_done : Icons.cloud_off,
                      size: 16,
                      color: _isOnline ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isOnline ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Torch toggle
          IconButton(
            icon: Icon(
              cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _onQRScanned,
          ),
          
          // Overlay with instructions
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        
        // Scanner frame
        Container(
          height: 300,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              Container(
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppConstants.primaryColor,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    _buildCorner(Alignment.topLeft),
                    _buildCorner(Alignment.topRight),
                    _buildCorner(Alignment.bottomLeft),
                    _buildCorner(Alignment.bottomRight),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Position QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan the agent\'s QR code to verify their identity',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}