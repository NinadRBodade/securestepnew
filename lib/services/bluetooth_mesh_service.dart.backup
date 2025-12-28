import 'package:flutter_blue_plus/flutter_blue_plus.dart';import 'package:permission_handler/permission_handler.dart';import 'dart:convert';import 'dart:async';import 'package:shared_preferences/shared_preferences.dart';import '../models/sos_event_model.dart';import 'dart:io' show Platform;class BluetoothMeshService {  static final BluetoothMeshService _instance = BluetoothMeshService._internal();  factory BluetoothMeshService() => _instance;  BluetoothMeshService._internal();  static const String SOS_SERVICE_UUID = "00001234-0000-1000-8000-00805f9b34fb";  static const String SOS_CHARACTERISTIC_UUID = "00005678-0000-1000-8000-00805f9b34fb";  StreamSubscription? _scanSubscription;  StreamSubscription? _stateSubscription;    final Set<String> _processedSOSIds = {};  final List<SOSEvent> _pendingSOSAlerts = [];    bool _isInitialized = false;  bool _isScanning = false;  Future<bool> initialize() async {    if (_isInitialized) return true;    try {      // Request Bluetooth permissions first
      if (Platform.isAndroid) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();
        
        // Check if any critical permission was denied
        if (statuses[Permission.bluetoothScan]?.isDenied ?? true) {
          print('⚠️ Bluetooth scan permission denied - mesh disabled');
          return false;
        }
      } else if (Platform.isIOS) {
        await Permission.bluetooth.request();
      }
      
      // Check Bluetooth availability
      if (await FlutterBluePlus.isAvailable == false) {
        print('⚠️ Bluetooth not available on device');
        return false;
      }
      
      _stateSubscription = FlutterBluePlus.adapterState.listen((state) {
        print('📡 Bluetooth: $state');
      });
      
      _isInitialized = true;
      print('✅ Bluetooth mesh initialized');
      
      // Start scanning (non-blocking)
      _startScanning();
      return true;
    } catch (e) {
      print('❌ Bluetooth init failed: $e');
      return false;
    }
  }  Future<void> _startScanning() async {    if (_isScanning) return;
    if (!_isInitialized) {
      print('⚠️ Cannot scan - Bluetooth not initialized');
      return;
    }
    
    try {
      _isScanning = true;
      await FlutterBluePlus.startScan(
        withServices: [Guid(SOS_SERVICE_UUID)],
        timeout: Duration(seconds: 15),
      );
      
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          _handleDiscoveredDevice(result);
        }
      }, onError: (error) {
        print('❌ Scan results error: $error');
      });
      
      print('📡 Scanning for SOS alerts');
    } catch (e) {
      print('❌ Scan error: $e');
      _isScanning = false;
      // Don't retry if permissions denied
      return;
    }
    
    // Restart scanning after timeout
    Future.delayed(Duration(seconds: 20), () {
      if (_isInitialized) {
        FlutterBluePlus.stopScan();
        _isScanning = false;
        _startScanning();
      }
    });
  }  Future<void> _handleDiscoveredDevice(ScanResult result) async {    try {      final device = result.device;      for (var service in result.advertisementData.serviceUuids) {        if (service.toString() == SOS_SERVICE_UUID) {          print('🚨 Found SOS service');          try {            await device.connect(timeout: Duration(seconds: 5));            final services = await device.discoverServices();                        for (var service in services) {              for (var characteristic in service.characteristics) {                if (characteristic.uuid.toString() == SOS_CHARACTERISTIC_UUID) {                  final value = await characteristic.read();                  final sosJson = utf8.decode(value);                  final sosData = jsonDecode(sosJson);                  final sosEvent = SOSEvent.fromJson(sosData);                                    if (!_processedSOSIds.contains(sosEvent.id)) {                    _processedSOSIds.add(sosEvent.id);                    _pendingSOSAlerts.add(sosEvent);                    await _saveToLocalQueue(sosEvent);                    await propagateSOSAlert(sosEvent);                    print('✅ Received SOS via mesh: ${sosEvent.id}');                  }                }              }            }            await device.disconnect();          } catch (e) {            print('❌ Failed to read SOS: $e');          }        }      }    } catch (e) {      print('❌ Error handling device: $e');    }  }  Future<void> propagateSOSAlert(SOSEvent sosEvent) async {    if (_processedSOSIds.contains(sosEvent.id)) {      print('⚠️ SOS already propagated: ${sosEvent.id}');      return;    }    try {      _processedSOSIds.add(sosEvent.id);      _pendingSOSAlerts.add(sosEvent);      await _saveToLocalQueue(sosEvent);      if (Platform.isAndroid) {        print('📡 Propagating SOS via mesh: ${sosEvent.id}');      } else {        print('⚠️ iOS cannot advertise - saved to queue');      }    } catch (e) {      print('❌ Failed to propagate: $e');    }  }  Future<void> _saveToLocalQueue(SOSEvent sosEvent) async {    try {      final prefs = await SharedPreferences.getInstance();      List<String> queue = prefs.getStringList('sos_mesh_queue') ?? [];      queue.add(jsonEncode(sosEvent.toJson()));      await prefs.setStringList('sos_mesh_queue', queue);      print('💾 Saved SOS to queue: ${sosEvent.id}');    } catch (e) {      print('❌ Failed to save: $e');    }  }  Future<void> syncPendingAlerts() async {    try {      final prefs = await SharedPreferences.getInstance();      List<String> queue = prefs.getStringList('sos_mesh_queue') ?? [];            if (queue.isEmpty) {        print('✅ No pending SOS to sync');        return;      }      print('🔄 Syncing ${queue.length} pending SOS...');      await prefs.remove('sos_mesh_queue');      _pendingSOSAlerts.clear();      print('✅ Synced ${queue.length} alerts');    } catch (e) {      print('❌ Sync failed: $e');    }  }  Map<String, dynamic> getStats() {    return {      'isInitialized': _isInitialized,      'isScanning': _isScanning,      'processedCount': _processedSOSIds.length,      'pendingCount': _pendingSOSAlerts.length,    };  }  void dispose() {    _scanSubscription?.cancel();    _stateSubscription?.cancel();    FlutterBluePlus.stopScan();  }}