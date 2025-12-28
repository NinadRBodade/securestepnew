import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'offline_database.dart';

class OfflineQRService {
  static final OfflineQRService instance = OfflineQRService._init();
  final OfflineDatabase _db = OfflineDatabase.instance;

  OfflineQRService._init();

  /// Check if device has internet connectivity
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Double-check with actual network request (timeout 3 seconds)
      try {
        final response = await http.get(
          Uri.parse('${AppConstants.baseUrl}/api/auth/verify'),
        ).timeout(Duration(seconds: 3));
        return response.statusCode < 500;
      } catch (_) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Verify QR code offline (check signature and expiry)
  Map<String, dynamic> verifyQROffline(Map<String, dynamic> qrData) {
    try {
      // 1. Check if QR has required fields
      if (!qrData.containsKey('id') || !qrData.containsKey('name')) {
        return {
          'valid': false,
          'reason': 'Invalid QR structure',
        };
      }

      // 2. Check expiry if present
      if (qrData.containsKey('expiresAt')) {
        final expiresAt = DateTime.tryParse(qrData['expiresAt']);
        if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
          return {
            'valid': false,
            'reason': 'QR code expired',
          };
        }
      }

      // 3. Check issued time (QR shouldn't be from future)
      if (qrData.containsKey('issuedAt')) {
        final issuedAt = DateTime.tryParse(qrData['issuedAt']);
        if (issuedAt != null && issuedAt.isAfter(DateTime.now())) {
          return {
            'valid': false,
            'reason': 'Invalid issue time',
          };
        }
      }

      // 4. Verify signature if present (basic check)
      if (qrData.containsKey('signature') && qrData.containsKey('signedHash')) {
        // In production, verify against public key
        // For now, just check they exist
        if (qrData['signature'].toString().isEmpty) {
          return {
            'valid': false,
            'reason': 'Invalid signature',
          };
        }
      }

      // Offline validation passed
      return {
        'valid': true,
        'reason': 'Offline verification successful',
        'mode': 'offline',
      };
    } catch (e) {
      return {
        'valid': false,
        'reason': 'Verification error: $e',
      };
    }
  }

  /// Process QR scan (online or offline)
  Future<Map<String, dynamic>> processQRScan({
    required Map<String, dynamic> qrData,
    required String token,
  }) async {
    try {
      final online = await isOnline();
      print('🌐 Network status: ${online ? "ONLINE" : "OFFLINE"}');

      if (online) {
        // ONLINE MODE - Call backend API
        return await _processOnline(qrData, token);
      } else {
        // OFFLINE MODE - Local verification
        return await _processOffline(qrData);
      }
    } catch (e) {
      print('❌ QR processing error: $e');
      return {
        'success': false,
        'mode': 'error',
        'message': 'Processing failed: $e',
      };
    }
  }

  /// Online processing (existing flow)
  Future<Map<String, dynamic>> _processOnline(
    Map<String, dynamic> qrData,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/guards/scan-agent'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(qrData),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'mode': 'online',
          'action': result['action'],
          'agent': result['data'],
          'message': result['message'],
        };
      } else {
        return {
          'success': false,
          'mode': 'online',
          'message': 'Backend error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Online processing failed: $e');
      // Fallback to offline if network error
      return await _processOffline(qrData);
    }
  }

  /// Offline processing (new flow)
  Future<Map<String, dynamic>> _processOffline(Map<String, dynamic> qrData) async {
    try {
      print('📴 Processing OFFLINE...');

      // 1. Verify QR locally
      final verification = verifyQROffline(qrData);
      
      if (!verification['valid']) {
        return {
          'success': false,
          'mode': 'offline',
          'message': verification['reason'],
        };
      }

      // 2. Check agent's current status (check if already inside)
      final agentId = qrData['id'].toString();
      final existingEntries = await _db.getAllEntries();
      
      // Find last entry for this agent
      final lastEntry = existingEntries.firstWhere(
        (entry) => entry['agentId'] == agentId,
        orElse: () => {},
      );

      // Determine action: CHECK-IN or CHECK-OUT
      String action = 'CHECK_IN';
      if (lastEntry.isNotEmpty && lastEntry['action'] == 'CHECK_IN') {
        action = 'CHECK_OUT';
      }

      // 3. Save to offline database
      final offlineEntry = {
        'agentId': agentId,
        'name': qrData['name'],
        'email': qrData['email'],
        'company': qrData['company'] ?? '',
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        'verified': qrData['verified'] == true ? 1 : 0,
        'score': qrData['score'] ?? 0,
        'isOffline': 1,
        'synced': 0,
        'qrData': json.encode(qrData),
        'expiresAt': qrData['expiresAt'],
        'signature': qrData['signature'],
      };

      await _db.insertOfflineEntry(offlineEntry);

      print('✅ Offline entry saved: $action for ${qrData['name']}');

      return {
        'success': true,
        'mode': 'offline',
        'action': action,
        'agent': qrData,
        'message': 'Verified offline - Will sync when online',
        'pendingSync': true,
      };
    } catch (e) {
      print('❌ Offline processing error: $e');
      return {
        'success': false,
        'mode': 'offline',
        'message': 'Offline processing failed: $e',
      };
    }
  }

  /// Sync offline entries to backend
  Future<Map<String, dynamic>> syncOfflineEntries(String token) async {
    try {
      final online = await isOnline();
      if (!online) {
        return {
          'success': false,
          'message': 'No internet connection',
          'synced': 0,
        };
      }

      final unsyncedEntries = await _db.getUnsyncedEntries();
      if (unsyncedEntries.isEmpty) {
        return {
          'success': true,
          'message': 'No entries to sync',
          'synced': 0,
        };
      }

      print('🔄 Syncing ${unsyncedEntries.length} offline entries...');

      int successCount = 0;
      int failCount = 0;

      for (var entry in unsyncedEntries) {
        try {
          // Send to backend
          final response = await http.post(
            Uri.parse('${AppConstants.baseUrl}/api/guards/sync-offline-entry'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'agentId': entry['agentId'],
              'name': entry['name'],
              'email': entry['email'],
              'company': entry['company'],
              'action': entry['action'],
              'timestamp': entry['timestamp'],
              'verified': entry['verified'] == 1,
              'score': entry['score'],
              'qrData': entry['qrData'],
              'isOfflineVerified': true,
            }),
          ).timeout(Duration(seconds: 10));

          if (response.statusCode == 200 || response.statusCode == 201) {
            await _db.markAsSynced(entry['id']);
            successCount++;
            print('   ✅ Synced entry ${entry['id']}');
          } else {
            failCount++;
            print('   ❌ Failed to sync entry ${entry['id']}: ${response.statusCode}');
          }
        } catch (e) {
          failCount++;
          print('   ❌ Error syncing entry ${entry['id']}: $e');
        }
      }

      return {
        'success': true,
        'message': 'Synced $successCount entries',
        'synced': successCount,
        'failed': failCount,
        'total': unsyncedEntries.length,
      };
    } catch (e) {
      print('❌ Sync error: $e');
      return {
        'success': false,
        'message': 'Sync failed: $e',
        'synced': 0,
      };
    }
  }

  /// Get unsynced count
  Future<int> getUnsyncedCount() async {
    return await _db.getUnsyncedCount();
  }

  /// Auto-sync on network restore
  Future<void> autoSync(String token) async {
    final online = await isOnline();
    if (online) {
      final count = await getUnsyncedCount();
      if (count > 0) {
        print('🔄 Auto-syncing $count offline entries...');
        await syncOfflineEntries(token);
      }
    }
  }
}
