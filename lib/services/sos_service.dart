import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sos_event_model.dart';
import '../config/api_config.dart';
import 'bluetooth_mesh_service.dart';

class SOSService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final BluetoothMeshService _meshService = BluetoothMeshService();
  bool _meshInitialized = false;

  SOSService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Always read token from SharedPreferences (persistent storage)
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token') ?? '';
          
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
    // Initialize mesh in background, don't block
    _initializeMeshNetwork();
  }

  /// Initialize Bluetooth mesh network for offline SOS
  Future<void> _initializeMeshNetwork() async {
    try {
      if (!_meshInitialized) {
        _meshInitialized = await _meshService.initialize();
        if (_meshInitialized) {
          print('✅ Bluetooth mesh initialized for offline SOS');
        } else {
          print('⚠️ Bluetooth mesh not available, SOS will work online only');
        }
      }
    } catch (e) {
      print('⚠️ Bluetooth mesh init failed: $e - SOS will work online only');
      _meshInitialized = false;
    }
  }

  /// Check location permission
  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied && 
           permission != LocationPermission.deniedForever;
  }

  /// Trigger SOS Alert with location tracking
  Future<SOSEvent> triggerSOS({
    required String societyId,
    required String flatNumber,
    String? description,
    String? agentId,
    String? userId,
    String? userName,
    dynamic user,
  }) async {
    try {
      // Get current location
      Position? position = await _getCurrentLocation();
      String? address;
      
      if (position != null) {
        address = await _getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      }

      final sosData = {
        'societyId': societyId,
        'flatNumber': flatNumber,
        'description': description ?? 'Emergency - Immediate assistance required',
        'agentId': agentId,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'locationAddress': address,
        'isOffline': false,
      };

      // Try to send to backend
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      if (token.isEmpty) {
        print('❌ CRITICAL: No auth token found! Please log in again.');
        throw Exception('Not logged in. Please log out and log back in to send SOS.');
      }
      
      print('🔄 Sending SOS to: ${ApiConfig.baseUrl}/sos');
      print('🔑 Token: ${token.substring(0, 20)}...');
      
      final response = await _dio.post('/sos', data: sosData);
      final sosEvent = SOSEvent.fromJson(response.data['data']['sosEvent']);
      print('✅ SOS sent to server successfully');
      return sosEvent;
    } catch (e) {
      print('❌ SOS trigger failed: $e');
      rethrow;
    }
  }

  /// Get current GPS location
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        print('⚠️ Location permission denied');
        return null;
      }

      // Get position with 5-second timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      print('✅ Location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Location error: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to address
  Future<String?> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
    }
    return null;
  }

  /// Save SOS to offline queue
  Future<SOSEvent> _saveOfflineSOS(
    Map<String, dynamic> sosData,
    String? userId,
    String? userName,
  ) async {
    try {
      final sosEvent = SOSEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId ?? 'offline_user',
        userName: userName ?? 'Offline User',
        userRole: 'resident',
        flatNumber: sosData['flatNumber']?.toString(),
        timestamp: DateTime.now(),
        latitude: sosData['latitude']?.toString(),
        longitude: sosData['longitude']?.toString(),
        locationAddress: sosData['locationAddress']?.toString(),
        description: sosData['description']?.toString() ?? 'Emergency - Immediate assistance required',
        agentId: sosData['agentId']?.toString(),
      );

      // Save to local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList('offline_sos_queue') ?? [];
      queue.add(jsonEncode(sosEvent.toJson()));
      await prefs.setStringList('offline_sos_queue', queue);
      
      print('💾 SOS saved to offline queue');
      return sosEvent;
    } catch (e) {
      print('❌ Save offline SOS failed: $e');
      rethrow;
    }
  }

  /// Sync offline SOS alerts when connection restored
  Future<void> syncOfflineAlerts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList('offline_sos_queue') ?? [];
      
      if (queue.isEmpty) {
        print('✅ No offline SOS to sync');
        return;
      }

      print('🔄 Syncing ${queue.length} offline SOS alerts...');
      
      List<String> remaining = [];
      for (String sosJson in queue) {
        try {
          Map<String, dynamic> sosData = jsonDecode(sosJson);
          await _dio.post('/sos/offline-sync', data: sosData);
          print('✅ Synced SOS: ${sosData['sosId']}');
        } catch (e) {
          print('❌ Sync failed for one SOS, keeping in queue');
          remaining.add(sosJson);
        }
      }

      // Update queue with remaining items
      await prefs.setStringList('offline_sos_queue', remaining);
      
      // Sync Bluetooth mesh pending alerts
      if (_meshInitialized) {
        await _meshService.syncPendingAlerts();
      }
      
      print('✅ Offline sync complete. ${remaining.length} remaining');
    } catch (e) {
      print('❌ Sync failed: $e');
    }
  }

  Future<List<SOSEvent>> getAlertsByStatus(String status) async {
    final response = await _dio.get(
      '/sos',
      queryParameters: {'status': status},
    );

    final sosEvents = response.data['data']['sosEvents'];
    if (sosEvents == null) return [];
    
    return (sosEvents as List)
        .map((e) => SOSEvent.fromJson(e))
        .toList();
  }

  Future<List<SOSEvent>> getAllAlerts() async {
    final response = await _dio.get('/sos');

    final sosEvents = response.data['data']['sosEvents'];
    if (sosEvents == null) return [];
    
    return (sosEvents as List)
        .map((e) => SOSEvent.fromJson(e))
        .toList();
  }

  Future<void> acknowledgeAlert(String sosId) async {
    await _dio.put('/sos/$sosId/acknowledge');
  }

  Future<void> resolveAlert(String sosId, String notes) async {
    await _dio.put(
      '/sos/$sosId/resolve',
      data: {
        'outcome': 'safe',
        'notes': notes,
      },
    );
  }

  Future<void> markAsFalseAlarm(String sosId, String notes) async {
    await _dio.put(
      '/sos/$sosId/resolve',
      data: {
        'outcome': 'false-alarm',
        'notes': notes,
      },
    );
  }

  /// Get SOS history for current user
  Future<List<SOSEvent>> getSOSHistory() async {
    try {
      final response = await _dio.get('/sos/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          final List events = data['data']['events'] ?? [];
          return events.map((json) => SOSEvent.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching SOS history: $e');
      return [];
    }
  }

  Stream<List<SOSEvent>> get alertStream async* {
    while (true) {
      await Future.delayed(Duration(seconds: 5));
      yield await getAllAlerts();
    }
  }
}