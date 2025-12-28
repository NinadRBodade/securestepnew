import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class SimpleQRScanner extends StatefulWidget {
  const SimpleQRScanner({Key? key}) : super(key: key);

  @override
  State<SimpleQRScanner> createState() => _SimpleQRScannerState();
}

class _SimpleQRScannerState extends State<SimpleQRScanner> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrString) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    print('🔥 NEW SCANNER - QR DETECTED!');
    print('📋 Raw QR Data: $qrString');
    print('📏 Length: ${qrString.length} characters');

    try {
      // Step 1: Parse QR as JSON
      Map<String, dynamic> qrData;
      try {
        qrData = json.decode(qrString);
        print('✅ JSON Parsed Successfully');
        print('📦 QR Data: $qrData');
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        _showError('Invalid QR Code', 'This QR code contains invalid data.');
        return;
      }

      // Step 2: Validate required fields
      if (!qrData.containsKey('id') || !qrData.containsKey('email')) {
        print('❌ Missing required fields');
        _showError('Invalid QR Code', 'QR code is missing agent ID or email.');
        return;
      }

      print('🌐 Calling API...');
      print('🎯 Endpoint: ${AppConstants.baseUrl}/api/verify-agent');
      print('📤 Sending: ${json.encode(qrData)}');

      // Step 3: Call backend API
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/verify-agent'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(qrData),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - check your network');
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📝 Response Headers: ${response.headers}');
      print('📄 Response Body: ${response.body}');

      // Step 4: Check if response is HTML (ERROR!)
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html')) {
        print('❌ ERROR: Backend returned HTML instead of JSON!');
        print('❌ Full HTML Response: ${response.body}');
        _showError(
          'Backend Error',
          'Server returned HTML instead of JSON.\n\n'
          'Backend is misconfigured or route not found.\n\n'
          'Expected: JSON from /api/verify-agent\n'
          'Got: HTML page'
        );
        return;
      }

      // Step 5: Parse JSON response
      Map<String, dynamic> result;
      try {
        result = json.decode(response.body);
        print('✅ Response JSON Parsed');
      } catch (e) {
        print('❌ Failed to parse response as JSON: $e');
        _showError('Server Error', 'Backend sent invalid response format.');
        return;
      }

      // Step 6: Handle response
      if (response.statusCode == 200 && result['success'] == true) {
        final agent = result['agent'];
        print('🎉 SUCCESS! Agent verified: ${agent['name']}');
        
        // Show success dialog
        _showSuccess(agent);
      } else {
        print('❌ Verification failed: ${result['message']}');
        _showError('Verification Failed', result['message'] ?? 'Unknown error');
      }

    } catch (e) {
      print('💥 EXCEPTION CAUGHT: $e');
      _showError('Error', 'Failed to verify agent: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(Map<String, dynamic> agent) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✅ Agent Verified'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${agent['name']}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Email: ${agent['email']}'),
            SizedBox(height: 8),
            Text('Company: ${agent['company'] ?? 'N/A'}'),
            SizedBox(height: 8),
            Text('Score: ${agent['score']}/100'),
            SizedBox(height: 8),
            Text('Status: ${agent['verified'] ? '✅ Verified' : '⏳ Pending'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Agent QR Code'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _handleQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          
          // Overlay with instructions
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '📷 Point camera at Agent QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Verifying Agent...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
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
