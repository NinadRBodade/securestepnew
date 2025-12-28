import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/constants.dart';
import '../../services/offline_qr_service.dart';

class GuardQRScannerScreen extends StatefulWidget {
  const GuardQRScannerScreen({super.key});

  @override
  State<GuardQRScannerScreen> createState() => _GuardQRScannerScreenState();
}

class _GuardQRScannerScreenState extends State<GuardQRScannerScreen> {
  String? _token;
  bool _isProcessing = false;
  bool _isOnline = true;
  int _unsyncedCount = 0;
  MobileScannerController cameraController = MobileScannerController();
  final OfflineQRService _offlineService = OfflineQRService.instance;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _checkConnectivity();
    _loadUnsyncedCount();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> _checkConnectivity() async {
    final online = await _offlineService.isOnline();
    if (mounted) {
      setState(() => _isOnline = online);
      
      // Auto-sync if online and has token
      if (online && _token != null) {
        _offlineService.autoSync(_token!);
        _loadUnsyncedCount(); // Refresh count
      }
    }
  }

  Future<void> _loadUnsyncedCount() async {
    final count = await _offlineService.getUnsyncedCount();
    if (mounted) {
      setState(() => _unsyncedCount = count);
    }
  }

  Future<void> _syncOfflineEntries() async {
    if (_token == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final result = await _offlineService.syncOfflineEntries(_token!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        
        if (result['success']) {
          await _loadUnsyncedCount();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Sync failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing || _token == null) return;
    
    setState(() => _isProcessing = true);

    try {
      // DETAILED DEBUG LOGGING
      print('=' * 80);
      print('📷 RAW SCANNED DATA:');
      print('Length: ${qrData.length} characters');
      print('First 200 chars: ${qrData.length > 200 ? qrData.substring(0, 200) : qrData}');
      print('Last 50 chars: ${qrData.length > 50 ? qrData.substring(qrData.length - 50) : qrData}');
      print('=' * 80);
      
      // Show user what was scanned
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned: ${qrData.substring(0, qrData.length > 100 ? 100 : qrData.length)}...'),
          duration: Duration(seconds: 3),
        ),
      );
      
      // Check if scanned data looks like HTML
      if (qrData.trim().startsWith('<!DOCTYPE') || qrData.trim().startsWith('<html')) {
        throw Exception('❌ Scanned HTML page instead of JSON data.\n\nPlease scan the QR CODE IMAGE, not the webpage.');
      }
      
      // Check if scanned data looks like a URL
      if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
        throw Exception('❌ Scanned a URL instead of agent data.\n\nThe QR code should contain JSON, not a link.');
      }
      
      // Try to parse JSON
      Map<String, dynamic> agentData;
      try {
        agentData = json.decode(qrData);
      } catch (e) {
        throw Exception('❌ Invalid JSON format.\n\nError: ${e.toString()}\n\nScanned data must be valid JSON.');
      }
      
      // Validate required fields
      if (!agentData.containsKey('id') || !agentData.containsKey('name') || !agentData.containsKey('email')) {
        throw Exception('❌ Missing required fields.\n\nQR code must contain: id, name, and email');
      }

      print('✅ Valid agent data: ${agentData['name']} (${agentData['email']})');

      // Use offline service for online/offline handling
      final result = await _offlineService.processQRScan(
        qrData: agentData,
        token: _token!,
      );

      if (mounted) {
        if (result['success']) {
          final action = result['action'];
          final agent = result['agent'];
          final mode = result['mode'];
          final pendingSync = result['pendingSync'] ?? false;
          
          _showResultDialog(
            action: action,
            agentName: agent['name'],
            company: agent['company'] ?? 'N/A',
            verified: agent['verified'] ?? false,
            mode: mode,
            pendingSync: pendingSync,
          );
          
          // Refresh unsynced count
          await _loadUnsyncedCount();
        } else {
          _showError(result['message'] ?? 'Scan failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Invalid QR code: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showResultDialog({
    required String action,
    required String agentName,
    required String company,
    required bool verified,
    required String mode,
    required bool pendingSync,
  }) {
    final isCheckIn = action == 'CHECK_IN';
    final isOffline = mode == 'offline';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCheckIn ? Icons.login : Icons.logout,
              color: isCheckIn ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(isCheckIn ? 'CHECK-IN' : 'CHECK-OUT')),
            if (isOffline)
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
                    Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade900),
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
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $agentName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Company: $company'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  verified ? Icons.verified : Icons.warning,
                  color: verified ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(verified ? 'Verified' : 'Not Verified'),
              ],
            ),
            if (pendingSync) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sync, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Will sync when online',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Scan Another'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
          // Sync button
          if (_unsyncedCount > 0)
            IconButton(
              icon: Badge(
                label: Text('$_unsyncedCount'),
                child: const Icon(Icons.sync),
              ),
              onPressed: _syncOfflineEntries,
              tooltip: 'Sync offline entries',
            ),
          // Torch toggle
          IconButton(
            icon: Icon(cameraController.torchEnabled == TorchState.on 
              ? Icons.flash_on 
              : Icons.flash_off),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _processQRCode(barcodes.first.rawValue!);
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Scan Agent QR Code',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
