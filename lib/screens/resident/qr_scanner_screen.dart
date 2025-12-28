import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/constants.dart';

class ResidentQRScannerScreen extends StatefulWidget {
  const ResidentQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<ResidentQRScannerScreen> createState() => _ResidentQRScannerScreenState();
}

class _ResidentQRScannerScreenState extends State<ResidentQRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  Future<void> _handleQRScanned(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/agent/scan/${Uri.encodeComponent(qrData)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        
        // Stop scanner
        cameraController.stop();
        
        // Show agent details
        await _showAgentDetails(data['agent']);
        
        // Resume scanner after dialog closes
        cameraController.start();
      } else {
        if (!mounted) return;
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Invalid QR code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showAgentDetails(Map<String, dynamic> agent) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.green, size: 30),
            const SizedBox(width: 10),
            const Text('Verified Agent'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Agent Name
              Center(
                child: Text(
                  agent['name'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 20),

              // Rating
              Center(
                child: Column(
                  children: [
                    const Text('Rating', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final score = agent['score'].toDouble();
                        if (index < score.floor()) {
                          return const Icon(Icons.star, color: Colors.amber, size: 28);
                        } else if (index < score) {
                          return const Icon(Icons.star_half, color: Colors.amber, size: 28);
                        } else {
                          return const Icon(Icons.star_border, color: Colors.amber, size: 28);
                        }
                      }),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${agent['score'].toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),

              // Contact Information
              const Text(
                'Contact Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Email'),
                subtitle: Text(agent['email']),
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Phone'),
                subtitle: Text(agent['phone']),
              ),

              const Divider(),

              // Verification Info
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Verification Status'),
                subtitle: Text(agent['verificationStatus'].toUpperCase()),
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('Verified On'),
                subtitle: Text(agent['verifiedAt'] ?? 'N/A'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Agent QR Code'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.switch_camera),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQRScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          
          // Overlay with instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, size: 60, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    'Point camera at agent\'s QR code',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'The QR code will be scanned automatically',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text('Verifying agent...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
